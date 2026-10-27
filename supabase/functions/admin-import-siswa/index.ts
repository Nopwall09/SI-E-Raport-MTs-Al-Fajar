import { createClient } from "npm:@supabase/supabase-js@2";

// Domain harus sama dengan Env.authEmailDomain di aplikasi Flutter.
const DOMAIN = Deno.env.get("AUTH_EMAIL_DOMAIN") ?? "eraport.example.com";
const MAKS_BARIS = 100;
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });

// Tanpa 0/O/1/l/I agar mudah dibaca dan diketik ulang.
const ALFABET = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const acak = (n: number) =>
  Array.from(crypto.getRandomValues(new Uint8Array(n)), (b) => ALFABET[b % ALFABET.length]).join("");

type Baris = { nis?: string; nisn?: string; nama?: string; jk?: string; tgl_lahir?: string; kelas?: string };
type Hasil = { nis: string; status: "dibuat" | "sudah_ada" | "gagal"; password?: string; pesan?: string };

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "Method tidak didukung" }, 405);

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // Hanya admin aktif yang boleh mengimpor siswa.
  const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
  const { data: caller } = await admin.auth.getUser(token);
  if (!caller.user) return json({ error: "Sesi tidak valid" }, 401);
  const { data: me } = await admin
    .from("users").select("role,is_active").eq("id", caller.user.id).maybeSingle();
  if (me?.role !== "admin" || !me.is_active) return json({ error: "Hanya admin" }, 403);

  let body: { rows?: Baris[] };
  try { body = await req.json(); } catch { return json({ error: "Body bukan JSON" }, 400); }
  const rows = body.rows ?? [];
  if (!Array.isArray(rows) || rows.length === 0) return json({ error: "Tidak ada baris untuk diimpor" }, 400);
  if (rows.length > MAKS_BARIS) return json({ error: `Maksimal ${MAKS_BARIS} baris per permintaan` }, 400);

  // Kelas dicari di tahun ajaran aktif, sekali untuk seluruh batch.
  const { data: ta } = await admin.from("tahun_ajaran").select("id").eq("is_active", true).maybeSingle();
  if (!ta) return json({ error: "Belum ada tahun ajaran aktif" }, 409);
  const { data: daftarKelas } = await admin.from("kelas").select("id,nama").eq("tahun_ajaran_id", ta.id);
  const kelasId = new Map((daftarKelas ?? []).map((k) => [k.nama.trim().toLowerCase(), k.id as number]));

  const hasil: Hasil[] = [];
  for (const r of rows) hasil.push(await proses(r));
  return json({ hasil });

  async function proses(r: Baris): Promise<Hasil> {
    const nis = (r.nis ?? "").trim();
    const gagal = (pesan: string): Hasil => ({ nis, status: "gagal", pesan });

    const username = nis.toLowerCase();
    if (!/^[a-z0-9._-]{3,30}$/.test(username)) return gagal("NIS 3-30 karakter: huruf, angka, titik, minus, garis bawah");
    const nama = (r.nama ?? "").trim();
    if (!nama) return gagal("Nama wajib diisi");
    if (r.jk !== "L" && r.jk !== "P") return gagal("Jenis kelamin harus L atau P");
    if (!/^\d{4}-\d{2}-\d{2}$/.test(r.tgl_lahir ?? "") || isNaN(Date.parse(r.tgl_lahir!)))
      return gagal("Tanggal lahir harus berformat yyyy-mm-dd");

    // Idempoten: NIS yang sudah ada dilewati, bukan dianggap kesalahan.
    const { data: ada } = await admin.from("siswa").select("id").eq("nis", nis).maybeSingle();
    if (ada) return { nis, status: "sudah_ada" };

    let kid: number | undefined;
    const namaKelas = (r.kelas ?? "").trim();
    if (namaKelas) {
      kid = kelasId.get(namaKelas.toLowerCase());
      if (!kid) return gagal(`Kelas "${namaKelas}" tidak ada di tahun ajaran aktif`);
    }

    const password = acak(8);
    const { data: created, error: authErr } = await admin.auth.admin.createUser({
      email: `${username}@${DOMAIN}`, password, email_confirm: true,
    });
    if (authErr || !created.user)
      return gagal(authErr?.message.includes("already") ? "Username (NIS) sudah dipakai akun lain" : "Gagal membuat akun");
    const uid = created.user.id;

    let siswaId: number | undefined;
    const batal = async (pesan: string) => {
      if (siswaId) await admin.from("siswa").delete().eq("id", siswaId);
      await admin.auth.admin.deleteUser(uid); // cascade ke public.users
      return gagal(pesan);
    };

    const { error: uErr } = await admin.from("users").insert({
      id: uid, username, email: `${username}@${DOMAIN}`, role: "siswa", must_change_password: true,
    });
    if (uErr) return batal("Gagal menyimpan pengguna");

    const { data: s, error: sErr } = await admin.from("siswa").insert({
      user_id: uid, nis, nisn: r.nisn?.trim() || null, nama, jk: r.jk, tgl_lahir: r.tgl_lahir,
    }).select("id").single();
    if (sErr) return batal(sErr.code === "23505" ? "NISN sudah dipakai siswa lain" : "Gagal menyimpan siswa");
    siswaId = s.id;

    if (kid) {
      const { error } = await admin.from("kelas_siswa").insert({
        kelas_id: kid, siswa_id: siswaId, tahun_ajaran_id: ta!.id,
      });
      if (error) return batal("Gagal mendaftarkan siswa ke kelas");
    }
    return { nis, status: "dibuat", password };
  }
});

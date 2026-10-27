import { createClient } from "npm:@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });

const b64url = (b: ArrayBuffer | Uint8Array | string) => {
  const bytes = typeof b === "string" ? new TextEncoder().encode(b) : new Uint8Array(b);
  return btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
};

type Akun = { client_email: string; private_key: string; token_uri: string; project_id: string };

// Tukar kunci layanan menjadi token akses FCM (JWT RS256, tanpa pustaka tambahan).
async function tokenAkses(sa: Akun): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const data = `${b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }))}.${b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: sa.token_uri,
    iat: now,
    exp: now + 3000,
  }))}`;
  const pem = sa.private_key.replace(/-----[A-Z ]+-----/g, "").replace(/\s/g, "");
  const key = await crypto.subtle.importKey(
    "pkcs8",
    Uint8Array.from(atob(pem), (c) => c.charCodeAt(0)),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(data));
  const res = await fetch(sa.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${data}.${b64url(sig)}`,
    }),
  });
  if (!res.ok) throw new Error("Gagal masuk ke FCM");
  return (await res.json()).access_token;
}

type Pesan = { token: string; judul: string; isi: string; data: Record<string, string> };
type Hasil = "terkirim" | "gagal" | "token_mati";

async function kirim(akses: string, proyek: string, p: Pesan): Promise<Hasil> {
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${proyek}/messages:send`, {
    method: "POST",
    headers: { Authorization: `Bearer ${akses}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      message: {
        token: p.token,
        notification: { title: p.judul, body: p.isi },
        data: p.data,
        android: { priority: "HIGH", notification: { channel_id: "rapor_penting" } },
      },
    }),
  });
  if (res.ok) return "terkirim";
  const status = (await res.json().catch(() => ({})))?.error?.status;
  return status === "UNREGISTERED" || status === "NOT_FOUND" ? "token_mati" : "gagal";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "Method tidak didukung" }, 405);

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  const jwt = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
  const { data: caller } = await admin.auth.getUser(jwt);
  if (!caller.user) return json({ error: "Sesi tidak valid" }, 401);

  let b: { kelas_id?: number; semester?: string };
  try { b = await req.json(); } catch { return json({ error: "Body bukan JSON" }, 400); }
  if (!Number.isInteger(b.kelas_id)) return json({ error: "kelas_id wajib diisi" }, 400);
  if (b.semester !== "ganjil" && b.semester !== "genap")
    return json({ error: "semester harus ganjil atau genap" }, 400);

  // Hanya wali kelas dari kelas itu (guru aktif) yang boleh memicu pengiriman.
  const { data: kelas } = await admin
    .from("kelas")
    .select("id, tahun_ajaran(tahun), guru:wali_kelas_id(user_id, users(is_active))")
    .eq("id", b.kelas_id)
    .maybeSingle();
  // deno-lint-ignore no-explicit-any
  const wali = (kelas as any)?.guru;
  if (!wali || wali.user_id !== caller.user.id || !wali.users?.is_active)
    return json({ error: "Hanya wali kelas dari kelas ini" }, 403);

  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) return json({ error: "Notifikasi belum dikonfigurasi di server" }, 500);
  let akun: Akun;
  try { akun = JSON.parse(raw); } catch { return json({ error: "Konfigurasi notifikasi rusak" }, 500); }

  // Hanya siswa yang rapornya benar-benar final pada semester itu.
  const { data: baris, error: errBaris } = await admin
    .from("kelas_siswa")
    .select("siswa(id, nama, user_id, wali_murid(user_id)), rapor!inner(semester, status)")
    .eq("kelas_id", b.kelas_id)
    .eq("rapor.semester", b.semester)
    .eq("rapor.status", "final");
  if (errBaris) return json({ error: "Gagal membaca data rapor" }, 500);
  if (!baris?.length) return json({ error: "Belum ada rapor final di kelas ini" }, 409);

  // Satu penerima (siswa atau wali murid) bisa punya beberapa anak di kelas ini.
  const penerima: { userId: string; siswaId: number; nama: string }[] = [];
  // deno-lint-ignore no-explicit-any
  for (const r of baris as any[]) {
    const s = r.siswa;
    if (s.user_id) penerima.push({ userId: s.user_id, siswaId: s.id, nama: s.nama });
    if (s.wali_murid?.user_id) penerima.push({ userId: s.wali_murid.user_id, siswaId: s.id, nama: s.nama });
  }
  if (!penerima.length) return json({ terkirim: 0, gagal: 0, perangkat: 0 });

  const { data: tokens } = await admin
    .from("device_token")
    .select("user_id, token")
    .in("user_id", [...new Set(penerima.map((p) => p.userId))]);
  if (!tokens?.length) return json({ terkirim: 0, gagal: 0, perangkat: 0 });

  // deno-lint-ignore no-explicit-any
  const tahun = (kelas as any).tahun_ajaran?.tahun ?? "";
  const label = `semester ${b.semester === "ganjil" ? 1 : 2} ${tahun}`.trim();
  const pesan: Pesan[] = penerima.flatMap((p) =>
    tokens.filter((t) => t.user_id === p.userId).map((t) => ({
      token: t.token,
      judul: "Rapor sudah final",
      // Tanpa nilai: layar kunci bisa terbaca orang lain.
      isi: `Rapor ${label} milik ${p.nama} sudah tersedia. Ketuk untuk melihat.`,
      data: { type: "rapor_final", siswa_id: String(p.siswaId), semester: b.semester! },
    }))
  );

  let akses: string;
  try { akses = await tokenAkses(akun); } catch { return json({ error: "Gagal masuk ke FCM" }, 502); }

  let terkirim = 0, gagal = 0;
  const mati: string[] = [];
  for (let i = 0; i < pesan.length; i += 10) {
    const hasil = await Promise.all(
      pesan.slice(i, i + 10).map((p) => kirim(akses, akun.project_id, p).catch((): Hasil => "gagal")),
    );
    hasil.forEach((h, j) => {
      if (h === "terkirim") terkirim++;
      else {
        gagal++;
        if (h === "token_mati") mati.push(pesan[i + j].token);
      }
    });
  }
  if (mati.length) await admin.from("device_token").delete().in("token", mati);

  return json({ terkirim, gagal, perangkat: pesan.length });
});

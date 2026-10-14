import { createClient } from "npm:@supabase/supabase-js@2";

// Domain harus sama dengan Env.authEmailDomain di aplikasi Flutter.
const DOMAIN = Deno.env.get("AUTH_EMAIL_DOMAIN") ?? "eraport.example.com";
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "Method tidak didukung" }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // Hanya admin aktif yang boleh membuat akun.
  const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
  const { data: caller } = await admin.auth.getUser(token);
  if (!caller.user) return json({ error: "Sesi tidak valid" }, 401);
  const { data: me } = await admin
    .from("users").select("role,is_active").eq("id", caller.user.id).maybeSingle();
  if (me?.role !== "admin" || !me.is_active) return json({ error: "Hanya admin" }, 403);

  let b: Record<string, string>;
  try { b = await req.json(); } catch { return json({ error: "Body bukan JSON" }, 400); }

  const username = (b.username ?? "").trim().toLowerCase();
  const { password, role } = b;
  const nama = (b.nama ?? "").trim();
  if (!/^[a-z0-9._-]{3,30}$/.test(username))
    return json({ error: "Username 3-30 karakter: huruf kecil, angka, titik, minus, garis bawah" }, 400);
  if (!password || password.length < 8) return json({ error: "Password minimal 8 karakter" }, 400);
  if (!["admin", "guru", "wali_murid"].includes(role)) return json({ error: "Role tidak didukung" }, 400);
  if (role !== "admin" && !nama) return json({ error: "Nama wajib diisi" }, 400);

  const email = `${username}@${DOMAIN}`;
  const { data: created, error: authErr } = await admin.auth.admin.createUser({
    email, password, email_confirm: true,
  });
  if (authErr || !created.user)
    return json({ error: authErr?.message.includes("already") ? "Username sudah dipakai" : "Gagal membuat akun" }, 409);
  const id = created.user.id;

  const rollback = async (msg: string, status: number) => {
    await admin.auth.admin.deleteUser(id); // cascade ke public.users
    return json({ error: msg }, status);
  };

  const { error: uErr } = await admin.from("users").insert({ id, username, email, role });
  if (uErr) return rollback("Gagal menyimpan pengguna", 500);

  if (role === "guru") {
    const { error } = await admin.from("guru").insert({
      user_id: id, nama, nip: b.nip?.trim() || null, no_hp: b.no_hp?.trim() || null,
    });
    if (error) return rollback(error.code === "23505" ? "NIP sudah dipakai" : "Gagal menyimpan guru", 409);
  } else if (role === "wali_murid") {
    const { error } = await admin.from("wali_murid").insert({
      user_id: id, nama, no_hp: b.no_hp?.trim() || null,
    });
    if (error) return rollback("Gagal menyimpan wali murid", 500);
  }

  return json({ id, username }, 201);
});

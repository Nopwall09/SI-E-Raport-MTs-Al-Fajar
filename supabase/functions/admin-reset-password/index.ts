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

// Tanpa 0/O/1/l/I agar mudah dibaca dan diketik ulang.
const ALFABET = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const acak = (n: number) =>
  Array.from(crypto.getRandomValues(new Uint8Array(n)), (b) => ALFABET[b % ALFABET.length]).join("");

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "Method tidak didukung" }, 405);

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // Hanya admin aktif yang boleh mereset password.
  const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
  const { data: caller } = await admin.auth.getUser(token);
  if (!caller.user) return json({ error: "Sesi tidak valid" }, 401);
  const { data: me } = await admin
    .from("users").select("role,is_active").eq("id", caller.user.id).maybeSingle();
  if (me?.role !== "admin" || !me.is_active) return json({ error: "Hanya admin" }, 403);

  let b: Record<string, string>;
  try { b = await req.json(); } catch { return json({ error: "Body bukan JSON" }, 400); }
  if (!b.user_id) return json({ error: "user_id wajib diisi" }, 400);
  if (b.user_id === caller.user.id)
    return json({ error: "Gunakan menu Profil untuk mengganti password sendiri" }, 400);

  const { data: target } = await admin.from("users").select("username").eq("id", b.user_id).maybeSingle();
  if (!target) return json({ error: "Pengguna tidak ditemukan" }, 404);

  const password = acak(10);
  const { error: authErr } = await admin.auth.admin.updateUserById(b.user_id, { password });
  if (authErr) return json({ error: "Gagal mereset password" }, 500);
  const { error } = await admin.from("users").update({ must_change_password: true }).eq("id", b.user_id);
  if (error) return json({ error: "Password direset, tetapi penanda ganti password gagal disimpan" }, 500);

  return json({ username: target.username, password });
});

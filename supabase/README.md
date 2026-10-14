# Backend Supabase

Cermin dari yang berjalan di proyek Supabase `ncjvviupomqcpbinnvdn` (UAS PTT).
Dipakai untuk membuat ulang database yang sama.

| Path | Isi |
|---|---|
| `migrations/..._init_schema.sql` | 12 tabel sesuai ERD di Figma, fungsi helper, `get_my_profile()`, RLS per role |
| `migrations/..._seed_referensi_dan_progres_nilai.sql` | tingkat 7/8/9, tahun ajaran aktif, `admin_progres_input_nilai()` |
| `functions/admin-create-user/` | Edge Function pembuat akun (butuh service role, hanya admin yang boleh memanggil) |
| `seed.sql` | **data contoh pengembangan**, semua akun berpassword `123456` |

## Membuat ulang di proyek baru

1. Jalankan file di `migrations/` berurutan (SQL Editor, atau `supabase db push` setelah `supabase link`).
2. Deploy fungsi: `supabase functions deploy admin-create-user`
   (`verify_jwt` tetap aktif; fungsi memeriksa sendiri bahwa pemanggil adalah admin).
3. Opsional, hanya untuk pengembangan: jalankan `seed.sql` untuk akun dan data contoh.
4. Ubah URL dan publishable key bawaan di `lib/core/config/env.dart`.

Username login diubah aplikasi menjadi `username@eraport.example.com`. Domain itu
harus sama di `Env.authEmailDomain` (Flutter) dan `AUTH_EMAIL_DOMAIN` (Edge Function).

## Catatan

- Password disimpan Supabase Auth, bukan di tabel `users`.
- Akun baru dibuat lewat Edge Function (password minimal 8 karakter). Akun siswa belum didukung.
- Jangan menaruh service role key di aplikasi atau repo.

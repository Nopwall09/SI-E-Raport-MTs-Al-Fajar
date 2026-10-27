# Backend Supabase

Cermin dari yang berjalan di proyek Supabase `ncjvviupomqcpbinnvdn` (UAS PTT).
Dipakai untuk membuat ulang database yang sama.

| Path | Isi |
|---|---|
| `migrations/..._init_schema.sql` | 12 tabel sesuai ERD di Figma, fungsi helper, `get_my_profile()`, RLS per role |
| `migrations/..._seed_referensi_dan_progres_nilai.sql` | tingkat 7/8/9, tahun ajaran aktif, `admin_progres_input_nilai()` |
| `migrations/..._sprint12_ganti_password_dan_rapor.sql` | kolom `users.must_change_password`, RPC `selesai_ganti_password()`, trigger yang membuat 2 baris rapor per pendaftaran kelas (+ backfill) |
| `migrations/..._device_token.sql` | tabel `device_token` (token FCM per perangkat, RLS: hanya milik sendiri) dan RPC `daftarkan_device_token()` |
| `migrations/..._finalisasi_dan_penguncian_rapor.sql` | alur ACC rapor (`menunggu_acc`, `final`), RPC `ajukan_acc_rapor()`, `finalisasi_rapor()`, `buka_kunci_rapor()`, dan trigger penguncian nilai `detnilai` |
| `functions/kirim-notifikasi-rapor/` | Kirim notifikasi "rapor final" lewat FCM ke siswa dan wali murid satu kelas; hanya wali kelas kelas itu yang boleh memanggil; butuh secret `FIREBASE_SERVICE_ACCOUNT` |
| `functions/admin-create-user/` | Edge Function pembuat akun (butuh service role, hanya admin yang boleh memanggil) |
| `functions/admin-reset-password/` | Reset password pengguna ke password sementara acak, menandai wajib ganti |
| `functions/admin-import-siswa/` | Impor siswa per batch (maks. 100 baris): membuat akun siswa (username = NIS), data siswa, dan pendaftaran kelas; idempoten per NIS |
| `seed.sql` | **data contoh pengembangan**, semua akun berpassword `123456` |

## Membuat ulang di proyek baru

1. Jalankan file di `migrations/` berurutan (SQL Editor, atau `supabase db push` setelah `supabase link`).
2. Deploy fungsi setelah migration (fungsi memakai kolom `must_change_password`):
   `supabase functions deploy admin-create-user admin-reset-password admin-import-siswa`
   (`verify_jwt` tetap aktif; fungsi memeriksa sendiri bahwa pemanggil adalah admin).
   Untuk notifikasi: `supabase functions deploy kirim-notifikasi-rapor`, lalu isi secret
   `FIREBASE_SERVICE_ACCOUNT` dengan seluruh isi berkas kunci layanan Firebase
   (Dashboard, Edge Functions, Secrets). Berkas kunci itu jangan masuk repo.
3. Opsional, hanya untuk pengembangan: jalankan `seed.sql` untuk akun dan data contoh.
4. Ubah URL dan publishable key bawaan di `lib/core/config/env.dart`.

Username login diubah aplikasi menjadi `username@eraport.example.com`. Domain itu
harus sama di `Env.authEmailDomain` (Flutter) dan `AUTH_EMAIL_DOMAIN` (Edge Function).

## Catatan

- Password disimpan Supabase Auth, bukan di tabel `users`.
- Akun guru, wali murid, dan admin dibuat lewat `admin-create-user` (password minimal 8 karakter); akun siswa dibuat oleh `admin-import-siswa`. Semua akun baru wajib mengganti password saat masuk pertama.
- Format Excel impor: sheet pertama, header `nis, nisn, nama, jk, tgl_lahir, kelas` (nis, nama, jk, tgl_lahir wajib).
- Jangan menaruh service role key di aplikasi atau repo.

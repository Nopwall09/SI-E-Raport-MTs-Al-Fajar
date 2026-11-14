# E-Raport MTs Al Fajar (mobile)

Aplikasi Flutter (Android) untuk sistem E-Raport dan Portal Wali Murid
MTs Al Fajar Kandat. Backend memakai Supabase (Auth, Postgres + RLS, Edge
Functions, Storage). Tidak ada server backend sendiri dan tidak ada web.

Status saat ini (Sprint 4 - Pertemuan 11 / Penyempurnaan Fitur & Integrasi):
Seluruh modul aplikasi telah diintegrasikan secara utuh.
- **Admin**: Manajemen data master (siswa, guru, kelas, mapel, tahun ajaran), manajemen pengguna, reset password, impor siswa dari Excel, monitoring kesiapan rapor kelas, ACC & finalisasi rapor kelas, pemicu notifikasi FCM, serta pembukaan kunci rapor untuk revisi data.
- **Guru & Wali Kelas**: Beranda terpadu penugasan mapel, pengisian nilai siswa (UTS/tugas), monitoring progres kelengkapan nilai kelas, pengisian presensi (sakit/izin/alpa) dan catatan kepribadian siswa, cetak rekapitulasi presensi kelas berformat PDF, serta pengajuan ACC rapor ke pihak madrasah.
- **Siswa & Wali Murid**: Beranda akademik, grafik tren capaian belajar, rekapitulasi nilai per mata pelajaran dengan filter kategori, catatan wali kelas, status kelulusan/tuntas, pratinjau lembar rapor digital berstandar madrasah dengan verifikasi QR Code, serta unduh lembar rapor resmi berformat PDF.
- **Keamanan & Kecepatan**: Otentikasi Supabase, proteksi RLS ketat, database trigger penguncian nilai saat status rapor final, RPC security definer, dan caching offline.

`landing/` berisi halaman profil statis (HTML dan CSS tanpa build) untuk
memperkenalkan aplikasi. Tautan unduh APK diisi di `data-apk-url` pada
`landing/index.html`.

Skema database, Edge Function pembuat akun, dan data contoh ada di
`supabase/` (lihat `supabase/README.md`).

## Menjalankan

```bash
flutter pub get
flutter run
```

Aplikasi langsung tersambung ke Supabase proyek ini. Semua akun contoh
memakai password `123456`: `admin`, `guru1`-`guru5`, `wali1`-`wali6`,
`siswa1`-`siswa3`.

Anon key boleh ada di aplikasi karena keamanan dijaga RLS. Service role key
tidak boleh pernah masuk ke aplikasi atau repo.

## Struktur

```
lib/
  main.dart
  app/        app, tema, router, shell navigasi, daftar tab per role
  core/       config, error, provider Supabase, widget bersama
  features/
    auth/         domain/ data/ presentation/
    admin/        data/ presentation/   (repository dan provider admin)
    nilai/        data/ presentation/   (input nilai guru)
    wali_kelas/   data/ presentation/   (progres nilai kelas wali)
    dashboard/    presentation/
  screens/admin/  layar admin
  widgets/        komponen bersama (kartu statistik, animasi)
supabase/         migration, Edge Function, seed
```

Aturan: layar tidak memanggil Supabase langsung. Layar memakai controller,
controller memakai repository, dan repository yang berbicara dengan Supabase.
Setiap repository punya implementasi asli (`Supabase...`) dan contoh
(`Fake...`), dipilih di satu tempat (`authRepositoryProvider`).

## Kontrak backend yang diasumsikan

Konfirmasi saat skema Postgres dibuat.

- **Login:** pengguna mengetik username, aplikasi masuk ke Supabase Auth dengan
  email `username@<AUTH_EMAIL_DOMAIN>`. Akun dibuat Admin TU lewat Edge
  Function, dengan email dan domain yang sama.
- **`get_my_profile()`** (fungsi Postgres) mengembalikan json untuk pengguna
  yang login: `{"id": "<uuid>", "name": "...", "role": "guru", "wali_kelas":
  null atau {"kelas_id": 3, "nama": "7A"}}`. `role` bernilai `admin`, `guru`,
  `siswa`, atau `wali_murid`. Wali kelas bukan role, jadi `wali_kelas` wajib
  ada agar menu wali kelas muncul.
- **Kode error Postgres** dipetakan ke pesan pengguna: `42501` (ditolak RLS),
  `P0001` (aturan bisnis dari trigger/RPC, pesannya ditampilkan apa adanya,
  mis. rapor sudah final), `23505` (data ganda), `23514` (melanggar CHECK).

Sesi disimpan oleh `supabase_flutter` (secara bawaan di penyimpanan privat
aplikasi) dan token di-refresh otomatis. Bila nanti dibutuhkan penyimpanan
terenkripsi, ganti `LocalStorage` lewat `FlutterAuthClientOptions`.

## Merapikan repo (sekali saja)

Web dan desktop tidak dipakai, jadi bisa dihapus:

```bash
rm -rf web windows linux macos
```

Ganti `applicationId` (`android/app/build.gradle.kts`) dan nama aplikasi
(`android/app/src/main/AndroidManifest.xml`) sebelum build rilis pertama.
Kalau paket Kotlin ikut berganti, pindahkan juga `MainActivity.kt` ke folder
paket yang baru.

## Pengujian

```bash
flutter analyze
flutter test
```

CI (`.github/workflows/flutter.yml`) menjalankan keduanya di setiap PR.

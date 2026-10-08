# E-Raport MTs Al Fajar (mobile)

Aplikasi Flutter (Android) untuk sistem E-Raport dan Portal Wali Murid
MTs Al Fajar Kandat. Backend memakai Supabase (Auth, Postgres + RLS, Edge
Functions, Storage). Tidak ada server backend sendiri dan tidak ada web.

Skeleton ini mencakup target Sprint 1 sisi aplikasi: struktur folder, login,
router dan shell navigasi per role. Fitur penilaian, rapor, dan layar admin
masih berupa halaman sementara.

## Menjalankan

```bash
flutter pub get
flutter run                       # data contoh, tanpa Supabase
```

Akun contoh (password bebas, asal tidak kosong):
`admin`, `guru`, `walikelas`, `siswa`, `wali`.

Memakai Supabase asli:

```bash
flutter run \
  --dart-define=USE_FAKE_API=false \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=eyJ...
```

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
    dashboard/    presentation/
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

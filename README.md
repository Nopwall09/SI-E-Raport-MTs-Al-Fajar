# E-Raport MTs Al Fajar (mobile)

Aplikasi mobile Flutter untuk sistem E-Raport dan Portal Wali Murid
MTs Al Fajar Kandat. Web dan API dikerjakan terpisah di Laravel.

Skeleton ini mencakup target Sprint 1 sisi mobile: struktur folder, API client,
login dengan token aman, dan shell navigasi per role. Fitur penilaian dan
rapor masih berupa halaman sementara.

## Menjalankan

```bash
flutter pub get
flutter run                       # data contoh, tanpa backend
```

Akun contoh (password bebas, asal tidak kosong):
`admin`, `guru`, `walikelas`, `siswa`, `wali`.

Memakai API asli:

```bash
flutter run \
  --dart-define=USE_FAKE_API=false \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

`10.0.2.2` adalah alamat localhost laptop dari emulator Android. Di HP fisik,
pakai IP laptop di jaringan yang sama.

## Struktur

```
lib/
  main.dart
  app/        app, tema, router, shell navigasi, daftar tab per role
  core/       config, error, network (Dio), storage token, widget bersama
  features/
    auth/         domain/ data/ presentation/
    dashboard/    presentation/
```

Aturan: layar tidak memanggil Dio langsung. Layar memakai controller, controller
memakai repository, dan repository yang berbicara dengan API. Setiap repository
punya implementasi asli (`Api...`) dan contoh (`Fake...`), dipilih di satu
tempat (`authRepositoryProvider`).

## Kontrak API yang diasumsikan

Konfirmasi dengan jalur backend sebelum menyambungkan API asli.

| Endpoint | Respons |
| --- | --- |
| `POST /auth/login` `{username, password, device_name}` | `200 {"data": {"token", "user": {...}}}` |
| `GET /auth/me` | `200 {"data": {"id", "name", "role", "wali_kelas": null atau {"kelas_id", "nama"}}}` |
| `POST /auth/logout` | `200` atau `204` |

`role` bernilai `admin`, `guru`, `siswa`, atau `wali_murid`. Wali kelas bukan
role, jadi `wali_kelas` wajib ada di `/auth/me` agar menu wali kelas muncul.
Error mengikuti konvensi: 401 sesi habis, 403 ditolak, 409 rapor sudah final,
422 validasi (`{"message", "errors": {kolom: [pesan]}}`).

## Merapikan repo (sekali saja)

Web sudah dipegang Laravel, jadi platform yang tidak dipakai bisa dihapus:

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

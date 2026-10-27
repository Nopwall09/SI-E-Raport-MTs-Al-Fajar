# Catatan tim: apa yang baru di branch `fitur-asli`

Baca ini sebelum lanjut ngoding, supaya tidak bentrok dengan yang sudah dikerjakan.
Isinya: apa yang berubah, apa yang berpengaruh ke pekerjaan kalian, dan apa yang masih
terbuka.

## 1. Status singkat

- **Sprint 1 dan 2 selesai**, sudah di-deploy ke Supabase dan sudah diuji di HP.
- Branch Nopal (beranda guru terpadu) sudah digabung.
- Siswa sekarang memakai halaman wali murid.
- Data karangan di layar wali murid sudah dibuang.
- Sprint 3 (finalisasi, layar Rapor, PDF, FCM) belum jadi. Pembagiannya ada di bagian 6.

Mulai kerja dari branch ini: `git fetch && git switch -c <branch-kalian> origin/fitur-asli`.
Branch lama (`Nopal`, `Dimas`, `mumu`) ketinggalan, jadi `git merge origin/fitur-asli`
dulu sebelum push.

## 2. Perubahan yang pasti kena ke kalian

| Perubahan | Kenapa penting |
|---|---|
| Tab **Wali kelas dihapus**. Daftar siswa kelas ada di Beranda guru. | Jangan tambahkan lagi `WaliKelasPage`. Form presensi ada di `lib/features/wali_kelas/presentation/presensi_form.dart`, dipanggil dari kartu siswa di `guru_beranda_page.dart`. |
| **Siswa memakai halaman wali murid** (judul "Perkembangan Saya"). Tab Rapor placeholder dihapus. | `tabsFor(UserRole.siswa)` di `role_tabs.dart` hanya Beranda dan Profil. |
| **`WaliMuridRepository` tidak lagi mengembalikan data contoh.** Kosong tampil "Belum ada ...", error asli tampil di layar. | Jangan menambah fallback nilai, rata-rata, atau catatan bawaan. Orang tua bisa mengira itu data asli. |
| **Akun baru dan hasil reset wajib ganti password** saat masuk pertama. | Ada kolom `users.must_change_password`. Router mengalihkan ke `/ganti-password`. |
| **Setiap siswa yang didaftarkan ke kelas otomatis punya 2 baris rapor** (ganjil dan genap, draft). | Trigger `kelas_siswa_buat_rapor`. Tidak perlu insert rapor manual. |

Titik rawan konflik saat merge: `role_tabs.dart`, `router.dart`, `guru_beranda_page.dart`,
`wali_murid_repository.dart`, `wali_murid_page.dart`. Tarik `fitur-asli` sering-sering.

**Jangan jalankan `dart format` ke seluruh proyek.** File wali murid belum terformat, jadi
format massal membuat diff ratusan baris yang tidak ada hubungannya. Format hanya file
yang kalian ubah.

## 3. Fitur baru (Sprint 1 dan 2)

- **Ganti password wajib**: `lib/features/auth/presentation/ganti_password_page.dart`. Juga
  bisa dibuka sukarela dari Profil.
- **Reset password pengguna** oleh admin: sheet aksi di layar Pengguna. Password sementara
  tampil sekali.
- **Impor siswa dari Excel**: ikon upload di layar Data Siswa
  (`lib/screens/admin/admin_impor_siswa_screen.dart`, parser di
  `lib/features/admin/data/impor_siswa.dart`).
  - Sheet pertama, header `nis, nisn, nama, jk, tgl_lahir, kelas`. `nis`, `nama`, `jk`
    (L/P), `tgl_lahir` wajib. `kelas` harus sama dengan nama kelas di tahun ajaran aktif.
  - NIS jadi username, password awal acak ditampilkan sekali. NIS yang sudah ada dilewati.
  - Berkas dari openpyxl atau pandas juga terbaca.
- **Presensi dan catatan wali kelas**: sakit, izin, alpa, catatan per siswa untuk semester
  aktif. Terkunci otomatis kalau rapor sudah final.

## 4. Backend (Supabase)

Proyek `ncjvviupomqcpbinnvdn` (satu database bersama, hati-hati).

- Migration terbaru: `supabase/migrations/20261027000007_sprint12_ganti_password_dan_rapor.sql`
  (sudah diterapkan).
- Edge Function: `admin-create-user` (versi 2), `admin-reset-password`, `admin-import-siswa`
  (semuanya sudah ter-deploy).
- Bikin migration baru? Tambahkan file di `supabase/migrations/` dengan nomor urut berikutnya
  **dan** terapkan ke proyek, lalu catat di `supabase/README.md`. Tidak ada Postgres lokal,
  jadi cek logika RLS dan trigger langsung di proyek.
- **Jangan pernah** commit service role key, atau kunci adminsdk Firebase. `.gitignore`
  sudah mengabaikan polanya, tapi tetap periksa sebelum `git add`.
- Akun contoh dan password ada di `README.md`. Akun-akun itu dipakai bersama. Kalau uji
  reset password atau impor, pakai akun atau data uji sendiri lalu hapus setelahnya.

## 5. Menjalankan dan menguji

```bash
flutter pub get
flutter analyze        # harus bersih
flutter test           # 36 tes harus lulus
flutter run
```

Tes memakai override (`test/helpers/test_overrides.dart`), jadi tidak menyentuh Supabase.
Kalau menambah field wajib di model seperti `SiswaProgres`, perbarui override itu juga.

## 6. Yang masih terbuka (Sprint 3)

| Pekerjaan | Pemilik | Catatan |
|---|---|---|
| Finalisasi rapor | **Dimas** | Lihat kontrak di bawah. |
| Layar Rapor siswa dan wali murid | **Dimas** | Tujuan ketukan notifikasi. Tanpa PDF dulu. Rute yang akan dipakai notifikasi: `/siswa/rapor` dan `/wali-murid/rapor?siswa=ID`. |
| Notifikasi FCM | Syakir | Rancangan di `docs/superpowers/specs/2026-10-27-fcm-notifikasi-rapor-design.md`. Uji coba ada di branch lokal `spike-fcm` (belum di-push). |
| PDF rapor dan absensi, buka kunci rapor | belum ada pemilik | Buka kunci menunggu keputusan sekolah. |

### Untuk Dimas (finalisasi dan layar Rapor)

FCM bergantung pada empat hal ini dari finalisasi:

1. Setelah finalisasi, baris `rapor` kelas itu pada semester itu berstatus `final`.
2. Finalisasi dipanggil dari aplikasi oleh wali kelas dan hasilnya sukses atau galat.
   Sesudah sukses, aplikasi memanggil fungsi pengirim notifikasi (satu baris, nanti
   disambung bersama).
3. Gagal kirim notifikasi tidak boleh membalikkan finalisasi.
4. Rapor final tidak bisa berubah lagi.

**Perhatian: saat ini nilai (`detnilai`) belum terkunci walau rapor final.** Guru mapel
masih bisa mengubah nilai lewat RLS. Itu perlu ditutup di bagian finalisasi, mis. trigger
yang menolak ubah `detnilai` kalau rapor siswa itu pada semester itu sudah final.

Kabari Syakir: nama RPC atau fungsinya, berkas layar tempat tombolnya, dan apakah layar
Rapor bisa dibuka langsung untuk satu anak lewat rute di atas.
Syarat dari dokumen rancangan: finalisasi hanya bila nilai semua mapel semua siswa terisi
(belum dikonfirmasi sekolah).

## 7. Keputusan sekolah yang masih menggantung

- SKM satu angka atau per mapel (kalau per mapel, `skm_snapshot` pindah ke `detnilai`).
- Siapa yang boleh membuka kunci rapor final.
- Format contoh rapor untuk PDF.
- Boleh tidaknya finalisasi saat ada nilai mapel yang kosong.

## 8. Hal yang diketahui belum beres

- Siswa dan wali murid belum bisa melihat **nama wali kelas** (RLS membatasi tabel `guru`).
  Chip "Wali:" sengaja disembunyikan.
- Grafik perkembangan di layar wali murid tidak muncul. Sistem hanya punya nilai UTS, tidak
  ada riwayat UH/PTS/PAS.
- Siswa dan wali murid hanya bisa membaca presensi dan catatan setelah rapor final (RLS).
  Sebelum itu tampil nol dan "Belum ada catatan".
- Belum teruji di HP: impor ulang berkas yang sama, dan impor baris dengan kolom `nisn`.

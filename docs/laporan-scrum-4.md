# Laporan Pelaksanaan Scrum 4 (Pertemuan 11)
## Proyek Teknologi Terintegrasi (PTT) - E-Raport MTs Al Fajar Kandat

---

### 1. Informasi Sprint
* **Fase / Sprint:** Scrum 4 (Sprint 4)
* **Pertemuan Silabus:** Pertemuan 11 (Implementasi Scrum 4 - Penyempurnaan Fitur)
* **Target Mingguan:** Menyelesaikan seluruh fitur aplikasi dan mengoptimalkan kualitas sistem secara keseluruhan.
* **Cek Poin (Deliverables):**
  1. Pelaksanaan Sprint 4: Finishing seluruh fitur aplikasi, pembenahan aspek Usability (UI/UX), serta optimalisasi keamanan dan kecepatan sistem.
  2. Integrasi akhir seluruh modul yang telah dibuat.

---

### 2. Ringkasan Eksekutif Hasil Integrasi Modul
Pada Sprint 4 ini, seluruh pekerjaan modul yang sebelumnya dikembangkan secara terpisah oleh tim telah berhasil diintegrasikan ke dalam cabang kerja `sprint-4-penyempurnaan`:
1. **Modul Rapor & Ekspor PDF Siswa (Branch `Dimas`):**
   - Layar Beranda Siswa (`siswa_beranda_page.dart`) dan Layar Rapor Siswa (`siswa_rapor_page.dart`).
   - Dialog Pratinjau Lembar Rapor Digital resmi madrasah (`lembar_rapor_dialog.dart`).
   - Layanan penyusunan dan pengunduhan dokumen PDF Rapor standar ISO 32000-1 dengan logo sekolah & QR code verifikasi (`pdf_rapor_service.dart`).
2. **Modul Finalisasi Rapor, Cetak Absensi & Buka Kunci (Branch `mumu`):**
   - Alur pengajuan verifikasi/ACC oleh wali kelas di Beranda Guru (`guru_beranda_page.dart`).
   - Layanan penyusunan dokumen PDF Rekapitulasi Presensi Siswa (`absensi_pdf_service.dart`).
   - Aksi pengesahan (ACC), finalisasi, dan pembukaan kunci rapor di layar Admin (`admin_data_rapor_screen.dart`).
   - Migrasi database penguncian nilai dan status alur ACC (`20261027000009_finalisasi_dan_penguncian_rapor.sql`).
3. **Modul Push Notifikasi FCM (Branch `syakir`):**
   - Registrasi token FCM perangkat (`device_token`).
   - Edge Function Supabase `kirim-notifikasi-rapor` yang otomatis dipanggil setelah admin/wali kelas memfinalisasi rapor kelas.
4. **Modul Portal Wali Murid & Monitoring (Branch `Nopal`):**
   - Monitoring perkembangan belajar berkala, grafik tren nilai, rekapitulasi nilai dan presensi anak.
   - Telah ditautkan langsung dengan dialog pratinjau lembar rapor resmi dan unduh PDF untuk orang tua.

---

### 3. Rincian Penyelesaian Fitur (Feature Finishing)

```
[Guru Mapel]                 [Wali Kelas]                     [Admin / Kamad]                   [Siswa & Wali Murid]
Input Nilai UTS/Tugas  --->  Isi Presensi & Catatan  --->  Verifikasi & Finalisasi  --->  Menerima Notifikasi FCM
                             Ajukan ACC Rapor              (Nilai & Rapor Dikunci)        Melihat & Unduh PDF Rapor
                             Cetak Rekap Presensi PDF      (Tersedia Buka Kunci)
```

1. **Alur Siklus Rapor Terpadu:**
   - **Tahap Pengisian (Draft):** Guru mapel mengisi nilai; wali kelas melengkapi absensi (sakit, izin, alpa) dan catatan kepribadian.
   - **Tahap Pengajuan (Menunggu ACC):** Wali kelas memeriksa kelengkapan nilai lalu menekan tombol *Ajukan ACC Rapor*. Status berubah menjadi `menunggu_acc`.
   - **Tahap Pengesahan & Penguncian (Final):** Admin/Kepala Madrasah memeriksa kesiapan seluruh siswa di kelas terkait pada menu *Data Rapor*. Saat menekan *ACC & Finalisasi*, sistem:
     - Mengunci baris data `rapor` menjadi `final`.
     - Mencatat snapshot SKM, tanggal finalisasi, dan identitas pengesah.
     - Mengunci tabel `detnilai` via database trigger sehingga nilai tidak dapat diubah lagi.
     - Menjalankan Edge Function `kirim-notifikasi-rapor` untuk mengirim notifikasi push FCM ke perangkat siswa dan orang tua.
   - **Tahap Revisi (Buka Kunci Rapor):** Apabila terdapat kekeliruan data setelah finalisasi, Admin memiliki hak istimewa (*UC-13*) untuk membuka kembali kunci rapor menjadi `draft`.

2. **Cetak Dokumen Resmi (PDF):**
   - **Rekapitulasi Presensi Kelas:** Dicetak langsung oleh wali kelas menggunakan `AbsensiPdfService` lengkap dengan kop yayasan/madrasah dan tanda tangan wali kelas.
   - **Lembar Rapor Digital:** Diakses oleh siswa maupun wali murid melalui `LembarRaporDialog` dan diunduh ke penyimpanan lokal HP dengan nama file standar madrasah (`Rapor_MTsAlFajar_[NIS]_[Semester].pdf`).

---

### 4. Pembenahan Aspek Usability (UI/UX)
* **Indikator Visual Status Rapor:**
  - Badge dinamis dengan warna tematik:
    - `Draft Pengisian`: Abu-abu / Amber.
    - `Menunggu ACC`: Oranye / Info.
    - `Final (ACC)`: Hijau tua (`#0D5C3A`) dengan ikon ceklis.
* **Dialog Konfirmasi Aksi Kritis:**
  - Konfirmasi pengajuan ACC dan finalisasi menyertakan deteksi otomatis berapa siswa yang nilainya masih belum lengkap agar tidak terjadi ketidaksengajaan.
* **Integrasi Unduh Rapor Wali Murid:**
  - Tombol *Unduh Laporan Perkembangan (PDF)* pada layar Wali Murid kini langsung menampilkan lembar pratinjau digital resmi dan tombol unduh/cetak, bukan lagi notifikasi statis.
* **Navigasi & Shell Role:**
  - Setiap role (Admin, Guru, Siswa, Wali Murid) memiliki navigasi bawah (*Bottom Navigation Bar*) dan drawer yang terisolasi dan rapi sesuai hak aksesnya.

---

### 5. Optimalisasi Keamanan & Kecepatan Sistem

#### A. Keamanan (Security)
1. **Database Trigger Penguncian Nilai:**
   - Diterapkan trigger `trg_kunci_detnilai` pada event `BEFORE UPDATE OR DELETE ON public.detnilai`. Jika status rapor siswa pada semester tersebut sudah `final`, operasi manipulasi nilai akan ditolak di tingkat database dengan exception code `P0001`.
2. **Row Level Security (RLS) & RPC Security Definer:**
   - Prosedur tersimpan `ajukan_acc_rapor`, `finalisasi_rapor`, dan `buka_kunci_rapor` menggunakan klausa `SECURITY DEFINER` dengan validasi ketat `auth.uid()` terhadap kepemilikan kelas (`wali_kelas_id`) atau role admin (`is_admin()`).
3. **Penyimpanan Kredensial & Secrets:**
   - Kunci sensitif Firebase Service Account disimpan di Supabase Secrets (tidak pernah masuk ke repositori). Anon Key di aplikasi hanya memiliki hak akses terbatas sesuai RLS.

#### B. Kecepatan (Performance)
1. **Query Terpadu & Paralelisasi:**
   - Pengambilan data progres siswa dan status rapor dioptimalkan dengan `Future.wait` untuk meminimalkan round-trip request ke server Supabase.
2. **Offline Caching:**
   - Filter preferensi kelas/semester disimpan lokal via `SharedPreferences`.
   - Data tabel rapor didukung fitur *Simpan untuk Offline* berbasis SQLite untuk akses cepat tanpa koneksi internet.

---

### 6. Status Kesiapan Menuju Pertemuan 12 (Review Scrum 4)
* **Status Proyek:** **Feature Freeze Ready** (Seluruh fitur fungsional telah selesai dan terintegrasi).
* **Target Pertemuan 12:**
  - Demo aplikasi secara utuh (Feature Freeze) di internal kelas.
  - Final code review dan persiapan rilis versi Beta untuk pengujian lanjutan.

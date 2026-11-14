# Buku Petunjuk Penggunaan Sistem (User Manual)
## E-Raport & Portal Wali Murid MTs Al Fajar Kandat
**Mata Kuliah: Proyek Teknologi Terintegrasi (PTT) - Pertemuan 15**

---

### Daftar Isi
1. [Tentang Sistem E-Raport Al-Fajar](#1-tentang-sistem-e-raport-al-fajar)
2. [Panduan Administrator Tata Usaha (Admin TU)](#2-panduan-administrator-tata-usaha-admin-tu)
3. [Panduan Guru Mata Pelajaran](#3-panduan-guru-mata-pelajaran)
4. [Panduan Guru Wali Kelas](#4-panduan-guru-wali-kelas)
5. [Panduan Siswa & Wali Murid](#5-panduan-siswa--wali-murid)
6. [Tanya Jawab & Penanganan Masalah (Troubleshooting)](#6-tanya-jawab--penanganan-masalah-troubleshooting)

---

### 1. Tentang Sistem E-Raport Al-Fajar
Aplikasi mobile **E-Raport MTs Al Fajar** adalah aplikasi Android berbasis *cloud* terintegrasi yang dikembangkan untuk mempermudah:
* Pengolahan nilai oleh guru mata pelajaran.
* Perekapan absensi dan pengajuan verifikasi oleh wali kelas.
* Pengesahan, penguncian data, dan cetak rapor oleh admin tata usaha.
* Pemantauan perkembangan belajar dan unduh rapor digital secara langsung oleh orang tua siswa.

---

### 2. Panduan Administrator Tata Usaha (Admin TU)

#### 2.1 Masuk Sistem & Pengaturan Akun
1. Buka aplikasi di perangkat Android Anda.
2. Masukkan **Username** (`admin`) dan **Password** Anda.
3. Jika akun baru atau baru saja di-reset, sistem akan otomatis mewajibkan Anda mengisi kata sandi baru minimal 8 karakter pada layar **Ganti Password**.

#### 2.2 Impor Siswa dari Excel
1. Buka menu samping (*Drawer*) di pojok kiri atas -> Pilih **Data Siswa**.
2. Ketuk ikon **Upload / Impor Excel** di kanan atas.
3. Pilih berkas Excel dengan format kolom: `nis, nisn, nama, jk, tgl_lahir, kelas`.
4. Sistem akan menampilkan pratinjau data. Ketuk **Mulai Impor**. Akun siswa otomatis dibuat dengan NIS sebagai username dan password acak sementara.

#### 2.3 Monitoring & Pengesahan (ACC) Rapor Kelas
1. Buka menu samping -> Pilih **Data Rapor**.
2. Pilih kelas dan semester aktif (Ganjil/Genap).
3. Periksa persentase kelengkapan nilai tiap siswa:
   * **Status Draft:** Nilai masih dalam proses pengisian oleh guru mapel.
   * **Status Menunggu ACC:** Wali kelas telah mengajukan rapor untuk diverifikasi.
4. Jika seluruh nilai telah lengkap dan disetujui Kepala Madrasah, ketuk tombol **ACC & Sahkan Rapor**:
   * Seluruh nilai dan presensi terkunci permanen.
   * Notifikasi push FCM otomatis dikirim ke HP siswa dan orang tua.

#### 2.4 Buka Kunci Rapor (*Revisi Nilai*)
Jika terdapat kesalahan pengisian nilai yang dilaporkan guru setelah finalisasi:
1. Masuk ke menu **Data Rapor** -> Pilih kelas yang dimaksud.
2. Ketuk tombol **Buka Kunci Rapor** -> Konfirmasi persetujuan.
3. Status rapor kembali ke `draft` sehingga guru mapel dapat memperbaiki nilainya kembali.

---

### 3. Panduan Guru Mata Pelajaran

#### 3.1 Mengisi Nilai Siswa
1. Masuk menggunakan akun guru Anda (contoh: `guru2`).
2. Masuk ke tab **Nilai** pada navigasi bawah.
3. Pilih rombel/kelas yang diajar dan mata pelajaran yang diampu.
4. Masukkan angka nilai capaian siswa (rentang 0 s.d. 100, batas SKM madrasah adalah 75).
5. Ketuk tombol **Simpan Nilai**.

> **Perhatian:** Apabila rapor kelas tersebut sudah disahkan (*final*) oleh madrasah, kolom nilai tidak dapat diedit kembali demi menjaga integritas data. Hubungi Admin TU jika memerlukan revisi resmi.

---

### 4. Panduan Guru Wali Kelas

#### 4.1 Mengisi Presensi & Catatan Siswa
1. Masuk menggunakan akun guru wali kelas Anda (contoh: `guru1`).
2. Pada **Beranda Guru**, temukan kartu **Progres Nilai Kelas [Nama Kelas]**.
3. Ketuk nama siswa yang ingin dilengkapi:
   * Masukkan jumlah hari **Sakit**, **Izin**, dan **Alpa** semester berjalan.
   * Ketikkan catatan motivasi/kepribadian siswa untuk lembar rapor.
   * Ketuk **Simpan Presensi & Catatan**.

#### 4.2 Mencetak Rekapitulasi Presensi Kelas
1. Pada kartu progres kelas di Beranda, ketuk tombol **Cetak Rekap Presensi**.
2. Sistem akan menyusun dokumen PDF berstandar resmi madrasah lengkap dengan kop surat dan tanda tangan.
3. Anda dapat langsung mempratinjau (*preview*), mencetak (*print* ke printer WiFi), atau membagikannya (*share*) via WhatsApp.

#### 4.3 Mengajukan ACC Rapor
1. Setelah seluruh nilai mapel dan presensi siswa lengkap, ketuk tombol **Ajukan ACC Rapor**.
2. Jika ada siswa yang nilainya belum lengkap, sistem akan memberikan peringatan jumlah siswa terkait.
3. Konfirmasi pengajuan agar pimpinan madrasah dan Admin TU dapat melakukan pengesahan.

---

### 5. Panduan Siswa & Wali Murid

#### 5.1 Masuk & Memilih Profil Anak
1. Masuk menggunakan akun Siswa (NIS) atau akun Wali Murid (contoh: `wali1`).
2. Jika memiliki lebih dari 1 anak yang bersekolah di MTs Al Fajar, pilih nama anak pada *chip* pemilih di bagian atas.

#### 5.2 Memantau Capaian Belajar
1. Pada halaman **Perkembangan Anak**, Anda dapat melihat:
   * **Rata-rata Nilai** dan Predikat Capaian Belajar.
   * **Grafik Tren Perkembangan:** Visualisasi nilai antar-mata pelajaran.
   * **Rekapitulasi Kehadiran:** Jumlah ketidakhadiran sakit, izin, dan tanpa keterangan.
   * **Catatan Wali Kelas:** Ulasan perkembangan karakter dan motivasi belajar ananda.

#### 5.3 Melihat & Mengunduh Lembar Rapor Digital (PDF)
1. Ketuk tombol **Unduh Laporan Perkembangan (PDF)** atau tab **Rapor**.
2. Lembar rapor resmi madrasah akan terbuka di layar:
   * Dilengkapi nomor induk, logo yayasan, rincian nilai tiap mapel beserta SKM, status kelulusan, dan tanda tangan Kepala Madrasah.
   * Dilengkapi **QR Code Verifikasi Keaslian Dokumen**.
3. Ketuk tombol **Unduh** untuk menyimpan berkas PDF secara otomatis ke folder unduhan perangkat HP Anda.

---

### 6. Tanya Jawab & Penanganan Masalah (Troubleshooting)

* **Tanya: Mengapa nilai rapor saya belum muncul atau presensi masih 0?**
  * *Jawab:* Nilai resmi lembar rapor dan absensi baru terbuka bagi siswa dan orang tua setelah rapor kelas resmi disahkan (*final/ACC*) oleh Kepala Madrasah.
* **Tanya: Saya lupa kata sandi akun, bagaimana cara memulihkannya?**
  * *Jawab:* Silakan hubungi bagian Tata Usaha madrasah. Admin TU dapat mereset kata sandi Anda dan memberikan kata sandi sementara yang wajib Anda ganti saat login kembali.
* **Tanya: Di mana lokasi berkas PDF rapor setelah saya menekan tombol unduh?**
  * *Jawab:* Berkas tersimpan di folder *Download* atau penyimpanan internal HP dengan format nama `Rapor_MTsAlFajar_[NIS]_[Semester].pdf`. Berkas dapat langsung dibuka menggunakan aplikasi PDF Viewer apa pun.

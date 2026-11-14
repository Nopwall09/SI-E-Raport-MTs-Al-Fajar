# Instrumen Pengujian Penerimaan Pengguna (User Acceptance Testing - UAT)
## Sistem E-Raport & Portal Wali Murid MTs Al Fajar Kandat
**Mata Kuliah: Proyek Teknologi Terintegrasi (PTT) - Pertemuan 14**

---

### Informasi Pengujian Mitra
* **Nama Mitra / Instansi:** MTs Al Fajar Kandat, Kediri
* **Tanggal Pelaksanaan UAT:** ........................................
* **Nama Penguji (Mitra):** ........................................
* **Jabatan / Peran Penguji:** [ ] Kepala Madrasah   [ ] Admin TU   [ ] Guru / Wali Kelas   [ ] Perwakilan Wali Murid

---

### Petunjuk Pengisian
Berikan tanda centang ($\checkmark$) pada kolom **Diterima** jika fitur berjalan sesuai kebutuhan madrasah, atau **Ditolak** jika fitur belum memenuhi kebutuhan/terdapat kesalahan (*bug*). Tuliskan catatan perbaikan pada kolom yang disediakan.

---

### Bagian 1: Pengujian Fungsionalitas Sistem (Functional Testing)

#### A. Modul Administrator Tata Usaha (Admin TU)
| No | Skenario Fungsional | Kriteria Keberhasilan | Diterima | Ditolak | Catatan / Masukan Mitra |
|:--:|---|---|:---:|:---:|---|
| 1 | Manajemen Master Data | Admin dapat menambah, mengubah, dan menonaktifkan data Guru, Kelas, dan Mata Pelajaran. | [ ] | [ ] | |
| 2 | Impor Siswa Excel | Admin dapat mengunggah berkas Excel dan akun siswa otomatis terdaftar tanpa duplikasi NIS. | [ ] | [ ] | |
| 3 | Reset Password Pengguna | Admin dapat mereset password akun pengguna yang lupa kata sandi dengan password acak sementara. | [ ] | [ ] | |
| 4 | Monitoring Kesiapan Rapor | Admin dapat melihat persentase kelengkapan nilai siswa per kelas secara *real-time*. | [ ] | [ ] | |
| 5 | ACC & Finalisasi Rapor | Admin dapat mengesahkan rapor kelas, mengunci nilai permanen, dan memicu notifikasi FCM. | [ ] | [ ] | |
| 6 | Buka Kunci Rapor (*UC-13*) | Admin dapat membuka kembali status rapor ke *draft* jika dewan guru memerlukan revisi data. | [ ] | [ ] | |

#### B. Modul Guru Mata Pelajaran & Wali Kelas
| No | Skenario Fungsional | Kriteria Keberhasilan | Diterima | Ditolak | Catatan / Masukan Mitra |
|:--:|---|---|:---:|:---:|---|
| 7 | Input Nilai Mata Pelajaran | Guru mapel dapat menginput dan menyimpan nilai UTS/tugas sesuai kelas yang diampu. | [ ] | [ ] | |
| 8 | Presensi & Catatan Wali | Wali kelas dapat mengisi sakit, izin, alpa, serta catatan kepribadian tiap siswa bimbingan. | [ ] | [ ] | |
| 9 | Cetak Rekapitulasi Presensi | Wali kelas dapat mengunduh dan mencetak rekap presensi kelas berformat PDF resmi madrasah. | [ ] | [ ] | |
| 10 | Pengajuan ACC Rapor | Wali kelas dapat mengajukan rapor kelas yang sudah lengkap ke pimpinan madrasah. | [ ] | [ ] | |
| 11 | Perlindungan Data Final | Nilai tidak dapat diubah oleh guru setelah rapor disahkan (*final*) oleh madrasah. | [ ] | [ ] | |

#### C. Modul Siswa & Portal Wali Murid
| No | Skenario Fungsional | Kriteria Keberhasilan | Diterima | Ditolak | Catatan / Masukan Mitra |
|:--:|---|---|:---:|:---:|---|
| 12 | Monitoring Capaian Belajar | Orang tua dan siswa dapat melihat nilai per mata pelajaran dan grafik tren perkembangan belajar. | [ ] | [ ] | |
| 13 | Notifikasi Otomatis | Perangkat siswa/wali menerima pesan notifikasi push ketika rapor resmi telah diterbitkan. | [ ] | [ ] | |
| 14 | Pratinjau Lembar Rapor | Menampilkan lembar rapor digital lengkap dengan kop resmi, tanda tangan, dan verifikasi QR Code. | [ ] | [ ] | |
| 15 | Unduh Dokumen PDF Rapor | Pengguna dapat menyimpan berkas PDF rapor resmi madrasah langsung ke memori penyimpanan HP. | [ ] | [ ] | |

---

### Bagian 2: Evaluasi Aspek Usability & Kualitas Aplikasi
Berikan skor penilaian berdasarkan skala 1 s.d. 5:
*(1 = Sangat Kurang, 2 = Kurang, 3 = Cukup, 4 = Baik, 5 = Sangat Baik)*

| No | Parameter Usability & User Experience | Skor (1 - 5) | Catatan |
|:--:|---|:---:|---|
| 1 | **Kemudahan Penggunaan (*Ease of Use*):** Aplikasi mudah dipahami tanpa instruksi rumit. | [ &nbsp; ] | |
| 2 | **Kesesuaian Tampilan (*UI Design*):** Tata letak, warna hijau madrasah, dan teks nyaman dibaca. | [ &nbsp; ] | |
| 3 | **Kecepatan Akses (*Performance*):** Navigasi antar-layar dan pemuatan data terasa responsif. | [ &nbsp; ] | |
| 4 | **Ketepatan Informasi (*Data Accuracy*):** Nilai, kehadiran, dan rapor digital sesuai standar sekolah. | [ &nbsp; ] | |
| 5 | **Manfaat Sistem (*Utility*):** Membantu mempercepat pengolahan rapor dan mempermudah komunikasi orang tua. | [ &nbsp; ] | |

---

### Bagian 3: Lembar Pengesahan & Berita Acara UAT

Pada hari ini, ..................... Tanggal ....... Bulan ................... Tahun 2026, telah dilaksanakan Pengujian Penerimaan Pengguna (*User Acceptance Testing*) terhadap **Sistem E-Raport & Portal Wali Murid MTs Al Fajar Kandat**.

**Kesimpulan Evaluasi Mitra:**
[ ] Sistem Diterima Penuh (Siap Diimplementasikan)
[ ] Sistem Diterima dengan Catatan Revisi Ringan
[ ] Sistem Belum Dapat Diterima (Perlu Perbaikan Mayor)

**Komentar / Saran Tambahan dari Pihak Mitra:**
.........................................................................................................................................................
.........................................................................................................................................................


Kandat, Kediri, ................................... 2026

**Perwakilan Tim Pengembang (Mahasiswa),** &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; **Perwakilan Pihak Mitra (MTs Al Fajar),**



( ........................................................... ) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ( ........................................................... )
NIM. &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;NIP/Jabatan.

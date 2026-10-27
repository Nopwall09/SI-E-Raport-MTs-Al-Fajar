# Notifikasi rapor final (FCM), beserta finalisasi dan layar Rapor

Dokumen rancangan untuk Sprint 3, epic 13 (UC-04 dan UC-20), dan dua bagian lain yang
harus ada lebih dulu agar notifikasi bisa dipicu dan dibuka.

## Maksud

Orang tua dan siswa seharusnya tahu begitu rapor siap, tanpa harus membuka aplikasi
berkali-kali. Saat wali kelas memfinalisasi rapor, siswa dan wali murid yang
bersangkutan menerima notifikasi di HP. Mengetuknya membuka rapor anak itu.

Kenapa tiga bagian, bukan satu: notifikasi dipicu oleh finalisasi, dan harus membuka
layar Rapor. Keduanya belum ada di aplikasi, jadi FCM tidak bisa diuji tanpa mereka.

Urutan kerja:

1. **A. Finalisasi rapor** (UC-18): **dikerjakan Dimas, bukan bagian dokumen ini.**
   Dokumen ini hanya mencatat apa yang FCM butuhkan darinya (lihat "Kontrak dengan
   finalisasi" di bawah).
2. **B. Layar Rapor** untuk siswa dan wali murid (tujuan ketukan notifikasi, tanpa PDF).
   Dikerjakan Dimas bersama finalisasi.
3. **C. Notifikasi FCM** (UC-04, UC-20): bagian milik dokumen ini.

## Sasaran

- (Bagian Dimas, bukan dokumen ini.) Wali kelas bisa memfinalisasi rapor satu
  kelas untuk semester aktif. Hasilnya rapor terkunci: nilai, presensi, dan catatan tidak
  bisa berubah lagi.
- Siswa dan wali murid melihat rapor final anaknya di layar Rapor.
- Setiap finalisasi mengirim notifikasi ke semua perangkat siswa dan wali murid di
  kelas itu. Isinya tanpa nilai.
- Kegagalan mengirim notifikasi tidak pernah membatalkan atau membalikkan finalisasi.

## Bukan sasaran

- PDF rapor dan PDF absensi (epic 9 dan 11), tombol Unduh tidak dibuat.
- Buka kunci rapor (UC-13), menunggu keputusan sekolah tentang siapa yang berhak.
- Notifikasi untuk peristiwa selain rapor final (nilai baru, pengumuman, dan lain-lain).
- Pengiriman ulang notifikasi, jadwal pengiriman, atau antrean.
- Notifikasi ke iOS (hanya Android yang dipakai proyek ini).

## Hal yang membuat ini gagal walau tampak jalan

- Rapor bisa diubah lagi sesudah final (nilai guru, presensi, catatan).
- Notifikasi memuat nilai, atau terkirim ke orang yang bukan siswa atau walinya.
- Kunci pribadi Firebase masuk ke aplikasi atau repo.
- Wali kelas yang menekan finalisasi menunggu lama atau melihat error karena FCM lambat.

## Keadaan sekarang (diperiksa di kode dan database)

- Tabel `rapor` sudah punya `status` (draft/final), `skm_snapshot`, `finalized_at`,
  `finalized_by`. Dua baris rapor per siswa dibuat trigger (migration 7).
- Policy RLS: wali kelas hanya bisa mengubah rapor berstatus draft. Siswa dan wali murid
  hanya bisa membaca rapor berstatus final.
- **Belum ada** fungsi finalisasi. **Belum ada** penguncian `detnilai` saat rapor final,
  jadi guru mapel masih bisa mengubah nilai walau rapor final. Ini harus ditutup di
  bagian A.
- Tabel `device_token` belum ada. Aplikasi belum memakai Firebase sama sekali.
- Tab siswa dan wali murid kini memakai halaman Perkembangan yang sama (siswa: judul
  "Perkembangan Saya"). Layar Rapor belum ada.
- Berkas dari Firebase: proyek `si-e-mts-al-fajar`, nomor 687490436692, aplikasi
  Android `com.example.si_e_rapor_mts_al_fajar` (sama dengan `applicationId`).

## Kontrak dengan finalisasi (dikerjakan Dimas)

FCM hanya bergantung pada empat hal ini. Bila Dimas menyusunnya berbeda, cukup
sesuaikan di sini, bukan di bagian C:

1. Setelah finalisasi sukses, baris `rapor` kelas itu pada semester itu berstatus
   `final` (kolom dan nilai yang sudah ada di skema).
2. Finalisasi dipanggil dari aplikasi oleh wali kelas dan mengembalikan sukses atau
   galat. Titik pemanggilan di layar itulah tempat FCM menyambung: sesudah sukses,
   aplikasi memanggil fungsi pengirim dengan `kelas_id` dan `semester`.
3. Kegagalan pengiriman notifikasi tidak boleh membalikkan finalisasi (finalisasi
   sudah selesai sebelum notifikasi dicoba).
4. Rapor final tidak bisa berubah lagi. **Perhatian:** saat ini `detnilai` belum
   terkunci saat rapor final. Itu tanggung jawab bagian finalisasi, tetapi notifikasi
   "rapor final" menjadi menyesatkan bila nilainya masih bisa berubah.

Hal yang perlu disepakati dengan Dimas sebelum bagian C dimulai: nama fungsi atau
RPC finalisasi, di berkas layar mana tombolnya, dan siapa yang menambahkan satu baris
pemanggilan ke fungsi pengirim notifikasi.

Ringkasan rancangan finalisasi yang tadinya saya tulis (hanya sebagai usulan untuk teman
pemilik, tidak mengikat):

- Fungsi database `finalisasi_rapor(p_kelas_id, p_semester)`, `security definer`,
  dipanggil lewat RPC.
- Syarat (semua dicek di server, bukan hanya di layar): pemanggil adalah wali kelas
  kelas itu; semester sama dengan semester aktif; semua siswa kelas itu punya nilai
  untuk **semua mapel yang ditugaskan** di kelas itu; belum ada rapor final di kelas itu
  (atau diabaikan untuk yang sudah final).
- Efek: untuk setiap rapor kelas itu pada semester itu, `status = 'final'`,
  `skm_snapshot` = SKM tahun ajaran aktif, `finalized_at = now()`,
  `finalized_by = auth.uid()`. Satu transaksi: semua atau tidak sama sekali.
- Pelanggaran syarat memakai `raise exception` (kode P0001) dengan pesan Indonesia yang
  sudah dipetakan aplikasi ke `AppException`, mis. "Nilai belum lengkap: 3 siswa belum
  punya nilai semua mapel."
- Trigger pada `detnilai` (insert/update/delete) menolak perubahan bila rapor siswa
  itu pada semester itu sudah final: "Rapor sudah final, nilai tidak bisa diubah."
- Layar: tombol "Finalisasi rapor" di bagian wali kelas pada Beranda guru, dengan dialog
  konfirmasi (lihat sketsa). Tombol nonaktif disertai alasan bila nilai belum lengkap.
  Presensi pada kartu siswa sudah otomatis terkunci saat final (sudah dibuat).

## Bagian B. Layar Rapor

- Tab baru "Rapor" untuk siswa dan wali murid, di samping Beranda dan Profil.
- Menampilkan rapor final per anak dan semester: identitas, nilai per mapel, SKM yang
  tersimpan (`skm_snapshot`), presensi, catatan wali kelas, status Final.
- Wali murid dengan lebih dari satu anak memilih anak (pola pemilih anak yang sudah ada
  di halaman Perkembangan). Rapor belum final: tampil "Rapor belum tersedia", tanpa
  data apa pun.
- Layar bisa dibuka langsung dengan parameter anak (`/wali-murid/rapor?siswa=ID` dan
  `/siswa/rapor`), karena notifikasi membukanya.
- Hanya data asli. Tidak ada nilai atau teks bawaan (lihat pelajaran dari layar
  Perkembangan yang sebelumnya berisi data karangan).

## Bagian C. FCM

**Pendaftaran perangkat**
- Tabel `device_token`: `id`, `user_id` (ke `users`, hapus berantai), `token` (unik),
  `platform`, `updated_at`. RLS: pengguna hanya bisa menambah, mengubah, dan menghapus
  barisnya sendiri; tidak bisa membaca milik orang lain.
- Aplikasi meminta izin notifikasi (Android 13 ke atas) sesudah login dan ganti password
  selesai, mendaftarkan token (`upsert` berdasarkan token), dan memperbarui saat token
  berganti. Saat logout, token perangkat itu dihapus supaya akun berikutnya di HP yang
  sama tidak menerima notifikasi akun lama.
- Izin ditolak: aplikasi tetap berjalan normal tanpa notifikasi.

**Pengiriman**
- Edge Function `kirim-notifikasi-rapor`, `verify_jwt` aktif. Aplikasi memanggilnya
  sesudah RPC finalisasi sukses, dengan `kelas_id` dan `semester`.
- Fungsi memeriksa sendiri: pemanggil adalah wali kelas kelas itu, dan rapor kelas itu
  benar-benar berstatus final. Bila tidak, ditolak.
- Penerima: `user_id` siswa dan wali murid dari semua siswa di kelas itu, lalu semua token
  mereka. Satu pesan per token.
- Isi: judul "Rapor sudah final"; isi "Rapor semester 1 2026/2027 milik <nama anak> sudah
  tersedia. Ketuk untuk melihat." Tanpa nilai. Muatan data: `type=rapor_final`,
  `siswa_id`, `semester`.
- Autentikasi ke FCM HTTP v1: kunci layanan dibaca dari secret Supabase
  `FIREBASE_SERVICE_ACCOUNT` (seluruh JSON), ditukar menjadi token akses di dalam
  fungsi. Kunci tidak pernah ada di aplikasi atau repo.
- Token yang ditolak FCM (`UNREGISTERED` atau `NOT_FOUND`) dihapus dari `device_token`.
- Balasan fungsi berisi jumlah terkirim dan gagal. Aplikasi menampilkan:
  "Rapor final. Notifikasi dikirim ke N perangkat." atau, bila gagal total atau fungsi
  tidak terjangkau, "Rapor final, notifikasi belum terkirim." Finalisasi tetap sah.

**Penerimaan di aplikasi**
- Aplikasi tertutup atau di latar belakang: sistem Android menampilkan notifikasi.
  Mengetuknya membuka aplikasi dan langsung ke layar Rapor anak itu (lewat go_router).
- Aplikasi terbuka: banner kecil di dalam aplikasi dengan tombol "Lihat", tanpa
  mengganggu layar yang sedang dipakai.
- Pengguna belum login saat mengetuk: masuk dulu, lalu diarahkan ke rapor itu.

## Keputusan

Dari pembicaraan dengan pemilik:
- Skema layar seperti sketsa yang sudah disetujui (dialog finalisasi, izin notifikasi,
  notifikasi di layar kunci, layar Rapor).
- Nama anak ikut tampil di notifikasi (sketsa). Ketukan membuka rapor anak itu.
- Berkas Firebase sudah ada; kunci layanan disimpan pemilik sebagai secret sendiri.

Pilihan saya (bisa diubah):
- **Pemicu dari aplikasi, bukan dari database.** Aplikasi memanggil fungsi pengirim
  setelah finalisasi. Lebih sederhana dan tidak butuh ekstensi tambahan. Batasnya: bila
  aplikasi mati tepat antara dua langkah itu, notifikasi tidak terkirim dan rapor tetap
  final. Bila ini mengganggu, ganti ke webhook database pada perubahan `rapor.status`.
- **Foreground memakai banner di dalam aplikasi**, bukan paket notifikasi lokal.
- **Syarat finalisasi** adalah semua mapel yang ditugaskan terisi untuk semua siswa
  (asumsi dari dokumen rancangan, belum dikonfirmasi sekolah).
- **Layar Rapor tanpa PDF** dulu.
- **Yang bisa diserahkan ke pembangun:** nama kunci rute dan tabel, bentuk persis pesan
  galat, tampilan banner foreground, urutan layar di layar Rapor.

## Yang harus disiapkan pemilik

1. Memasukkan isi berkas adminsdk sebagai secret `FIREBASE_SERVICE_ACCOUNT` di Supabase
   (Edge Functions, Secrets). Berkasnya tetap di luar repo.
2. Menyalin `google-services (7).json` menjadi `android/app/google-services.json`
   (boleh masuk repo, itu konfigurasi klien).
3. Bila `applicationId` diganti sebelum rilis, daftarkan ulang aplikasi Android di
   Firebase dan unduh berkas baru.

## Pengujian

- Pengujian otomatis: aturan kelayakan finalisasi (syarat tidak terpenuhi), penolakan
  ubah nilai saat final (dites sebagai SQL yang bisa dijalankan terhadap database uji
  atau, bila tidak ada, dijelaskan sebagai uji manual), pemetaan tautan notifikasi ke
  rute, tampilan layar Rapor untuk rapor final dan belum final.
- Uji di HP, dari ujung ke ujung, dengan akun contoh: wali kelas memfinalisasi kelas
  uji, dan HP kedua (atau HP yang sama setelah ganti akun) menerima notifikasi di tiga
  keadaan: aplikasi terbuka, di latar belakang, dan tertutup.
- Hapus semua data uji sesudahnya.

## Risiko yang diketahui

- Perangkat Xiaomi/MIUI sering menahan notifikasi saat aplikasi ditutup paksa atau
  penghemat baterai agresif. Ini bukan bug kode, tetapi akan terlihat saat uji di HP.
- Kunci layanan sudah pernah terkirim lewat WhatsApp. Disarankan membuat kunci baru
  setelah uji selesai.
- Dokumen rancangan menyebut finalisasi harus menunggu keputusan sekolah tentang SKM
  satu angka atau per mapel. Bila per mapel, `skm_snapshot` harus pindah ke `detnilai`
  dan bagian A berubah.

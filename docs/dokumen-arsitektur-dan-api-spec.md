# Dokumen Teknis Arsitektur & Spesifikasi API (Pertemuan 13)
## E-Raport & Portal Wali Murid MTs Al Fajar Kandat
**Mata Kuliah: Proyek Teknologi Terintegrasi (PTT) - Semester 5**

---

### 1. Arsitektur Sistem Terintegrasi (System Architecture)

Sistem dirancang menggunakan arsitektur *Backend-as-a-Service* (BaaS) berbasis cloud tanpa server mandiri untuk menjamin ketersediaan tinggi, keamanan data per level pengguna, dan biaya operasional yang efisien.

```
+-------------------------------------------------------------------------+
|                       FLUTTER MOBILE CLIENT (ANDROID)                   |
|  +----------------+  +-------------------+  +------------------------+  |
|  | Presentation   |  | State Management  |  | Domain & Repository    |  |
|  | (UI & Widgets) |  | (Riverpod State)  |  | (Data Layer & Offline) |  |
|  +----------------+  +-------------------+  +------------------------+  |
+------------------------------------+------------------------------------+
                                     | HTTPS / WSS / REST
                                     v
+------------------------------------+------------------------------------+
|                         SUPABASE CLOUD PLATFORM                         |
|  +----------------------+ +--------------------+ +-------------------+  |
|  | Supabase Auth        | | Postgres Database  | | Edge Functions    |  |
|  | (JWT Auth per Role)  | | (RLS + Triggers)   | | (Deno / TypeScript|  |
|  +----------------------+ +--------------------+ +-------------------+  |
|  +----------------------+                                               |
|  | Storage Bucket       |                                               |
|  | (Foto & Dokumen)     |                                               |
|  +----------------------+                                               |
+------------------------------------+------------------------------------+
                                     | Google Cloud Service Account
                                     v
+------------------------------------+------------------------------------+
|                     FIREBASE CLOUD MESSAGING (FCM)                      |
|                  Push Notifikasi Rapor Final ke HP Siswa/Wali           |
+-------------------------------------------------------------------------+
```

* **Frontend:** Flutter SDK (Dart) dengan arsitektur Riverpod, GoRouter, dan Material 3 bernuansa hijau madrasah (`#0D5C3A`).
* **Backend Database:** PostgreSQL terkelola Supabase dengan Row Level Security (RLS) aktif pada seluruh tabel.
* **Komputasi Tanpa Server (Serverless):** Supabase Edge Functions (Deno/TypeScript) dengan verifikasi JWT untuk operasi administratif dan pemanggilan FCM HTTP v1.
* **Integrasi Pihak Ketiga (Third-Party):** Firebase Cloud Messaging (FCM) untuk pengiriman notifikasi pengesahan rapor.

---

### 2. Skema Relasi Database (Database Schema)

Database terdiri dari 13 entitas utama yang saling terhubung:

```
[users] 1---1 [guru] 1---N [kelas] (sebagai wali kelas)
   |             |            |
   |             +---N [penugasan_mengajar] N---1 [mapel]
   |                          |
   +---1 [wali_murid] 1---N   +---N [detnilai] (nilai UTS/mapel)
   |                          |
   +---1 [siswa] 1---N [kelas_siswa] 1---N [rapor] (presensi & finalisasi)
   |                          |
   +---N [device_token]       +---N [tahun_ajaran]
```

#### Ringkasan Struktur Tabel Utama:
1. **`users`**: Tabel profil otentikasi (`id` UUID, `role` ['admin','guru','siswa','wali_murid'], `must_change_password` boolean).
2. **`guru`**: Data master dewan guru madrasah (`id`, `user_id`, `nip`, `nama`, `kontak`, `alamat`).
3. **`siswa`**: Data master siswa (`id`, `user_id`, `wali_murid_id`, `nis`, `nisn`, `nama`, `jk`, `tgl_lahir`).
4. **`wali_murid`**: Data orang tua/wali siswa (`id`, `user_id`, `nama`, `kontak`, `pekerjaan`).
5. **`tahun_ajaran`**: Periode akademik (`id`, `tahun`, `semester_aktif`, `skm`, `is_aktif`).
6. **`tingkat` & `kelas`**: Struktur rombel (`tingkat_id` [7,8,9], `wali_kelas_id` FK ke guru).
7. **`mapel`**: Mata pelajaran madrasah (`kode`, `nama`, `kategori` ['Agama','Bahasa','Umum']).
8. **`kelas_siswa`**: Penempatan siswa pada rombel per tahun ajaran.
9. **`penugasan_mengajar`**: Penugasan guru mengampu mapel di kelas tertentu.
10. **`detnilai`**: Data transaksi nilai siswa per mapel dan semester (`nilai`, `diinput_oleh`).
11. **`rapor`**: Lembar status rapor (`sakit`, `izin`, `alpa`, `catatan`, `status` ['draft','menunggu_acc','final'], `skm_snapshot`, `finalized_at`, `finalized_by`).
12. **`device_token`**: Token FCM perangkat mobile untuk pengiriman push notification.

---

### 3. Spesifikasi Stored Procedure (RPC) & Database Trigger

| Nama Fungsi / RPC | Parameter | Hak Akses | Deskripsi & Aturan Bisnis |
|---|---|---|---|
| **`ajukan_acc_rapor`** | `p_kelas_id bigint`, `p_semester text` | Authenticated (Wali Kelas / Admin) | Mengubah status rapor dari `draft` menjadi `menunggu_acc`. |
| **`finalisasi_rapor`** | `p_kelas_id bigint`, `p_semester text` | Authenticated (Admin / Wali Kelas) | Mengesahkan rapor menjadi `final`, merekam snapshot SKM dan waktu finalisasi. |
| **`buka_kunci_rapor`** | `p_kelas_id bigint`, `p_semester text` | Admin Only (`is_admin()`) | Mengembalikan status rapor dari `final` ke `draft` untuk keperluan revisi nilai. |
| **`daftarkan_device_token`** | `p_token text`, `p_platform text` | Authenticated (Milik Sendiri) | Mendaftarkan token push notifikasi perangkat pengguna. |
| **`admin_progres_input_nilai`** | `p_tahun_ajaran_id bigint`, `p_semester text` | Admin Only | Menghitung persentase progres input nilai guru mapel per kelas. |

#### Database Trigger Penguncian Nilai:
* **Trigger:** `trg_kunci_detnilai`
* **Event:** `BEFORE UPDATE OR DELETE ON public.detnilai`
* **Logika Proteksi:** Memeriksa tabel `rapor` yang berelasi dengan baris `detnilai`. Jika `status == 'final'`, transaksi dibatalkan dengan pesan: *"Nilai terkunci: rapor siswa untuk semester ini sudah final/di-ACC."*

---

### 4. Spesifikasi Endpoint Supabase Edge Functions

| Nama Function | Method | Otorisasi | Payload Masukan | Respons Keluaran |
|---|:---:|---|---|---|
| **`admin-create-user`** | `POST` | Bearer JWT (Admin) | `{ role, name, username, password }` | `{ success: true, user_id: UUID }` |
| **`admin-reset-password`** | `POST` | Bearer JWT (Admin) | `{ user_id: UUID }` | `{ success: true, temp_password: "..." }` |
| **`admin-import-siswa`** | `POST` | Bearer JWT (Admin) | `{ batch: [ { nis, nama, jk, tgl_lahir, kelas } ] }` | `{ success: true, inserted: 30, skipped: 0 }` |
| **`kirim-notifikasi-rapor`** | `POST` | Bearer JWT (Wali Kelas/Admin) | `{ kelas_id: number, semester: string }` | `{ success: true, sent_count: number }` |

-- Kategori dan jam mulai pelajaran pada mata pelajaran.
-- Keduanya ditambahkan tanpa mengubah baris yang ada: kategori punya nilai
-- bawaan 'Umum', jam_mulai boleh kosong.

alter table public.mapel
  add column kategori text not null default 'Umum'
    check (kategori in ('Agama', 'Bahasa', 'Umum')),
  add column jam_mulai time;

-- Sesuaikan mapel contoh yang sudah ada.
update public.mapel set kategori = 'Agama' where kode in ('QH', 'FQH');
update public.mapel set kategori = 'Bahasa' where kode in ('BIN', 'BIG');

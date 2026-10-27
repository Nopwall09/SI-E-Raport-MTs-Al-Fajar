-- Bucket Storage privat untuk foto siswa dan bukti fisik rapor.
-- Hanya admin yang boleh membaca dan menulis; aplikasi memakai URL bertanda
-- (signed URL) berumur 1 jam, bukan URL publik.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('foto-siswa', 'foto-siswa', false, 2097152,
   array['image/jpeg', 'image/png', 'image/webp']),
  ('rapor-bukti', 'rapor-bukti', false, 5242880,
   array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy admin_kelola_storage on storage.objects
  for all to authenticated
  using (bucket_id in ('foto-siswa', 'rapor-bukti') and public.is_admin())
  with check (bucket_id in ('foto-siswa', 'rapor-bukti') and public.is_admin());

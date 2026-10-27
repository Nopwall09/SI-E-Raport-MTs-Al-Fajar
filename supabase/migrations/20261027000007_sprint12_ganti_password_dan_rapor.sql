-- UC-02: password awal/sementara wajib diganti saat masuk pertama.
alter table public.users add column must_change_password boolean not null default false;

create or replace function public.get_my_profile() returns json
language sql stable security definer set search_path = '' as $$
  select json_build_object(
    'id', u.id,
    'name', coalesce(g.nama, s.nama, w.nama, u.username),
    'role', u.role,
    'must_change_password', u.must_change_password,
    'wali_kelas', (
      select json_build_object('kelas_id', k.id, 'nama', k.nama)
      from public.kelas k
      join public.tahun_ajaran ta on ta.id = k.tahun_ajaran_id and ta.is_active
      where k.wali_kelas_id = g.id
      limit 1
    )
  )
  from public.users u
  left join public.guru g on g.user_id = u.id
  left join public.siswa s on s.user_id = u.id
  left join public.wali_murid w on w.user_id = u.id
  where u.id = auth.uid() and u.is_active
$$;

-- Dipanggil aplikasi sesudah auth.updateUser(password) berhasil. Pengguna tidak
-- punya policy UPDATE di tabel users, jadi flag hanya bisa dibersihkan lewat sini.
create function public.selesai_ganti_password() returns void
language sql security definer set search_path = '' as $$
  update public.users set must_change_password = false where id = auth.uid()
$$;
revoke execute on function public.selesai_ganti_password() from public, anon;
grant execute on function public.selesai_ganti_password() to authenticated;

-- UC-11: setiap pendaftaran kelas otomatis punya dua rapor (ganjil dan genap).
create function public.buat_rapor_kelas_siswa() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.rapor (kelas_siswa_id, semester)
  values (new.id, 'ganjil'), (new.id, 'genap')
  on conflict do nothing;
  return new;
end $$;

create trigger kelas_siswa_buat_rapor
after insert on public.kelas_siswa
for each row execute function public.buat_rapor_kelas_siswa();

-- Pendaftaran yang sudah ada sebelum trigger.
insert into public.rapor (kelas_siswa_id, semester)
select ks.id, s.semester
from public.kelas_siswa ks
cross join (values ('ganjil'), ('genap')) as s(semester)
on conflict do nothing;

-- data referensi minimal supaya kelas bisa dibuat
insert into public.tingkat (nama) values ('7'), ('8'), ('9');
insert into public.tahun_ajaran (tahun, semester_aktif, skm, is_active)
values ('2026/2027', 'ganjil', 75, true); -- skm contoh, ubah lewat admin

-- progres input nilai per penugasan (tahun ajaran & semester aktif), khusus admin
create function public.admin_progres_input_nilai()
returns table (kelas text, mapel text, nama_guru text, persen int)
language sql stable security definer set search_path = '' as $$
  select k.nama, m.nama, g.nama,
    case when s.n = 0 then 0 else least(100, round(100.0 * d.n / s.n))::int end
  from public.penugasan_mengajar pm
  join public.kelas k on k.id = pm.kelas_id
  join public.tahun_ajaran ta on ta.id = k.tahun_ajaran_id and ta.is_active
  join public.mapel m on m.id = pm.mapel_id
  join public.guru g on g.id = pm.guru_id
  cross join lateral (
    select count(*) n from public.kelas_siswa ks where ks.kelas_id = k.id
  ) s
  cross join lateral (
    select count(*) n from public.detnilai dn
    join public.kelas_siswa ks on ks.id = dn.kelas_siswa_id
    where ks.kelas_id = k.id and dn.mapel_id = pm.mapel_id and dn.semester = ta.semester_aktif
  ) d
  where public.is_admin()
  order by k.nama, m.nama
$$;
revoke execute on function public.admin_progres_input_nilai() from public, anon;
grant execute on function public.admin_progres_input_nilai() to authenticated;

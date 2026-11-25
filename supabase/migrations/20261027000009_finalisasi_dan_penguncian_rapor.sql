-- Epic 8, 14 (UC-18, UC-13): Alur ACC Rapor, Finalisasi, Penguncian Nilai, dan Buka Kunci.

-- 1. Perbarui batasan status rapor agar mendukung alur ACC sekolah: 'draft', 'menunggu_acc', 'final'.
alter table public.rapor drop constraint if exists rapor_status_check;
alter table public.rapor add constraint rapor_status_check
  check (status in ('draft', 'menunggu_acc', 'final'));

-- 2. Wali kelas mengajukan verifikasi/ACC rapor kelas ke Kepala Madrasah / Admin.
create or replace function public.ajukan_acc_rapor(
  p_kelas_id bigint,
  p_semester text
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_caller uuid := auth.uid();
  v_is_wali boolean;
  v_is_admin boolean;
begin
  select exists (
    select 1 from public.kelas k
    join public.guru g on g.id = k.wali_kelas_id
    where k.id = p_kelas_id and g.user_id = v_caller
  ) into v_is_wali;

  select public.is_admin() into v_is_admin;

  if not (v_is_wali or v_is_admin) then
    raise exception 'Hanya wali kelas atau admin yang dapat mengajukan ACC rapor kelas ini';
  end if;

  -- Pastikan semua siswa di kelas ini memiliki entri rapor berstatus 'menunggu_acc'
  insert into public.rapor (kelas_siswa_id, semester, status)
  select ks.id, p_semester, 'menunggu_acc'
  from public.kelas_siswa ks
  where ks.kelas_id = p_kelas_id
  on conflict (kelas_siswa_id, semester) do update
  set status = 'menunggu_acc'
  where public.rapor.status = 'draft';
end $$;

-- 3. Finalisasi / ACC Rapor: Rapor disahkan dan dikunci permanen.
create or replace function public.finalisasi_rapor(
  p_kelas_id bigint,
  p_semester text
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_caller uuid := auth.uid();
  v_is_admin boolean;
  v_is_wali boolean;
  v_finalized_by uuid;
  v_skm int;
begin
  select public.is_admin() into v_is_admin;
  select exists (
    select 1 from public.kelas k
    join public.guru g on g.id = k.wali_kelas_id
    where k.id = p_kelas_id and g.user_id = v_caller
  ) into v_is_wali;

  if not (v_is_admin or v_is_wali) then
    raise exception 'Hanya admin atau wali kelas yang berhak mengesahkan rapor';
  end if;

  -- Ambil nilai SKM tahun ajaran aktif kelas
  select ta.skm into v_skm
  from public.kelas k
  join public.tahun_ajaran ta on ta.id = k.tahun_ajaran_id
  where k.id = p_kelas_id
  limit 1;

  -- Pastikan finalized_by valid di public.users (menghindari error FK jika dipanggil service account)
  select id into v_finalized_by
  from public.users
  where id = v_caller;

  -- Upsert: pastikan semua siswa di kelas ini statusnya jadi 'final'
  insert into public.rapor (
    kelas_siswa_id, semester, status, skm_snapshot, finalized_at, finalized_by
  )
  select 
    ks.id, p_semester, 'final', coalesce(v_skm, 75), now(), v_finalized_by
  from public.kelas_siswa ks
  where ks.kelas_id = p_kelas_id
  on conflict (kelas_siswa_id, semester) do update
  set status = 'final',
      skm_snapshot = coalesce(v_skm, public.rapor.skm_snapshot, 75),
      finalized_at = now(),
      finalized_by = v_finalized_by
  where public.rapor.status in ('draft', 'menunggu_acc');
end $$;

-- 4. Buka Kunci Rapor (UC-13): Khusus Admin jika ada revisi nilai/presensi.
create or replace function public.buka_kunci_rapor(
  p_kelas_id bigint,
  p_semester text
) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Hanya admin yang memiliki wewenang membuka kunci rapor';
  end if;

  update public.rapor r
  set status = 'draft',
      finalized_at = null,
      finalized_by = null
  from public.kelas_siswa ks
  where r.kelas_siswa_id = ks.id
    and ks.kelas_id = p_kelas_id
    and r.semester = p_semester
    and r.status in ('menunggu_acc', 'final');
end $$;

-- 5. Trigger Penguncian Nilai (detnilai) saat rapor kelas berstatus 'final'.
create or replace function public.kunci_detnilai_saat_rapor_final() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_status text;
begin
  select r.status into v_status
  from public.rapor r
  where r.kelas_siswa_id = coalesce(new.kelas_siswa_id, old.kelas_siswa_id)
    and r.semester = coalesce(new.semester, old.semester)
  limit 1;

  if v_status = 'final' then
    raise exception 'Nilai terkunci: rapor siswa untuk semester ini sudah final/di-ACC.';
  end if;

  return coalesce(new, old);
end $$;

drop trigger if exists trg_kunci_detnilai on public.detnilai;
create trigger trg_kunci_detnilai
before insert or update or delete on public.detnilai
for each row execute function public.kunci_detnilai_saat_rapor_final();

revoke execute on function public.ajukan_acc_rapor(bigint, text) from public, anon;
grant execute on function public.ajukan_acc_rapor(bigint, text) to authenticated;

revoke execute on function public.finalisasi_rapor(bigint, text) from public, anon;
grant execute on function public.finalisasi_rapor(bigint, text) to authenticated;

revoke execute on function public.buka_kunci_rapor(bigint, text) from public, anon;
grant execute on function public.buka_kunci_rapor(bigint, text) to authenticated;

-- 6. Kebijakan akses baca data guru: agar siswa dan wali murid dapat membaca nama wali kelas di kartu rapor.
drop policy if exists baca_guru_publik on public.guru;
create policy baca_guru_publik on public.guru for select to authenticated using (true);


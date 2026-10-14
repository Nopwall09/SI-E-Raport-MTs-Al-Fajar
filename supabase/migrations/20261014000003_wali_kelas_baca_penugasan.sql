-- Wali kelas perlu melihat seluruh penugasan mengajar di kelasnya
-- (untuk menghitung progres nilai per siswa), bukan hanya miliknya sendiri.
drop policy baca_penugasan on public.penugasan_mengajar;
create policy baca_penugasan on public.penugasan_mengajar for select to authenticated
  using (
    guru_id = public.my_guru_id()
    or exists (
      select 1 from public.kelas k
      where k.id = kelas_id and k.wali_kelas_id = public.my_guru_id()
    )
  );

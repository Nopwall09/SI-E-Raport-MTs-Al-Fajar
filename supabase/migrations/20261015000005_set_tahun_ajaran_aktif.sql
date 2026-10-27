-- Mengganti tahun ajaran aktif secara atomik. Ada indeks unik parsial yang
-- hanya mengizinkan satu baris is_active, jadi menukar dari aplikasi dengan dua
-- update terpisah bisa meninggalkan nol tahun ajaran aktif bila yang kedua gagal.

create function public.set_tahun_ajaran_aktif(p_id bigint) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Hanya admin yang boleh mengganti tahun ajaran aktif'
      using errcode = '42501';
  end if;
  if not exists (select 1 from public.tahun_ajaran where id = p_id) then
    raise exception 'Tahun ajaran tidak ditemukan';
  end if;
  update public.tahun_ajaran set is_active = false where is_active and id <> p_id;
  update public.tahun_ajaran set is_active = true where id = p_id;
end $$;

revoke execute on function public.set_tahun_ajaran_aktif(bigint) from public, anon;
grant execute on function public.set_tahun_ajaran_aktif(bigint) to authenticated;

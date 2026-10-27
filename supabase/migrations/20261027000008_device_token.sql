-- UC-04, UC-20: token perangkat untuk notifikasi rapor final (FCM).
create table public.device_token (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  token text not null unique check (length(token) between 20 and 4096),
  platform text not null default 'android',
  updated_at timestamptz not null default now()
);
create index on public.device_token (user_id);

alter table public.device_token enable row level security;

-- Pengguna hanya melihat dan menghapus token miliknya. Tidak ada policy
-- INSERT/UPDATE: pendaftaran lewat fungsi di bawah, supaya token yang pindah
-- akun (HP yang sama, akun lain) bisa diambil alih tanpa bentrok.
create policy device_token_baca_sendiri on public.device_token
  for select to authenticated using (user_id = auth.uid());
create policy device_token_hapus_sendiri on public.device_token
  for delete to authenticated using (user_id = auth.uid());

create function public.daftarkan_device_token(p_token text) returns void
language sql security definer set search_path = '' as $$
  insert into public.device_token (user_id, token)
  values (auth.uid(), p_token)
  on conflict (token) do update set user_id = auth.uid(), updated_at = now()
$$;
revoke execute on function public.daftarkan_device_token(text) from public, anon;
grant execute on function public.daftarkan_device_token(text) to authenticated;

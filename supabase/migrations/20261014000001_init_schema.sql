-- ============ TABEL ============
-- users = profil aplikasi; password disimpan Supabase Auth (auth.users), bukan di sini.
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  email text,
  role text not null check (role in ('admin','guru','siswa','wali_murid')),
  is_active boolean not null default true
);

create table public.guru (
  id bigint generated always as identity primary key,
  user_id uuid not null unique references public.users(id) on delete cascade,
  nip text unique,
  nama text not null,
  no_hp text
);

create table public.wali_murid (
  id bigint generated always as identity primary key,
  user_id uuid not null unique references public.users(id) on delete cascade,
  nama text not null,
  no_hp text
);

create table public.siswa (
  id bigint generated always as identity primary key,
  user_id uuid unique references public.users(id) on delete set null,
  wali_murid_id bigint references public.wali_murid(id) on delete set null,
  nis text not null unique,
  nisn text unique,
  nama text not null,
  jk text not null check (jk in ('L','P')),
  tgl_lahir date not null
);

create table public.tahun_ajaran (
  id bigint generated always as identity primary key,
  tahun text not null unique,
  semester_aktif text not null check (semester_aktif in ('ganjil','genap')),
  skm int not null check (skm between 0 and 100), -- satu angka untuk semua mapel
  is_active boolean not null default false
);
create unique index tahun_ajaran_satu_aktif on public.tahun_ajaran (is_active) where is_active;

create table public.tingkat (
  id bigint generated always as identity primary key,
  nama text not null unique check (nama in ('7','8','9'))
);

create table public.kelas (
  id bigint generated always as identity primary key,
  tahun_ajaran_id bigint not null references public.tahun_ajaran(id),
  tingkat_id bigint not null references public.tingkat(id),
  nama text not null,
  wali_kelas_id bigint references public.guru(id) on delete set null,
  unique (tahun_ajaran_id, nama)
);

create table public.mapel (
  id bigint generated always as identity primary key,
  kode text not null unique,
  nama text not null
);

create table public.kelas_siswa (
  id bigint generated always as identity primary key,
  kelas_id bigint not null references public.kelas(id) on delete cascade,
  siswa_id bigint not null references public.siswa(id) on delete cascade,
  tahun_ajaran_id bigint not null references public.tahun_ajaran(id),
  unique (siswa_id, tahun_ajaran_id)
);

create table public.penugasan_mengajar (
  id bigint generated always as identity primary key,
  guru_id bigint not null references public.guru(id) on delete cascade,
  mapel_id bigint not null references public.mapel(id),
  kelas_id bigint not null references public.kelas(id) on delete cascade,
  unique (kelas_id, mapel_id)
);

create table public.detnilai (
  id bigint generated always as identity primary key,
  kelas_siswa_id bigint not null references public.kelas_siswa(id) on delete cascade,
  mapel_id bigint not null references public.mapel(id),
  semester text not null check (semester in ('ganjil','genap')),
  nilai numeric(5,2) not null check (nilai between 0 and 100), -- UTS
  diinput_oleh uuid not null default auth.uid() references public.users(id),
  unique (kelas_siswa_id, mapel_id, semester)
);

create table public.rapor (
  id bigint generated always as identity primary key,
  kelas_siswa_id bigint not null references public.kelas_siswa(id) on delete cascade,
  semester text not null check (semester in ('ganjil','genap')),
  sakit int not null default 0 check (sakit >= 0),
  izin int not null default 0 check (izin >= 0),
  alpa int not null default 0 check (alpa >= 0),
  catatan text,
  status text not null default 'draft' check (status in ('draft','final')),
  skm_snapshot int, -- diisi saat final
  finalized_at timestamptz,
  finalized_by uuid references public.users(id),
  pdf_path text,
  unique (kelas_siswa_id, semester)
);

-- index untuk FK yang tidak tercover unique
create index on public.siswa (wali_murid_id);
create index on public.kelas (tingkat_id);
create index on public.kelas (wali_kelas_id);
create index on public.kelas_siswa (kelas_id);
create index on public.kelas_siswa (tahun_ajaran_id);
create index on public.penugasan_mengajar (guru_id);
create index on public.penugasan_mengajar (mapel_id);
create index on public.detnilai (mapel_id);
create index on public.detnilai (diinput_oleh);
create index on public.rapor (finalized_by);

-- ============ HELPER (security definer: hindari rekursi RLS) ============
create function public.app_role() returns text
language sql stable security definer set search_path = '' as $$
  select role from public.users where id = auth.uid() and is_active
$$;

create function public.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce(public.app_role() = 'admin', false)
$$;

create function public.my_guru_id() returns bigint
language sql stable security definer set search_path = '' as $$
  select id from public.guru where user_id = auth.uid()
$$;

-- kelas_siswa milik siswa yang login, atau anak dari wali murid yang login
create function public.is_my_kelas_siswa(ks_id bigint) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.kelas_siswa ks
    join public.siswa s on s.id = ks.siswa_id
    left join public.wali_murid w on w.id = s.wali_murid_id
    where ks.id = ks_id and (s.user_id = auth.uid() or w.user_id = auth.uid())
  )
$$;

create function public.guru_teaches(ks_id bigint, p_mapel_id bigint) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.kelas_siswa ks
    join public.penugasan_mengajar pm on pm.kelas_id = ks.kelas_id
    where ks.id = ks_id and pm.mapel_id = p_mapel_id and pm.guru_id = public.my_guru_id()
  )
$$;

create function public.guru_is_wali_of(ks_id bigint) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.kelas_siswa ks
    join public.kelas k on k.id = ks.kelas_id
    where ks.id = ks_id and k.wali_kelas_id = public.my_guru_id()
  )
$$;

-- Kontrak dengan Flutter (SupabaseAuthRepository._loadProfile)
create function public.get_my_profile() returns json
language sql stable security definer set search_path = '' as $$
  select json_build_object(
    'id', u.id,
    'name', coalesce(g.nama, s.nama, w.nama, u.username),
    'role', u.role,
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

revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated;

-- ============ RLS ============
alter table public.users enable row level security;
alter table public.guru enable row level security;
alter table public.wali_murid enable row level security;
alter table public.siswa enable row level security;
alter table public.tahun_ajaran enable row level security;
alter table public.tingkat enable row level security;
alter table public.kelas enable row level security;
alter table public.mapel enable row level security;
alter table public.kelas_siswa enable row level security;
alter table public.penugasan_mengajar enable row level security;
alter table public.detnilai enable row level security;
alter table public.rapor enable row level security;

-- admin: akses penuh ke semua tabel
do $$ declare t text; begin
  foreach t in array array['users','guru','wali_murid','siswa','tahun_ajaran','tingkat','kelas','mapel','kelas_siswa','penugasan_mengajar','detnilai','rapor'] loop
    execute format('create policy admin_all on public.%I for all to authenticated using (public.is_admin()) with check (public.is_admin())', t);
  end loop;
end $$;

-- tabel referensi: semua pengguna login boleh baca
create policy baca_referensi on public.tahun_ajaran for select to authenticated using (true);
create policy baca_referensi on public.tingkat for select to authenticated using (true);
create policy baca_referensi on public.mapel for select to authenticated using (true);
create policy baca_referensi on public.kelas for select to authenticated using (true);

-- profil sendiri
create policy baca_sendiri on public.users for select to authenticated using (id = auth.uid());
create policy baca_sendiri on public.guru for select to authenticated using (user_id = auth.uid());
create policy baca_sendiri on public.wali_murid for select to authenticated using (user_id = auth.uid());

-- siswa: diri sendiri, anak (wali murid), atau guru
create policy baca_siswa on public.siswa for select to authenticated using (
  user_id = auth.uid()
  or wali_murid_id in (select id from public.wali_murid where user_id = auth.uid())
  or public.app_role() = 'guru'
);

create policy baca_kelas_siswa on public.kelas_siswa for select to authenticated using (
  public.is_my_kelas_siswa(id) or public.app_role() = 'guru'
);

create policy baca_penugasan on public.penugasan_mengajar for select to authenticated
  using (guru_id = public.my_guru_id());

-- nilai: guru hanya mapel+kelas yang diampu; siswa/wali hanya miliknya
create policy baca_nilai on public.detnilai for select to authenticated using (
  public.is_my_kelas_siswa(kelas_siswa_id)
  or public.guru_teaches(kelas_siswa_id, mapel_id)
  or public.guru_is_wali_of(kelas_siswa_id)
);
create policy guru_isi_nilai on public.detnilai for insert to authenticated
  with check (public.guru_teaches(kelas_siswa_id, mapel_id) and diinput_oleh = auth.uid());
create policy guru_ubah_nilai on public.detnilai for update to authenticated
  using (public.guru_teaches(kelas_siswa_id, mapel_id))
  with check (public.guru_teaches(kelas_siswa_id, mapel_id));

-- rapor: wali kelas kelola draft; siswa/wali hanya lihat yang final
create policy baca_rapor on public.rapor for select to authenticated using (
  public.guru_is_wali_of(kelas_siswa_id)
  or (status = 'final' and public.is_my_kelas_siswa(kelas_siswa_id))
);
create policy wali_kelas_isi_rapor on public.rapor for insert to authenticated
  with check (public.guru_is_wali_of(kelas_siswa_id) and status = 'draft');
create policy wali_kelas_ubah_rapor on public.rapor for update to authenticated
  using (public.guru_is_wali_of(kelas_siswa_id) and status = 'draft')
  with check (public.guru_is_wali_of(kelas_siswa_id));

-- DATA CONTOH UNTUK PENGEMBANGAN. Semua akun berpassword 123456.
-- JANGAN dijalankan di database produksi.
-- Jalankan setelah semua migration (butuh tingkat dan tahun ajaran aktif).

-- ===== AKUN =====
create temp table seed_u as
select gen_random_uuid() id, u username, r role from (values
  ('admin','admin'),
  ('guru1','guru'),('guru2','guru'),('guru3','guru'),('guru4','guru'),('guru5','guru'),
  ('wali1','wali_murid'),('wali2','wali_murid'),('wali3','wali_murid'),
  ('wali4','wali_murid'),('wali5','wali_murid'),('wali6','wali_murid'),
  ('siswa1','siswa'),('siswa2','siswa'),('siswa3','siswa')
) v(u, r);

insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change, email_change_token_new)
select '00000000-0000-0000-0000-000000000000', id, 'authenticated', 'authenticated',
  username || '@eraport.example.com', crypt('123456', gen_salt('bf')), now(),
  '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''
from seed_u;

insert into auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
select gen_random_uuid(), id, id::text, 'email',
  jsonb_build_object('sub', id::text, 'email', username || '@eraport.example.com', 'email_verified', true),
  now(), now(), now()
from seed_u;

insert into public.users (id, username, email, role)
select id, username, username || '@eraport.example.com', role from seed_u;

-- ===== GURU =====
insert into public.guru (user_id, nip, nama, no_hp)
select s.id, g.nip, g.nama, g.hp from seed_u s join (values
  ('guru1','198501012010011001','Ust. Ahmad Fauzi, S.Pd.I','081234567801'),
  ('guru2','198703152011012002','Ibu Nur Azizah, S.Pd','081234567802'),
  ('guru3','198208202009011003','Ust. Zulkifli, S.Pd.I','081234567803'),
  ('guru4','199001102015022004','Ibu Siti Aminah, S.Pd','081234567804'),
  ('guru5','198905052014011005','Ust. Hamdan, S.Pd','081234567805')
) g(u, nip, nama, hp) on g.u = s.username;

-- ===== WALI MURID =====
insert into public.wali_murid (user_id, nama, no_hp)
select s.id, w.nama, w.hp from seed_u s join (values
  ('wali1','H. Bambang Setiawan','081300000001'),
  ('wali2','Hj. Siti Mariam','081300000002'),
  ('wali3','Rahmat Hidayat','081300000003'),
  ('wali4','Ir. Hendra Wijaya','081300000004'),
  ('wali5','Subhan Santoso','081300000005'),
  ('wali6','Drs. H. Mulyadi','081300000006')
) w(u, nama, hp) on w.u = s.username;

-- ===== MAPEL =====
insert into public.mapel (kode, nama) values
  ('MTK','Matematika'), ('BIN','Bahasa Indonesia'), ('IPA','Ilmu Pengetahuan Alam'),
  ('QH','Al-Qur''an Hadits'), ('FQH','Fiqih'), ('BIG','Bahasa Inggris');

-- ===== KELAS (tahun ajaran aktif) =====
insert into public.kelas (tahun_ajaran_id, tingkat_id, nama, wali_kelas_id)
select ta.id, t.id, k.nama, g.id
from public.tahun_ajaran ta
join (values ('VII-A','7','guru1'),('VII-B','7','guru2'),('VIII-A','8','guru3'),('IX-A','9','guru4')) k(nama, tk, gu) on true
join public.tingkat t on t.nama = k.tk
join public.users u on u.username = k.gu
join public.guru g on g.user_id = u.id
where ta.is_active;

-- ===== SISWA (12) =====
insert into public.siswa (nis, nisn, nama, jk, tgl_lahir, wali_murid_id, user_id)
select s.nis, s.nisn, s.nama, s.jk, s.tgl::date,
  (select wm.id from public.wali_murid wm join public.users u on u.id = wm.user_id where u.username = s.wali),
  (select u.id from public.users u where u.username = s.akun)
from (values
  ('2026001','0089765432','Muhammad Farhan Al-Ghifari','L','2013-02-11','wali1','siswa1'),
  ('2026002','0081234567','Aisyah Putri Azzahra','P','2013-06-21','wali2','siswa2'),
  ('2026003','0087654321','Ahmad Bilal Al-Kautsar','L','2013-09-03','wali3',null),
  ('2026004','0078901234','Fatimah Zahra Maulida','P','2012-04-17','wali4','siswa3'),
  ('2026005','0076543210','Rizky Ramadhan','L','2012-08-30','wali5',null),
  ('2026006','0065432198','Zaskia Nurul Izzati','P','2011-12-05','wali6',null),
  ('2026007','0069876543','Zidan Al-Mubarak','L','2011-01-25','wali1',null),
  ('2026008','0071122334','Nabila Khairunnisa','P','2013-03-14','wali2',null),
  ('2026009','0072233445','Fikri Maulana','L','2013-07-19','wali3',null),
  ('2026010','0073344556','Salsabila Putri','P','2012-10-08','wali4',null),
  ('2026011','0074455667','Dimas Pratama','L','2012-05-27','wali5',null),
  ('2026012','0075566778','Hafizah Nur Aini','P','2011-09-16','wali6',null)
) s(nis, nisn, nama, jk, tgl, wali, akun);

-- ===== KELAS_SISWA: 3 siswa per kelas =====
insert into public.kelas_siswa (kelas_id, siswa_id, tahun_ajaran_id)
select k.id, s.id, k.tahun_ajaran_id
from public.siswa s
join (values ('2026001','VII-A'),('2026002','VII-A'),('2026008','VII-A'),
             ('2026003','VII-B'),('2026009','VII-B'),('2026005','VII-B'),
             ('2026004','VIII-A'),('2026010','VIII-A'),('2026011','VIII-A'),
             ('2026006','IX-A'),('2026007','IX-A'),('2026012','IX-A')) m(nis, kelas) on m.nis = s.nis
join public.kelas k on k.nama = m.kelas;

-- ===== PENUGASAN MENGAJAR: tiap kelas diajar 6 mapel =====
insert into public.penugasan_mengajar (guru_id, mapel_id, kelas_id)
select g.id, mp.id, k.id
from public.kelas k
join (values ('MTK','guru2'),('BIN','guru4'),('IPA','guru5'),('QH','guru3'),('FQH','guru3'),('BIG','guru1')) a(kode, gu) on true
join public.mapel mp on mp.kode = a.kode
join public.users u on u.username = a.gu
join public.guru g on g.user_id = u.id;

-- ===== NILAI UTS (sebagian, agar progres input bervariasi) =====
insert into public.detnilai (kelas_siswa_id, mapel_id, semester, nilai, diinput_oleh)
select ks.id, pm.mapel_id, 'ganjil', 65 + ((ks.id * 7 + pm.mapel_id * 11) % 31), g.user_id
from public.kelas_siswa ks
join public.penugasan_mengajar pm on pm.kelas_id = ks.kelas_id
join public.guru g on g.id = pm.guru_id
join public.mapel mp on mp.id = pm.mapel_id
where mp.kode in ('MTK','QH')
   or (mp.kode = 'BIN' and ks.id % 2 = 0)
   or (mp.kode = 'FQH' and ks.id % 3 = 0);

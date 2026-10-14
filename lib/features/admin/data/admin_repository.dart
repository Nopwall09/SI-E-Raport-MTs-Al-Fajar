import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/dashboard_model.dart';
import '../../../models/guru_model.dart';
import '../../../models/kelas_model.dart';
import '../../../models/siswa_model.dart';
import '../../../models/user_model.dart';

class TahunAjaranAktif {
  const TahunAjaranAktif(this.id, this.tahun, this.semester);

  final int id;
  final String tahun;
  final String semester; // ganjil | genap

  String get label => 'Semester ${semester == 'ganjil' ? 1 : 2} $tahun';
}

/// Pasangan id/label untuk dropdown (kelas, guru, wali murid).
class Opsi {
  const Opsi(this.id, this.label);

  final int id;
  final String label;
}

const _romawi = {'7': 'VII', '8': 'VIII', '9': 'IX'};

/// Satu-satunya tempat layar admin menyentuh Supabase.
class AdminRepository {
  AdminRepository(this._db);

  final SupabaseClient _db;

  Future<TahunAjaranAktif> tahunAjaranAktif() async {
    final row = await _db
        .from('tahun_ajaran')
        .select('id,tahun,semester_aktif')
        .eq('is_active', true)
        .maybeSingle();
    if (row == null) throw const FormatException('Tahun ajaran aktif kosong');
    return TahunAjaranAktif(row['id'] as int, row['tahun'] as String,
        row['semester_aktif'] as String);
  }

  Future<DashboardStatistik> statistik() async {
    Future<int> hitung(String tabel) async =>
        (await _db.from(tabel).select('id').count(CountOption.exact)).count;
    final ta = await tahunAjaranAktif();
    final hasil = await Future.wait([
      hitung('siswa'),
      hitung('guru'),
      _db
          .from('kelas')
          .select('id')
          .eq('tahun_ajaran_id', ta.id)
          .count(CountOption.exact)
          .then((r) => r.count),
      hitung('wali_murid'),
    ]);
    return DashboardStatistik(
      totalSiswa: hasil[0],
      totalGuru: hasil[1],
      totalKelas: hasil[2],
      totalOrangTua: hasil[3],
    );
  }

  Future<List<ProgressInputNilai>> progresInputNilai() async {
    final rows = await _db.rpc('admin_progres_input_nilai') as List;
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        ProgressInputNilai(
          kelas: r['kelas'] as String,
          mapel: r['mapel'] as String,
          namaGuru: r['nama_guru'] as String,
          persen: r['persen'] as int,
        ),
    ];
  }

  Future<List<SiswaModel>> daftarSiswa() async {
    final ta = await tahunAjaranAktif();
    final rows = await _db
        .from('siswa')
        .select('id,nama,nis,nisn,jk,wali_murid(nama),'
            'kelas_siswa(tahun_ajaran_id,kelas(nama))')
        .order('nama');
    return [
      for (final r in rows)
        SiswaModel(
          id: '${r['id']}',
          nama: r['nama'] as String,
          nisn: (r['nisn'] ?? r['nis']) as String,
          kelas: _kelasSiswaAktif(r['kelas_siswa'], ta.id) ?? '-',
          jenisKelamin: r['jk'] as String,
          namaWali: _nama(r['wali_murid']) ?? '',
        ),
    ];
  }

  Future<List<GuruModel>> daftarGuru() async {
    final ta = await tahunAjaranAktif();
    final rows = await _db
        .from('guru')
        .select('id,nama,nip,no_hp,users(email),'
            'penugasan_mengajar(mapel(nama)),'
            'kelas!wali_kelas_id(nama,tahun_ajaran_id)')
        .order('nama');
    return [
      for (final r in rows)
        GuruModel(
          id: '${r['id']}',
          nama: r['nama'] as String,
          nip: (r['nip'] as String?) ?? '-',
          mapel: _mapel(r['penugasan_mengajar']),
          waliKelas: _waliKelasAktif(r['kelas'], ta.id),
          email: (r['users']?['email'] as String?) ?? '',
          telepon: (r['no_hp'] as String?) ?? '',
        ),
    ];
  }

  Future<List<KelasModel>> daftarKelas() async {
    final ta = await tahunAjaranAktif();
    final rows = await _db
        .from('kelas')
        .select(
            'id,nama,tingkat(nama),guru!wali_kelas_id(nama),kelas_siswa(count)')
        .eq('tahun_ajaran_id', ta.id)
        .order('nama');
    return [
      for (final r in rows)
        KelasModel(
          id: '${r['id']}',
          namaKelas: r['nama'] as String,
          tingkat: _romawi[r['tingkat']['nama']] ?? '${r['tingkat']['nama']}',
          namaWali: _nama(r['guru']) ?? '-',
          jumlahSiswa: (r['kelas_siswa'] as List).first['count'] as int,
        ),
    ];
  }

  Future<List<UserModel>> daftarPengguna() async {
    final rows = await _db
        .from('users')
        .select(
            'id,username,role,guru(nama),siswa(nama),wali_murid(nama)')
        .order('username');
    return [
      for (final r in rows)
        UserModel(
          id: r['id'] as String,
          nama: _nama(r['guru']) ??
              _nama(r['siswa']) ??
              _nama(r['wali_murid']) ??
              r['username'] as String,
          email: r['username'] as String, // yang dipakai untuk login
          role: UserRole.fromApi(r['role'] as String),
        ),
    ];
  }

  Future<List<Opsi>> opsiKelas() async {
    final ta = await tahunAjaranAktif();
    final rows = await _db
        .from('kelas')
        .select('id,nama')
        .eq('tahun_ajaran_id', ta.id)
        .order('nama');
    return [for (final r in rows) Opsi(r['id'] as int, r['nama'] as String)];
  }

  Future<List<Opsi>> opsiGuru() => _opsiNama('guru');

  Future<List<Opsi>> opsiWaliMurid() => _opsiNama('wali_murid');

  Future<List<Opsi>> _opsiNama(String tabel) async {
    final rows = await _db.from(tabel).select('id,nama').order('nama');
    return [for (final r in rows) Opsi(r['id'] as int, r['nama'] as String)];
  }

  Future<void> tambahKelas({
    required String tingkat, // VII | VIII | IX
    required String nama,
    int? waliKelasId,
  }) async {
    final ta = await tahunAjaranAktif();
    final angka = _romawi.entries.firstWhere((e) => e.value == tingkat).key;
    final tk =
        await _db.from('tingkat').select('id').eq('nama', angka).single();
    await _db.from('kelas').insert({
      'tahun_ajaran_id': ta.id,
      'tingkat_id': tk['id'],
      'nama': nama,
      'wali_kelas_id': waliKelasId,
    });
  }

  Future<void> tambahSiswa({
    required String nama,
    required String nis,
    String? nisn,
    required String jk,
    required DateTime tglLahir,
    required int kelasId,
    int? waliMuridId,
  }) async {
    final ta = await tahunAjaranAktif();
    final siswa = await _db
        .from('siswa')
        .insert({
          'nama': nama,
          'nis': nis,
          'nisn': nisn,
          'jk': jk,
          'tgl_lahir': tglLahir.toIso8601String().substring(0, 10),
          'wali_murid_id': waliMuridId,
        })
        .select('id')
        .single();
    try {
      await _db.from('kelas_siswa').insert({
        'kelas_id': kelasId,
        'siswa_id': siswa['id'],
        'tahun_ajaran_id': ta.id,
      });
    } catch (_) {
      // Jangan tinggalkan siswa tanpa kelas.
      await _db.from('siswa').delete().eq('id', siswa['id']);
      rethrow;
    }
  }

  /// Lewat Edge Function karena membuat akun butuh service role.
  Future<void> buatAkun({
    required String username,
    required String password,
    required UserRole role,
    String? nama,
    String? nip,
    String? noHp,
  }) async {
    await _db.functions.invoke('admin-create-user', body: {
      'username': username,
      'password': password,
      'role': role.apiValue,
      'nama': nama,
      'nip': nip,
      'no_hp': noHp,
    });
  }

  // Relasi to-one dikembalikan PostgREST sebagai objek, to-many sebagai list.
  static String? _nama(dynamic v) {
    if (v is Map) return v['nama'] as String?;
    if (v is List && v.isNotEmpty) return (v.first as Map)['nama'] as String?;
    return null;
  }

  static String? _kelasSiswaAktif(dynamic v, int taId) {
    for (final r in (v as List).cast<Map<String, dynamic>>()) {
      if (r['tahun_ajaran_id'] == taId) return r['kelas']['nama'] as String;
    }
    return null;
  }

  static String? _waliKelasAktif(dynamic v, int taId) {
    for (final r in (v as List).cast<Map<String, dynamic>>()) {
      if (r['tahun_ajaran_id'] == taId) return r['nama'] as String;
    }
    return null;
  }

  static String _mapel(dynamic v) {
    final nama = {
      for (final r in (v as List).cast<Map<String, dynamic>>())
        r['mapel']['nama'] as String
    };
    return nama.isEmpty ? '-' : nama.join(', ');
  }
}

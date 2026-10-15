import 'dart:math' as math;
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';
import '../../../models/dashboard_model.dart';
import '../../../models/data_rapor_model.dart';
import '../../../models/guru_model.dart';
import '../../../models/kelas_model.dart';
import '../../../models/mapel_model.dart';
import '../../../models/siswa_model.dart';
import '../../../models/tahun_ajaran_model.dart';
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
    return TahunAjaranAktif(
      row['id'] as int,
      row['tahun'] as String,
      row['semester_aktif'] as String,
    );
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
        .select(
          'id,nama,nis,nisn,jk,tgl_lahir,wali_murid_id,wali_murid(nama),'
          'kelas_siswa(tahun_ajaran_id,kelas_id,kelas(nama))',
        )
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
          nis: r['nis'] as String,
          nisnAsli: r['nisn'] as String?,
          tglLahir: DateTime.parse(r['tgl_lahir'] as String),
          kelasId: _kelasIdAktif(r['kelas_siswa'], ta.id),
          waliMuridId: r['wali_murid_id'] as int?,
        ),
    ];
  }

  Future<List<GuruModel>> daftarGuru() async {
    final ta = await tahunAjaranAktif();
    final rows = await _db
        .from('guru')
        .select(
          'id,nama,nip,no_hp,users(email),'
          'penugasan_mengajar(mapel(nama)),'
          'kelas!wali_kelas_id(nama,tahun_ajaran_id)',
        )
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
          'id,nama,wali_kelas_id,tingkat(nama),guru!wali_kelas_id(nama),'
          'kelas_siswa(count)',
        )
        .eq('tahun_ajaran_id', ta.id)
        .order('tingkat_id')
        .order('nama');
    return [
      for (final r in rows)
        KelasModel(
          id: '${r['id']}',
          namaKelas: r['nama'] as String,
          tingkat: _romawi[r['tingkat']['nama']] ?? '${r['tingkat']['nama']}',
          namaWali: _nama(r['guru']) ?? '-',
          jumlahSiswa: (r['kelas_siswa'] as List).first['count'] as int,
          waliKelasId: r['wali_kelas_id'] as int?,
        ),
    ];
  }

  Future<List<UserModel>> daftarPengguna() async {
    final rows = await _db
        .from('users')
        .select(
          'id,username,role,is_active,guru(nama),siswa(nama),wali_murid(nama)',
        )
        .order('username');
    return [
      for (final r in rows)
        UserModel(
          id: r['id'] as String,
          nama:
              _nama(r['guru']) ??
              _nama(r['siswa']) ??
              _nama(r['wali_murid']) ??
              r['username'] as String,
          email: r['username'] as String, // yang dipakai untuk login
          role: UserRole.fromApi(r['role'] as String),
          aktif: r['is_active'] as bool,
        ),
    ];
  }

  Future<List<Opsi>> opsiKelas() async {
    final ta = await tahunAjaranAktif();
    final rows = await _db
        .from('kelas')
        .select('id,nama')
        .eq('tahun_ajaran_id', ta.id)
        .order('tingkat_id')
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
    await _db.from('kelas').insert({
      'tahun_ajaran_id': ta.id,
      'tingkat_id': await _tingkatId(tingkat),
      'nama': nama,
      'wali_kelas_id': waliKelasId,
    });
  }

  Future<int> _tingkatId(String romawi) async {
    final angka = _romawi.entries.firstWhere((e) => e.value == romawi).key;
    final tk = await _db
        .from('tingkat')
        .select('id')
        .eq('nama', angka)
        .single();
    return tk['id'] as int;
  }

  Future<void> ubahKelas({
    required int id,
    required String tingkat,
    required String nama,
    int? waliKelasId,
  }) async {
    await _db
        .from('kelas')
        .update({
          'tingkat_id': await _tingkatId(tingkat),
          'nama': nama,
          'wali_kelas_id': waliKelasId,
        })
        .eq('id', id);
  }

  /// Menghapus kelas ikut menghapus daftar siswa dan nilainya (cascade),
  /// jadi hanya kelas kosong yang boleh dihapus.
  Future<void> hapusKelas(int id) async {
    final isi = await _db
        .from('kelas_siswa')
        .select('id')
        .eq('kelas_id', id)
        .count(CountOption.exact);
    if (isi.count > 0) {
      throw AppException(
        AppErrorType.conflict,
        'Kelas masih berisi ${isi.count} siswa. Pindahkan siswanya dulu.',
      );
    }
    await _db.from('kelas').delete().eq('id', id);
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

  Future<void> ubahSiswa({
    required int id,
    required String nama,
    required String nis,
    String? nisn,
    required String jk,
    required DateTime tglLahir,
    required int kelasId,
    int? waliMuridId,
  }) async {
    final ta = await tahunAjaranAktif();
    await _db
        .from('siswa')
        .update({
          'nama': nama,
          'nis': nis,
          'nisn': nisn,
          'jk': jk,
          'tgl_lahir': tglLahir.toIso8601String().substring(0, 10),
          'wali_murid_id': waliMuridId,
        })
        .eq('id', id);
    // Pindah kelas: satu baris per siswa per tahun ajaran (unique).
    await _db.from('kelas_siswa').upsert({
      'siswa_id': id,
      'tahun_ajaran_id': ta.id,
      'kelas_id': kelasId,
    }, onConflict: 'siswa_id,tahun_ajaran_id');
  }

  /// Nilai dan rapor siswa ikut terhapus (cascade). Layar wajib konfirmasi.
  Future<void> hapusSiswa(int id) => _db.from('siswa').delete().eq('id', id);

  Future<void> ubahGuru({
    required int id,
    required String nama,
    String? nip,
    String? noHp,
  }) async {
    await _db
        .from('guru')
        .update({'nama': nama, 'nip': nip, 'no_hp': noHp})
        .eq('id', id);
  }

  /// Akun tidak dihapus (menghapus akun Auth butuh service role). Akun
  /// nonaktif tidak bisa masuk karena get_my_profile() mensyaratkan is_active.
  Future<void> setPenggunaAktif(String userId, bool aktif) =>
      _db.from('users').update({'is_active': aktif}).eq('id', userId);

  /// Kesiapan rapor: jumlah mapel yang sudah ada nilainya per siswa di satu
  /// kelas pada semester [semester] ('ganjil' atau 'genap').
  Future<List<DataRaporModel>> daftarRapor({
    required int kelasId,
    required String kelasNama,
    required String semester,
  }) async {
    final ta = await tahunAjaranAktif();
    final anggota = await _db
        .from('kelas_siswa')
        .select('id,siswa(id,nama,nis,nisn)')
        .eq('kelas_id', kelasId)
        .eq('tahun_ajaran_id', ta.id);
    final total =
        (await _db
                .from('penugasan_mengajar')
                .select('id')
                .eq('kelas_id', kelasId)
                .count(CountOption.exact))
            .count;
    final ksIds = [for (final a in anggota) a['id'] as int];
    final nilai = ksIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _db
              .from('detnilai')
              .select('kelas_siswa_id')
              .inFilter('kelas_siswa_id', ksIds)
              .eq('semester', semester);
    final terisi = <int, int>{};
    for (final n in nilai) {
      terisi.update(
        n['kelas_siswa_id'] as int,
        (v) => v + 1,
        ifAbsent: () => 1,
      );
    }
    final hasil = [
      for (final a in anggota)
        DataRaporModel(
          id: '${a['siswa']['id']}',
          namaSiswa: a['siswa']['nama'] as String,
          nisn: (a['siswa']['nisn'] ?? a['siswa']['nis']) as String,
          kelas: kelasNama,
          semester: semester,
          mapelSelesai: math.min(terisi[a['id'] as int] ?? 0, total),
          totalMapel: total,
        ),
    ];
    hasil.sort((a, b) => a.namaSiswa.compareTo(b.namaSiswa));
    return hasil;
  }

  // ---- Mata pelajaran ----

  Future<List<MapelModel>> daftarMapel() async {
    final rows = await _db
        .from('mapel')
        .select('id,kode,nama,penugasan_mengajar(guru(nama))')
        .order('nama');
    return [
      for (final r in rows)
        MapelModel(
          id: '${r['id']}',
          kode: r['kode'] as String,
          nama: r['nama'] as String,
          guruPengampu: _guruMapel(r['penugasan_mengajar']),
        ),
    ];
  }

  Future<void> tambahMapel({required String kode, required String nama}) =>
      _db.from('mapel').insert({'kode': kode, 'nama': nama});

  Future<void> ubahMapel({
    required int id,
    required String kode,
    required String nama,
  }) => _db.from('mapel').update({'kode': kode, 'nama': nama}).eq('id', id);

  /// Gagal (23503) bila mapel sudah dipakai penugasan atau nilai.
  Future<void> hapusMapel(int id) => _db.from('mapel').delete().eq('id', id);

  // ---- Tahun ajaran ----

  Future<List<TahunAjaranModel>> daftarTahunAjaran() async {
    final rows = await _db
        .from('tahun_ajaran')
        .select('id,tahun,semester_aktif,skm,is_active')
        .order('tahun', ascending: false);
    return [
      for (final r in rows)
        TahunAjaranModel(
          id: '${r['id']}',
          tahun: r['tahun'] as String,
          semester: r['semester_aktif'] as String,
          isActive: r['is_active'] as bool,
          skm: r['skm'] as int,
        ),
    ];
  }

  /// Mengembalikan id baris baru.
  Future<int> tambahTahunAjaran({
    required String tahun,
    required String semester,
    required int skm,
  }) async {
    final row = await _db
        .from('tahun_ajaran')
        .insert({'tahun': tahun, 'semester_aktif': semester, 'skm': skm})
        .select('id')
        .single();
    return row['id'] as int;
  }

  Future<void> ubahTahunAjaran({
    required int id,
    required String tahun,
    required String semester,
    required int skm,
  }) => _db
      .from('tahun_ajaran')
      .update({'tahun': tahun, 'semester_aktif': semester, 'skm': skm})
      .eq('id', id);

  /// Hanya satu tahun ajaran boleh aktif; fungsi database menukarnya secara
  /// atomik (migrasi 000005).
  Future<void> aktifkanTahunAjaran(int id) =>
      _db.rpc('set_tahun_ajaran_aktif', params: {'p_id': id});

  Future<void> hapusTahunAjaran(TahunAjaranModel t) {
    if (t.isActive) {
      throw const AppException(
        AppErrorType.conflict,
        'Tahun ajaran yang sedang aktif tidak bisa dihapus.',
      );
    }
    return _db.from('tahun_ajaran').delete().eq('id', int.parse(t.id));
  }

  // ---- Supabase Storage (bucket privat, hanya admin; lihat migrasi 000004) ----

  static const _bucketFoto = 'foto-siswa';
  static const _bucketBukti = 'rapor-bukti';

  Future<void> unggahFotoSiswa(int siswaId, Uint8List bytes, String mime) =>
      _unggah(_bucketFoto, '$siswaId', bytes, mime);

  /// URL bertanda (berlaku 1 jam), atau null bila siswa belum punya foto.
  Future<String?> urlFotoSiswa(int siswaId) =>
      _urlBertanda(_bucketFoto, '$siswaId');

  Future<void> unggahBuktiRapor({
    required int siswaId,
    required String semester,
    required Uint8List bytes,
    required String mime,
  }) async {
    final ta = await tahunAjaranAktif();
    await _unggah(_bucketBukti, '${ta.id}/$semester/$siswaId', bytes, mime);
  }

  Future<String?> urlBuktiRapor({
    required int siswaId,
    required String semester,
  }) async {
    final ta = await tahunAjaranAktif();
    return _urlBertanda(_bucketBukti, '${ta.id}/$semester/$siswaId');
  }

  Future<void> _unggah(
    String bucket,
    String path,
    Uint8List bytes,
    String mime,
  ) => _db.storage
      .from(bucket)
      .uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: mime, upsert: true),
      );

  Future<String?> _urlBertanda(String bucket, String path) async {
    try {
      return await _db.storage.from(bucket).createSignedUrl(path, 3600);
    } on StorageException {
      return null; // berkas belum ada
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
    await _db.functions.invoke(
      'admin-create-user',
      body: {
        'username': username,
        'password': password,
        'role': role.apiValue,
        'nama': nama,
        'nip': nip,
        'no_hp': noHp,
      },
    );
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

  static int? _kelasIdAktif(dynamic v, int taId) {
    for (final r in (v as List).cast<Map<String, dynamic>>()) {
      if (r['tahun_ajaran_id'] == taId) return r['kelas_id'] as int;
    }
    return null;
  }

  static String? _waliKelasAktif(dynamic v, int taId) {
    for (final r in (v as List).cast<Map<String, dynamic>>()) {
      if (r['tahun_ajaran_id'] == taId) return r['nama'] as String;
    }
    return null;
  }

  static String _guruMapel(dynamic v) {
    final nama = {
      for (final r in (v as List).cast<Map<String, dynamic>>())
        ?_nama(r['guru']),
    };
    return nama.isEmpty ? '-' : nama.join(', ');
  }

  static String _mapel(dynamic v) {
    final nama = {
      for (final r in (v as List).cast<Map<String, dynamic>>())
        r['mapel']['nama'] as String,
    };
    return nama.isEmpty ? '-' : nama.join(', ');
  }
}

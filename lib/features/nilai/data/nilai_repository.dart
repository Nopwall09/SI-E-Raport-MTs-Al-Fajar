import 'package:supabase_flutter/supabase_flutter.dart';

/// Satu baris penugasan: guru yang login mengajar [mapel] di [kelas].
class Penugasan {
  const Penugasan({
    required this.kelasId,
    required this.kelas,
    required this.mapelId,
    required this.mapel,
  });

  final int kelasId;
  final String kelas;
  final int mapelId;
  final String mapel;
}

/// Siswa di sebuah kelas beserta nilai UTS yang sudah tersimpan (null = belum).
class SiswaNilai {
  const SiswaNilai({
    required this.kelasSiswaId,
    required this.nama,
    required this.nis,
    this.nilai,
  });

  final int kelasSiswaId;
  final String nama;
  final String nis;
  final num? nilai;
}

/// Penugasan beserta jumlah nilai yang sudah masuk dari seluruh siswa kelas.
class PenugasanProgres {
  const PenugasanProgres(this.penugasan, this.terisi, this.total);

  final Penugasan penugasan;
  final int terisi;
  final int total;
}

/// Akses data input nilai. Penugasan disaring ke guru yang login; nilai
/// dibatasi RLS pada kelas+mapel yang diampu.
class NilaiRepository {
  NilaiRepository(this._db);

  final SupabaseClient _db;

  Future<List<Penugasan>> penugasanSaya(int tahunAjaranId) async {
    final rows = await _db
        .from('penugasan_mengajar')
        .select('kelas_id,mapel_id,kelas!inner(nama,tahun_ajaran_id),'
            'mapel(nama),guru!inner(user_id)')
        .eq('kelas.tahun_ajaran_id', tahunAjaranId)
        // Wali kelas juga bisa membaca penugasan guru lain di kelasnya.
        .eq('guru.user_id', _db.auth.currentUser!.id);
    final hasil = [
      for (final r in rows)
        Penugasan(
          kelasId: r['kelas_id'] as int,
          kelas: r['kelas']['nama'] as String,
          mapelId: r['mapel_id'] as int,
          mapel: r['mapel']['nama'] as String,
        ),
    ];
    hasil.sort((a, b) {
      final c = a.kelas.compareTo(b.kelas);
      return c != 0 ? c : a.mapel.compareTo(b.mapel);
    });
    return hasil;
  }

  Future<List<SiswaNilai>> siswaDanNilai({
    required int kelasId,
    required int mapelId,
    required String semester,
  }) async {
    final siswa = await _db
        .from('kelas_siswa')
        .select('id,siswa(nama,nis)')
        .eq('kelas_id', kelasId);
    final ids = [for (final s in siswa) s['id'] as int];
    final nilai = ids.isEmpty
        ? const []
        : await _db
            .from('detnilai')
            .select('kelas_siswa_id,nilai')
            .eq('mapel_id', mapelId)
            .eq('semester', semester)
            .inFilter('kelas_siswa_id', ids);
    final peta = {
      for (final n in nilai) n['kelas_siswa_id'] as int: n['nilai'] as num,
    };
    final hasil = [
      for (final s in siswa)
        SiswaNilai(
          kelasSiswaId: s['id'] as int,
          nama: s['siswa']['nama'] as String,
          nis: s['siswa']['nis'] as String,
          nilai: peta[s['id']],
        ),
    ];
    hasil.sort((a, b) => a.nama.compareTo(b.nama));
    return hasil;
  }

  /// Simpan (tambah atau ubah) nilai. Hanya baris yang diisi yang dikirim.
  Future<void> simpan({
    required int mapelId,
    required String semester,
    required Map<int, num> nilaiPerKelasSiswa,
  }) async {
    if (nilaiPerKelasSiswa.isEmpty) return;
    await _db.from('detnilai').upsert(
      [
        for (final e in nilaiPerKelasSiswa.entries)
          {
            'kelas_siswa_id': e.key,
            'mapel_id': mapelId,
            'semester': semester,
            'nilai': e.value,
          },
      ],
      onConflict: 'kelas_siswa_id,mapel_id,semester',
    );
  }

  /// Progres input per penugasan. Jumlah siswa dan nilai dihitung di sisi
  /// klien: datanya kecil (satu sekolah) dan tetap dibatasi RLS.
  Future<List<PenugasanProgres>> progres({
    required int tahunAjaranId,
    required String semester,
  }) async {
    final hasil = await Future.wait<dynamic>([
      penugasanSaya(tahunAjaranId),
      _db
          .from('kelas_siswa')
          .select('kelas_id')
          .eq('tahun_ajaran_id', tahunAjaranId),
      _db
          .from('detnilai')
          .select('mapel_id,kelas_siswa!inner(kelas_id)')
          .eq('semester', semester)
          .eq('kelas_siswa.tahun_ajaran_id', tahunAjaranId),
    ]);
    final penugasan = hasil[0] as List<Penugasan>;
    final siswaPerKelas = <int, int>{};
    for (final r in hasil[1] as List) {
      siswaPerKelas.update(r['kelas_id'] as int, (n) => n + 1, ifAbsent: () => 1);
    }
    final nilaiPerKelasMapel = <(int, int), int>{};
    for (final r in hasil[2] as List) {
      final k = (r['kelas_siswa']['kelas_id'] as int, r['mapel_id'] as int);
      nilaiPerKelasMapel.update(k, (n) => n + 1, ifAbsent: () => 1);
    }
    return [
      for (final p in penugasan)
        PenugasanProgres(
          p,
          nilaiPerKelasMapel[(p.kelasId, p.mapelId)] ?? 0,
          siswaPerKelas[p.kelasId] ?? 0,
        ),
    ];
  }
}

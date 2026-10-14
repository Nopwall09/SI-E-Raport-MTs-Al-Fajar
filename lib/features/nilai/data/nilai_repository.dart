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

/// Akses data input nilai. RLS membatasi guru hanya pada kelas+mapel
/// yang diampunya, jadi query tidak perlu menyaring guru lagi.
class NilaiRepository {
  NilaiRepository(this._db);

  final SupabaseClient _db;

  Future<List<Penugasan>> penugasanSaya(int tahunAjaranId) async {
    final rows = await _db
        .from('penugasan_mengajar')
        .select('kelas_id,mapel_id,kelas!inner(nama,tahun_ajaran_id),mapel(nama)')
        .eq('kelas.tahun_ajaran_id', tahunAjaranId);
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
}

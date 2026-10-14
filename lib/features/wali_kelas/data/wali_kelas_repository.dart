import 'package:supabase_flutter/supabase_flutter.dart';

class MapelStatus {
  const MapelStatus(this.mapel, this.nilai);

  final String mapel;
  final num? nilai; // null = belum diinput
}

class SiswaProgres {
  const SiswaProgres({
    required this.nama,
    required this.nis,
    required this.mapel,
  });

  final String nama;
  final String nis;
  final List<MapelStatus> mapel;

  int get terisi => mapel.where((m) => m.nilai != null).length;
}

/// Progres nilai seluruh siswa di kelas wali. RLS mengizinkan wali kelas
/// membaca penugasan dan nilai kelasnya (migration 20261014000003).
class WaliKelasRepository {
  WaliKelasRepository(this._db);

  final SupabaseClient _db;

  Future<List<SiswaProgres>> progres({
    required int kelasId,
    required String semester,
  }) async {
    final hasil = await Future.wait([
      _db
          .from('penugasan_mengajar')
          .select('mapel_id,mapel(nama)')
          .eq('kelas_id', kelasId),
      _db
          .from('kelas_siswa')
          .select('id,siswa(nama,nis)')
          .eq('kelas_id', kelasId),
    ]);
    final penugasan = hasil[0] as List;
    final siswa = hasil[1] as List;
    final ids = [for (final s in siswa) s['id'] as int];
    final nilai = ids.isEmpty
        ? const []
        : await _db
              .from('detnilai')
              .select('kelas_siswa_id,mapel_id,nilai')
              .eq('semester', semester)
              .inFilter('kelas_siswa_id', ids);
    final peta = {
      for (final n in nilai)
        (n['kelas_siswa_id'] as int, n['mapel_id'] as int): n['nilai'] as num,
    };
    penugasan.sort(
      (a, b) => (a['mapel']['nama'] as String).compareTo(
        b['mapel']['nama'] as String,
      ),
    );

    final daftar = [
      for (final s in siswa)
        SiswaProgres(
          nama: s['siswa']['nama'] as String,
          nis: s['siswa']['nis'] as String,
          mapel: [
            for (final p in penugasan)
              MapelStatus(
                p['mapel']['nama'] as String,
                peta[(s['id'] as int, p['mapel_id'] as int)],
              ),
          ],
        ),
    ];
    daftar.sort((a, b) => a.nama.compareTo(b.nama));
    return daftar;
  }
}

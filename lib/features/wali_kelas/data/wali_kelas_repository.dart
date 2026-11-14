import 'package:supabase_flutter/supabase_flutter.dart';

class MapelStatus {
  const MapelStatus(this.mapel, this.nilai);

  final String mapel;
  final num? nilai; // null = belum diinput
}

class SiswaProgres {
  const SiswaProgres({
    required this.kelasSiswaId,
    required this.nama,
    required this.nis,
    required this.mapel,
    this.sakit = 0,
    this.izin = 0,
    this.alpa = 0,
    this.catatan,
    this.status = 'draft',
    this.terkunci = false,
  });

  final int kelasSiswaId;
  final String nama;
  final String nis;
  final List<MapelStatus> mapel;

  /// Presensi dan catatan semester berjalan (tabel rapor).
  final int sakit;
  final int izin;
  final int alpa;
  final String? catatan;

  /// Status rapor: 'draft', 'menunggu_acc', atau 'final'.
  final String status;

  /// Rapor sudah final atau diajukan: presensi dan catatan terkunci.
  final bool terkunci;

  bool get isMenungguAcc => status == 'menunggu_acc';
  bool get isFinal => status == 'final';

  int get terisi => mapel.where((m) => m.nilai != null).length;
}

/// Progres nilai dan presensi seluruh siswa di kelas wali. RLS mengizinkan
/// wali kelas membaca penugasan, nilai, dan rapor kelasnya, serta mengubah
/// rapor yang masih draft (migration 20261014000001 dan 20261014000003).
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
    final lanjutan = ids.isEmpty
        ? const [<dynamic>[], <dynamic>[]]
        : await Future.wait([
            _db
                .from('detnilai')
                .select('kelas_siswa_id,mapel_id,nilai')
                .eq('semester', semester)
                .inFilter('kelas_siswa_id', ids),
            _db
                .from('rapor')
                .select('kelas_siswa_id,sakit,izin,alpa,catatan,status')
                .eq('semester', semester)
                .inFilter('kelas_siswa_id', ids),
          ]);
    final nilai = lanjutan[0];
    final rapor = {for (final r in lanjutan[1]) r['kelas_siswa_id'] as int: r};
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
          kelasSiswaId: s['id'] as int,
          nama: s['siswa']['nama'] as String,
          nis: s['siswa']['nis'] as String,
          mapel: [
            for (final p in penugasan)
              MapelStatus(
                p['mapel']['nama'] as String,
                peta[(s['id'] as int, p['mapel_id'] as int)],
              ),
          ],
          sakit: (rapor[s['id']]?['sakit'] as int?) ?? 0,
          izin: (rapor[s['id']]?['izin'] as int?) ?? 0,
          alpa: (rapor[s['id']]?['alpa'] as int?) ?? 0,
          catatan: rapor[s['id']]?['catatan'] as String?,
          status: (rapor[s['id']]?['status'] as String?) ?? 'draft',
          terkunci: rapor[s['id']]?['status'] == 'final' ||
              rapor[s['id']]?['status'] == 'menunggu_acc',
        ),
    ];
    daftar.sort((a, b) => a.nama.compareTo(b.nama));
    return daftar;
  }

  /// UC-17. Upsert, bukan update: baris rapor dibuat trigger saat siswa
  /// didaftarkan, tetapi pendaftaran lama bisa saja belum punya. RLS menolak
  /// perubahan pada rapor yang sudah final.
  Future<void> simpanPresensi({
    required int kelasSiswaId,
    required String semester,
    required int sakit,
    required int izin,
    required int alpa,
    String? catatan,
  }) => _db.from('rapor').upsert({
    'kelas_siswa_id': kelasSiswaId,
    'semester': semester,
    'sakit': sakit,
    'izin': izin,
    'alpa': alpa,
    'catatan': catatan,
  }, onConflict: 'kelas_siswa_id,semester');

  /// Wali kelas mengajukan verifikasi/ACC rapor kelas ke Kepala Madrasah/Admin.
  Future<void> ajukanAcc({
    required int kelasId,
    required String semester,
  }) => _db.rpc('ajukan_acc_rapor', params: {
    'p_kelas_id': kelasId,
    'p_semester': semester,
  });

  /// Mengesahkan (ACC) dan mengunci rapor secara permanen.
  Future<void> finalisasiRapor({
    required int kelasId,
    required String semester,
  }) => _db.rpc('finalisasi_rapor', params: {
    'p_kelas_id': kelasId,
    'p_semester': semester,
  });

  /// Buka kunci rapor kembali ke draft (khusus admin bila perlu revisi nilai).
  Future<void> bukaKunciRapor({
    required int kelasId,
    required String semester,
  }) => _db.rpc('buka_kunci_rapor', params: {
    'p_kelas_id': kelasId,
    'p_semester': semester,
  });

  /// Mengirim notifikasi push FCM ke seluruh siswa dan wali murid di kelas.
  Future<void> kirimNotifikasiFinal({
    required int kelasId,
    required String semester,
  }) async {
    try {
      await _db.functions.invoke('kirim-notifikasi-rapor', body: {
        'kelas_id': kelasId,
        'semester': semester,
      });
    } catch (_) {
      // Gagal notifikasi tidak membatalkan finalisasi
    }
  }
}

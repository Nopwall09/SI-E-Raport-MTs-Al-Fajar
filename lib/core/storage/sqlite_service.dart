import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Cache offline rapor di SQLite lokal, agar daftar terakhir yang dilihat
/// admin tetap bisa dibuka tanpa internet.
class SqliteOfflineService {
  static final SqliteOfflineService _instance =
      SqliteOfflineService._internal();
  factory SqliteOfflineService() => _instance;
  SqliteOfflineService._internal();

  static const _tabel = 'rapor_offline';

  Database? _db;

  Future<Database> _buka() async => _db ??= await openDatabase(
    p.join(await getDatabasesPath(), 'eraport_offline.db'),
    version: 1,
    onCreate: (db, _) => db.execute('''
      CREATE TABLE $_tabel (
        siswa_id INTEGER NOT NULL,
        semester TEXT NOT NULL,
        nama_siswa TEXT NOT NULL,
        nisn TEXT NOT NULL,
        kelas TEXT NOT NULL,
        mapel_selesai INTEGER NOT NULL,
        total_mapel INTEGER NOT NULL,
        tersimpan_pada TEXT NOT NULL,
        PRIMARY KEY (siswa_id, semester)
      )
    '''),
  );

  /// Mengganti isi cache untuk satu kelas dan semester.
  Future<void> simpanRapor({
    required String kelas,
    required String semester,
    required List<Map<String, Object?>> baris,
  }) async {
    final db = await _buka();
    final waktu = DateTime.now().toIso8601String();
    await db.transaction((trx) async {
      await trx.delete(
        _tabel,
        where: 'kelas = ? AND semester = ?',
        whereArgs: [kelas, semester],
      );
      final batch = trx.batch();
      for (final b in baris) {
        batch.insert(_tabel, {...b, 'tersimpan_pada': waktu});
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Map<String, Object?>>> bacaRapor({
    required String kelas,
    required String semester,
  }) async => (await _buka()).query(
    _tabel,
    where: 'kelas = ? AND semester = ?',
    whereArgs: [kelas, semester],
    orderBy: 'nama_siswa',
  );

  Future<int> jumlahTersimpan() async => Sqflite.firstIntValue(
    await (await _buka()).rawQuery('SELECT COUNT(*) FROM $_tabel'),
  )!;
}

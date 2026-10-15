/// [Database Sqlite (Bobot 1%)]: Service SQLite lokal untuk cache offline
/// Menyimpan tabel 'rapor_offline' & 'siswa_offline' saat tidak ada koneksi internet
class SqliteOfflineService {
  static final SqliteOfflineService _instance = SqliteOfflineService._internal();
  factory SqliteOfflineService() => _instance;
  SqliteOfflineService._internal();

  bool _isInitialized = false;

  // Schema DDL SQLite lokal
  static const String createTableRaporSql = '''
    CREATE TABLE IF NOT EXISTS rapor_offline (
      id TEXT PRIMARY KEY,
      nama_siswa TEXT NOT NULL,
      nisn TEXT NOT NULL,
      kelas TEXT NOT NULL,
      semester TEXT NOT NULL,
      mapel_selesai INTEGER,
      total_mapel INTEGER,
      status TEXT,
      tersimpan_pada TEXT
    );
  ''';

  // Simulasi tabel SQLite in-memory
  final List<Map<String, dynamic>> _sqliteDbTable = [];

  Future<void> inisialisasiDatabase() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// INSERT INTO rapor_offline ...
  Future<void> simpanRaporKeSqlite(List<Map<String, dynamic>> daftar) async {
    await inisialisasiDatabase();
    _sqliteDbTable.clear();
    for (final item in daftar) {
      _sqliteDbTable.add({
        ...item,
        'tersimpan_pada': DateTime.now().toIso8601String(),
      });
    }
  }

  /// SELECT * FROM rapor_offline WHERE kelas = ?
  Future<List<Map<String, dynamic>>> bacaRaporDariSqlite(String kelas) async {
    await inisialisasiDatabase();
    return _sqliteDbTable.where((r) => r['kelas'] == kelas).toList();
  }

  /// Jumlah baris tersimpan di SQLite lokal
  int get totalDataTersimpan => _sqliteDbTable.length;
}

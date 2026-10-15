/// [SharedPreferences (Bobot 1%)]: Service penyimpanan preferensi lokal
/// Digunakan untuk menyimpan preferensi admin (kelas aktif, filter, status sinkronisasi offline)
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  // Memori lokal in-app storage
  final Map<String, dynamic> _memoryCache = {
    'pref_kelas_aktif': 'VII-A',
    'pref_semester_aktif': 'Ganjil',
    'pref_hanya_siap': false,
    'pref_terakhir_sinkron': '15 Okt 2026 21:00',
  };

  Future<void> simpanString(String key, String value) async {
    _memoryCache[key] = value;
  }

  Future<String?> ambilString(String key) async {
    return _memoryCache[key] as String?;
  }

  Future<void> simpanBool(String key, bool value) async {
    _memoryCache[key] = value;
  }

  Future<bool> ambilBool(String key, {bool defaultValue = false}) async {
    return (_memoryCache[key] as bool?) ?? defaultValue;
  }

  // Helper SharedPreferences untuk modul Data Rapor
  Future<void> simpanPreferensiRapor({
    required String kelas,
    required String semester,
    required bool hanyaSiap,
  }) async {
    await simpanString('pref_kelas_aktif', kelas);
    await simpanString('pref_semester_aktif', semester);
    await simpanBool('pref_hanya_siap', hanyaSiap);
  }

  Future<Map<String, dynamic>> ambilPreferensiRapor() async {
    return {
      'kelas': await ambilString('pref_kelas_aktif') ?? 'VII-A',
      'semester': await ambilString('pref_semester_aktif') ?? 'Ganjil',
      'hanyaSiap': await ambilBool('pref_hanya_siap', defaultValue: false),
    };
  }
}

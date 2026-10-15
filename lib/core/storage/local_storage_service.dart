import 'package:shared_preferences/shared_preferences.dart';

/// Preferensi ringan yang bertahan setelah aplikasi ditutup (SharedPreferences).
/// Dipakai untuk mengingat filter terakhir admin di layar Data Rapor.
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const _kKelas = 'pref_kelas_aktif';
  static const _kSemester = 'pref_semester_aktif';
  static const _kHanyaSiap = 'pref_hanya_siap';

  Future<void> simpanString(String key, String value) async =>
      (await SharedPreferences.getInstance()).setString(key, value);

  Future<String?> ambilString(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  Future<void> simpanBool(String key, bool value) async =>
      (await SharedPreferences.getInstance()).setBool(key, value);

  Future<bool> ambilBool(String key, {bool defaultValue = false}) async =>
      (await SharedPreferences.getInstance()).getBool(key) ?? defaultValue;

  Future<void> simpanPreferensiRapor({
    required String? kelas,
    required String semester,
    required bool hanyaSiap,
  }) async {
    if (kelas != null) await simpanString(_kKelas, kelas);
    await simpanString(_kSemester, semester);
    await simpanBool(_kHanyaSiap, hanyaSiap);
  }

  /// `kelas` null bila belum pernah disimpan.
  Future<({String? kelas, String semester, bool hanyaSiap})>
  ambilPreferensiRapor() async => (
    kelas: await ambilString(_kKelas),
    semester: await ambilString(_kSemester) ?? 'ganjil',
    hanyaSiap: await ambilBool(_kHanyaSiap),
  );
}

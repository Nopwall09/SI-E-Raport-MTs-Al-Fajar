/// Konfigurasi build-time. Ganti lewat `--dart-define`, contoh:
///
///   flutter run --dart-define=USE_FAKE_API=false \
///     --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
///
/// `10.0.2.2` adalah alamat localhost laptop dari dalam emulator Android.
class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// Selama backend belum siap (Sprint 1), aplikasi memakai data contoh.
  static const bool useFakeApi = bool.fromEnvironment(
    'USE_FAKE_API',
    defaultValue: true,
  );
}

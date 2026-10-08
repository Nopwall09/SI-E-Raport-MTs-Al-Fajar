/// Konfigurasi build-time. Ganti lewat `--dart-define`, contoh:
///
///   flutter run --dart-define=USE_FAKE_API=false \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=eyJ...
///
/// Anon key memang publik dan aman ada di aplikasi, asalkan RLS aktif di
/// semua tabel. JANGAN PERNAH memasukkan service role key ke aplikasi.
class Env {
  const Env._();

  /// Selama backend belum siap, aplikasi memakai data contoh.
  static const bool useFakeApi = bool.fromEnvironment(
    'USE_FAKE_API',
    defaultValue: true,
  );

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Supabase Auth masuk lewat email, sedangkan pengguna masuk dengan
  /// username. Username diubah menjadi `username@<domain ini>`. Domain harus
  /// sama dengan yang dipakai Edge Function saat membuat akun. Email tidak
  /// pernah dikirim, jadi domainnya tidak perlu benar-benar ada.
  static const String authEmailDomain = String.fromEnvironment(
    'AUTH_EMAIL_DOMAIN',
    defaultValue: 'eraport.example.com',
  );
}

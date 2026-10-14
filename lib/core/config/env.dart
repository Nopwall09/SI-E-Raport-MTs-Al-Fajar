/// Konfigurasi build-time. Bawaannya sudah mengarah ke Supabase proyek ini;
/// ganti lewat `--dart-define` bila perlu (SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY).
///
/// Anon key memang publik dan aman ada di aplikasi, asalkan RLS aktif di
/// semua tabel. JANGAN PERNAH memasukkan service role key ke aplikasi.
class Env {
  const Env._();

  /// Data contoh tanpa jaringan hanya untuk eksperimen:
  /// `--dart-define=USE_FAKE_API=true`. Test memakai override, bukan flag ini.
  static const bool useFakeApi = bool.fromEnvironment('USE_FAKE_API');

  // URL dan publishable key memang publik (keamanan dijaga RLS), jadi aman
  // jadi nilai bawaan agar `flutter run` langsung tersambung.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ncjvviupomqcpbinnvdn.supabase.co',
  );
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_px3u03HejuxDEg4gz45AXA__ATYOUjP',
  );

  /// Supabase Auth masuk lewat email, sedangkan pengguna masuk dengan
  /// username. Username diubah menjadi `username@<domain ini>`. Domain harus
  /// sama dengan yang dipakai Edge Function saat membuat akun. Email tidak
  /// pernah dikirim, jadi domainnya tidak perlu benar-benar ada.
  static const String authEmailDomain = String.fromEnvironment(
    'AUTH_EMAIL_DOMAIN',
    defaultValue: 'eraport.example.com',
  );
}

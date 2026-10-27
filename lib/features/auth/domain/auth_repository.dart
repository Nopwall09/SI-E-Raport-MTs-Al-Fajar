import 'user.dart';

abstract class AuthRepository {
  /// Melempar `AppException` bila gagal.
  Future<AppUser> login({required String username, required String password});

  /// Mengembalikan null bila belum ada sesi atau sesi sudah tidak berlaku.
  Future<AppUser?> restoreSession();

  /// Mengganti password pengguna yang login, menghapus kewajiban ganti
  /// password, lalu mengembalikan profil terbaru. Melempar `AppException`.
  Future<AppUser> gantiPassword(String passwordBaru);

  /// Selalu mengakhiri sesi lokal, walau permintaan ke server gagal.
  Future<void> logout();

  /// Terpancar saat sesi berakhir di luar kendali pengguna, misalnya refresh
  /// token gagal atau akun dinonaktifkan.
  Stream<void> get onSignedOut;
}

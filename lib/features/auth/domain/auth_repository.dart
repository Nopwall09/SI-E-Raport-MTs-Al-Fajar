import 'user.dart';

abstract class AuthRepository {
  /// Melempar `AppException` bila gagal.
  Future<AppUser> login({
    required String username,
    required String password,
    required String deviceName,
  });

  /// Mengembalikan null bila belum ada sesi atau token sudah tidak berlaku.
  Future<AppUser?> restoreSession();

  /// Selalu menghapus token lokal, walau permintaan ke server gagal.
  Future<void> logout();
}

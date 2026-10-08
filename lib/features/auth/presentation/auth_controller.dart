import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/providers.dart';
import '../data/api_auth_repository.dart';
import '../data/fake_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

/// Ganti ke implementasi asli lewat `--dart-define=USE_FAKE_API=false`.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  if (Env.useFakeApi) {
    return FakeAuthRepository(tokenStorage: tokenStorage);
  }
  return ApiAuthRepository(
    dio: ref.watch(dioProvider),
    tokenStorage: tokenStorage,
  );
});

/// State login seluruh aplikasi.
///   loading     -> memeriksa sesi tersimpan (splash)
///   data(null)  -> belum masuk
///   data(user)  -> sudah masuk
///   error       -> gagal memeriksa sesi (mis. tidak ada koneksi)
class AuthController extends AsyncNotifier<AppUser?> {
  static const _deviceName = 'Aplikasi mobile';

  @override
  Future<AppUser?> build() {
    final subscription =
        ref.read(sessionEventsProvider).onExpired.listen((_) => _onExpired());
    ref.onDispose(subscription.cancel);
    return ref.read(authRepositoryProvider).restoreSession();
  }

  /// Melempar `AppException` agar layar login bisa menampilkan pesannya.
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final user = await ref.read(authRepositoryProvider).login(
          username: username,
          password: password,
          deviceName: _deviceName,
        );
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  void _onExpired() {
    // Saat pemeriksaan sesi awal, hasilnya ditangani repository sendiri.
    if (state.isLoading) return;
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);

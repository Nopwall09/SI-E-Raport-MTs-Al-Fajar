import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/providers.dart';
import '../../notifikasi/notifikasi_providers.dart';
import '../data/fake_auth_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

/// Ganti ke Supabase asli lewat `--dart-define=USE_FAKE_API=false`.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (Env.useFakeApi) return FakeAuthRepository();
  return SupabaseAuthRepository(client: ref.watch(supabaseClientProvider));
});

/// State login seluruh aplikasi.
///   loading     -> memeriksa sesi tersimpan (splash)
///   data(null)  -> belum masuk
///   data(user)  -> sudah masuk
///   error       -> gagal memeriksa sesi (mis. tidak ada koneksi)
class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() {
    final repository = ref.read(authRepositoryProvider);
    final subscription = repository.onSignedOut.listen((_) => _onSignedOut());
    ref.onDispose(subscription.cancel);
    return repository.restoreSession();
  }

  /// Melempar `AppException` agar layar login bisa menampilkan pesannya.
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .login(username: username, password: password);
    state = AsyncData(user);
  }

  /// Melempar `AppException`. Mengembalikan profil baru agar layar bisa
  /// langsung berpindah ke beranda.
  Future<AppUser> gantiPassword(String passwordBaru) async {
    final user = await ref
        .read(authRepositoryProvider)
        .gantiPassword(passwordBaru);
    state = AsyncData(user);
    return user;
  }

  Future<void> logout() async {
    // Hapus token perangkat selagi sesi masih berlaku; gagal tidak boleh
    // menghalangi keluar.
    try {
      await ref.read(notifikasiServiceProvider).berhenti();
    } catch (_) {}
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  void _onSignedOut() {
    // Saat pemeriksaan sesi awal, hasilnya ditangani repository sendiri.
    if (state.isLoading) return;
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/error/app_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

/// Kontrak yang diasumsikan (konfirmasi saat skema Postgres dibuat):
///
/// Fungsi `public.get_my_profile()` mengembalikan json untuk pengguna yang
/// sedang login (berdasarkan `auth.uid()`):
///   {"id": "(uuid)", "name": "...", "role": "guru",
///    "wali_kelas": null | {"kelas_id": 3, "nama": "7A"}}
///
/// `wali_kelas` terisi bila guru itu wali kelas pada tahun ajaran aktif.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({required this._client});

  final SupabaseClient _client;

  static String emailFor(String username) =>
      '${username.trim().toLowerCase()}@${Env.authEmailDomain}';

  @override
  Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: emailFor(username),
        password: password,
      );
      return await _loadProfile();
    } catch (e) {
      // Jangan tinggalkan sesi setengah jadi (sudah masuk, profil gagal dimuat).
      if (_client.auth.currentSession != null) await _safeSignOut();
      throw AppException.from(e);
    }
  }

  @override
  Future<AppUser?> restoreSession() async {
    if (_client.auth.currentSession == null) return null;
    try {
      return await _loadProfile();
    } catch (e) {
      final error = AppException.from(e);
      if (error.type == AppErrorType.unauthorized) {
        await _safeSignOut();
        return null;
      }
      throw error;
    }
  }

  @override
  Future<void> logout() => _safeSignOut();

  @override
  Stream<void> get onSignedOut => _client.auth.onAuthStateChange
      .where((state) => state.event == AuthChangeEvent.signedOut)
      .map((_) {});

  Future<AppUser> _loadProfile() async {
    final data = await _client.rpc('get_my_profile');
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Profil kosong');
    }
    return AppUser.fromJson(data);
  }

  Future<void> _safeSignOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Sesi lokal tetap dianggap berakhir walau server tidak terjangkau.
    }
  }
}

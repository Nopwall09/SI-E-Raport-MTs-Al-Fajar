import '../../../core/error/app_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

/// Implementasi data contoh agar tim mobile bisa jalan tanpa backend.
/// Username yang tersedia: admin, guru, walikelas, siswa, wali.
/// Password bebas, asal tidak kosong.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    required TokenStorage tokenStorage,
    this.latency = const Duration(milliseconds: 400),
  }) : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;
  final Duration latency;

  static const _tokenPrefix = 'fake:';

  static const Map<String, AppUser> _users = {
    'admin': AppUser(id: 1, name: 'Admin TU', role: UserRole.admin),
    'guru': AppUser(id: 2, name: 'Guru Contoh', role: UserRole.guru),
    'walikelas': AppUser(
      id: 3,
      name: 'Guru Wali Kelas',
      role: UserRole.guru,
      waliKelas: WaliKelasInfo(kelasId: 1, namaKelas: '7A'),
    ),
    'siswa': AppUser(id: 4, name: 'Siswa Contoh', role: UserRole.siswa),
    'wali': AppUser(id: 5, name: 'Wali Murid Contoh', role: UserRole.waliMurid),
  };

  @override
  Future<AppUser> login({
    required String username,
    required String password,
    required String deviceName,
  }) async {
    await Future<void>.delayed(latency);
    final key = username.trim().toLowerCase();
    final user = _users[key];
    if (user == null || password.isEmpty) {
      throw const AppException(
        AppErrorType.unauthorized,
        'Username atau password salah.',
      );
    }
    await _tokenStorage.write('$_tokenPrefix$key');
    return user;
  }

  @override
  Future<AppUser?> restoreSession() async {
    await Future<void>.delayed(latency);
    final token = await _tokenStorage.read();
    if (token == null || !token.startsWith(_tokenPrefix)) return null;
    final user = _users[token.substring(_tokenPrefix.length)];
    if (user == null) await _tokenStorage.clear();
    return user;
  }

  @override
  Future<void> logout() => _tokenStorage.clear();
}

import '../../../core/error/app_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

/// Implementasi data contoh agar tim bisa jalan tanpa backend.
/// Username yang tersedia: admin, guru, walikelas, siswa, wali.
/// Password bebas, asal tidak kosong. Sesi hanya hidup selama aplikasi jalan.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.latency = const Duration(milliseconds: 400),
    String? signedInAs,
  }) : _current = signedInAs == null ? null : _users[signedInAs];

  final Duration latency;
  AppUser? _current;

  static const Map<String, AppUser> _users = {
    'admin': AppUser(id: 'fake-admin', name: 'Admin TU', role: UserRole.admin),
    'guru': AppUser(id: 'fake-guru', name: 'Guru Contoh', role: UserRole.guru),
    'walikelas': AppUser(
      id: 'fake-walikelas',
      name: 'Guru Wali Kelas',
      role: UserRole.guru,
      waliKelas: WaliKelasInfo(kelasId: 1, namaKelas: '7A'),
    ),
    'siswa': AppUser(
      id: 'fake-siswa',
      name: 'Siswa Contoh',
      role: UserRole.siswa,
    ),
    'wali': AppUser(
      id: 'fake-wali',
      name: 'Wali Murid Contoh',
      role: UserRole.waliMurid,
    ),
  };

  @override
  Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    final user = _users[username.trim().toLowerCase()];
    if (user == null || password.isEmpty) {
      throw const AppException(
        AppErrorType.unauthorized,
        'Username atau password salah.',
      );
    }
    _current = user;
    return user;
  }

  @override
  Future<AppUser?> restoreSession() async {
    await Future<void>.delayed(latency);
    return _current;
  }

  @override
  Future<void> logout() async {
    _current = null;
  }

  @override
  Stream<void> get onSignedOut => const Stream<void>.empty();
}

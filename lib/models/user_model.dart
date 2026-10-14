import '../features/auth/domain/user.dart';

// Layar admin memakai enum role yang sama dengan auth.
export '../features/auth/domain/user.dart' show UserRole;

class UserModel {
  final String id;
  final String nama;
  final String email;
  final UserRole role;

  const UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
  });
}

enum UserRole {
  admin,
  guru,
  waliMurid,
  siswa;

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.guru:
        return 'Guru';
      case UserRole.waliMurid:
        return 'Wali Murid';
      case UserRole.siswa:
        return 'Siswa';
    }
  }
}

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

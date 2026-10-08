enum UserRole {
  admin('admin', 'Admin TU', '/admin'),
  guru('guru', 'Guru', '/guru'),
  siswa('siswa', 'Siswa', '/siswa'),
  waliMurid('wali_murid', 'Wali murid', '/wali-murid');

  const UserRole(this.apiValue, this.label, this.basePath);

  final String apiValue;
  final String label;
  final String basePath;

  static UserRole fromApi(String value) {
    for (final role in UserRole.values) {
      if (role.apiValue == value) return role;
    }
    throw FormatException('Role tidak dikenal: $value');
  }
}

/// Wali kelas bukan role di server, melainkan penugasan seorang guru.
/// Karena itu `get_my_profile()` harus menyertakan info ini.
class WaliKelasInfo {
  const WaliKelasInfo({required this.kelasId, required this.namaKelas});

  final int kelasId;
  final String namaKelas;

  factory WaliKelasInfo.fromJson(Map<String, dynamic> json) {
    return WaliKelasInfo(
      kelasId: json['kelas_id'] as int,
      namaKelas: json['nama'] as String,
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.waliKelas,
  });

  final String id;
  final String name;
  final UserRole role;
  final WaliKelasInfo? waliKelas;

  bool get isWaliKelas => waliKelas != null;

  String get homePath => '${role.basePath}/beranda';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final waliKelas = json['wali_kelas'];
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      role: UserRole.fromApi(json['role'] as String),
      waliKelas: waliKelas is Map<String, dynamic>
          ? WaliKelasInfo.fromJson(waliKelas)
          : null,
    );
  }
}

class GuruModel {
  final String id;
  final String nama;
  final String nip;
  final String mapel;
  final String? waliKelas; // Jika guru ini menjadi wali kelas, contoh: "VII-A"
  final String email;
  final String telepon;

  const GuruModel({
    required this.id,
    required this.nama,
    required this.nip,
    required this.mapel,
    this.waliKelas,
    this.email = '',
    this.telepon = '',
  });
}

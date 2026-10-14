class SiswaModel {
  final String id;
  final String nama;
  final String nisn;
  final String kelas;
  final String jenisKelamin; // 'L' atau 'P'
  final String namaWali;
  final String status; // 'Aktif', 'Alumni', dll

  const SiswaModel({
    required this.id,
    required this.nama,
    required this.nisn,
    required this.kelas,
    this.jenisKelamin = 'L',
    this.namaWali = '',
    this.status = 'Aktif',
  });
}

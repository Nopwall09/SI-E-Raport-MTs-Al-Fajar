class TahunAjaranModel {
  final String id;
  final String tahun; // contoh: 2026/2027
  final String semester; // 'ganjil' atau 'genap'
  final bool isActive;
  final int skm; // satu angka untuk semua mapel

  const TahunAjaranModel({
    required this.id,
    required this.tahun,
    required this.semester,
    required this.isActive,
    required this.skm,
  });

  String get semesterLabel => semester == 'ganjil' ? 'Ganjil' : 'Genap';
}

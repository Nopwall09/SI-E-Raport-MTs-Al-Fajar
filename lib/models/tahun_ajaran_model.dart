class TahunAjaranModel {
  final String id;
  final String tahun;
  final String semester; // 'Ganjil' atau 'Genap'
  final bool isActive;
  final int skm;

  const TahunAjaranModel({
    required this.id,
    required this.tahun,
    required this.semester,
    required this.isActive,
    this.skm = 75,
  });
}

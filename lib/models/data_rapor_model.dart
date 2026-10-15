class DataRaporModel {
  final String id;
  final String namaSiswa;
  final String nisn;
  final String kelas;
  final String semester;
  final int mapelSelesai;
  final int totalMapel;
  final String status; // 'Siap' atau 'Belum Siap'

  const DataRaporModel({
    required this.id,
    required this.namaSiswa,
    required this.nisn,
    required this.kelas,
    required this.semester,
    required this.mapelSelesai,
    required this.totalMapel,
    this.status = 'Siap',
  });

  bool get isSiap => status == 'Siap' || mapelSelesai >= totalMapel;
}

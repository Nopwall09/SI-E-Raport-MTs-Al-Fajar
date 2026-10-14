class ProgressInputNilai {
  final String kelas;
  final String mapel;
  final String namaGuru;
  final int persen;

  const ProgressInputNilai({
    required this.kelas,
    required this.mapel,
    required this.namaGuru,
    required this.persen,
  });
}

class DashboardStatistik {
  final int totalSiswa;
  final int totalGuru;
  final int totalKelas;
  final int totalOrangTua;

  const DashboardStatistik({
    required this.totalSiswa,
    required this.totalGuru,
    required this.totalKelas,
    required this.totalOrangTua,
  });
}

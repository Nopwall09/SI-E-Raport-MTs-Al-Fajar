class NilaiMapel {
  final String namaMapel;
  final int nilai;
  final String tanggalUpdate;
  final String kategori;

  const NilaiMapel({
    required this.namaMapel,
    required this.nilai,
    required this.tanggalUpdate,
    this.kategori = 'Umum',
  });
}

class SiswaProfile {
  final String nama;
  final String kelas;
  final String nisn;
  final double rataRata;
  final String catatanWali;
  final int sakit;
  final int izin;
  final int alfa;
  final List<double> historiPerkembangan;

  const SiswaProfile({
    required this.nama,
    required this.kelas,
    required this.nisn,
    required this.rataRata,
    required this.catatanWali,
    required this.sakit,
    required this.izin,
    required this.alfa,
    required this.historiPerkembangan,
  });
}

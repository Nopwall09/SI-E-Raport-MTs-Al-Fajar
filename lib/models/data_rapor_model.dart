/// Kesiapan rapor satu siswa pada satu semester: berapa mata pelajaran yang
/// nilainya sudah diinput dibanding yang diajarkan di kelasnya.
class DataRaporModel {
  final String id; // id siswa
  final String namaSiswa;
  final String nisn;
  final String kelas;
  final String semester; // 'ganjil' atau 'genap'
  final int mapelSelesai;
  final int totalMapel;
  final String statusRapor; // 'draft', 'menunggu_acc', 'final'

  const DataRaporModel({
    required this.id,
    required this.namaSiswa,
    required this.nisn,
    required this.kelas,
    required this.semester,
    required this.mapelSelesai,
    required this.totalMapel,
    this.statusRapor = 'draft',
  });

  /// Siap bila ada mapel dan semuanya sudah ada nilainya.
  bool get isSiap => totalMapel > 0 && mapelSelesai >= totalMapel;

  bool get isFinal => statusRapor == 'final';
  bool get isMenungguAcc => statusRapor == 'menunggu_acc';

  String get status => isFinal
      ? 'Final (ACC)'
      : isMenungguAcc
          ? 'Menunggu ACC'
          : isSiap
              ? 'Siap'
              : 'Belum Siap';
}

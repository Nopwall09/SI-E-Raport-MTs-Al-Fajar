class KelasModel {
  final String id;
  final String namaKelas; // Contoh: "VII-A"
  final String tingkat;   // Contoh: "VII", "VIII", "IX"
  final String namaWali;  // Contoh: "Ust. Zulkifli, S.Pd.I"
  final int jumlahSiswa;  // Contoh: 32
  final int kapasitas;    // Contoh: 34

  const KelasModel({
    required this.id,
    required this.namaKelas,
    required this.tingkat,
    required this.namaWali,
    required this.jumlahSiswa,
    this.kapasitas = 36,
  });
}

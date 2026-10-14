class SiswaModel {
  final String id;
  final String nama;
  final String nisn;
  final String kelas;
  final String jenisKelamin; // 'L' atau 'P'
  final String namaWali;
  final String status; // 'Aktif', 'Alumni', dll

  // Dipakai form ubah.
  final String nis;
  final String? nisnAsli;
  final DateTime? tglLahir;
  final int? kelasId;
  final int? waliMuridId;

  const SiswaModel({
    required this.id,
    required this.nama,
    required this.nisn,
    required this.kelas,
    this.jenisKelamin = 'L',
    this.namaWali = '',
    this.status = 'Aktif',
    this.nis = '',
    this.nisnAsli,
    this.tglLahir,
    this.kelasId,
    this.waliMuridId,
  });
}

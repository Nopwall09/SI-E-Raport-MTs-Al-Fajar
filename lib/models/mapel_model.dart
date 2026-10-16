class MapelModel {
  final String id;
  final String kode;
  final String nama;
  final String guruPengampu; // dari penugasan mengajar; '-' bila belum ada
  final String kategori; // 'Agama', 'Bahasa', atau 'Umum'
  final String? jamMulai; // 'HH:mm', null bila belum diatur

  const MapelModel({
    required this.id,
    required this.kode,
    required this.nama,
    required this.guruPengampu,
    this.kategori = 'Umum',
    this.jamMulai,
  });
}

class MapelModel {
  final String id;
  final String kode;
  final String nama;
  final String guruPengampu; // dari penugasan mengajar; '-' bila belum ada

  const MapelModel({
    required this.id,
    required this.kode,
    required this.nama,
    required this.guruPengampu,
  });
}

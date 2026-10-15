class MapelModel {
  final String id;
  final String kode;
  final String nama;
  final String guruPengampu;
  final String kategori;

  const MapelModel({
    required this.id,
    required this.kode,
    required this.nama,
    required this.guruPengampu,
    this.kategori = 'Umum',
  });
}

import '../auth/domain/user.dart';

/// Pesan notifikasi yang sudah disederhanakan, supaya layar tidak perlu
/// mengenal Firebase.
class PesanNotifikasi {
  const PesanNotifikasi({this.judul, this.isi, this.data = const {}});

  final String? judul;
  final String? isi;
  final Map<String, dynamic> data;
}

/// Tujuan saat notifikasi diketuk, atau null bila tidak perlu pindah layar.
///
/// Rapor final seharusnya membuka layar Rapor anak itu (`/siswa/rapor` dan
/// `/wali-murid/rapor?siswa=ID`, lihat dokumen rancangan FCM). Layar itu belum
/// ada, jadi sementara membuka beranda role-nya. Ganti di sini saja bila sudah
/// ada.
String? ruteNotifikasi(PesanNotifikasi pesan, AppUser? user) {
  if (user == null) return null;
  return switch (pesan.data['type']) {
    'rapor_final' => user.homePath,
    _ => null,
  };
}

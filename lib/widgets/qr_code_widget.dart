import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// QR-Code sungguhan (bisa dipindai) untuk verifikasi rapor dan kartu siswa.
class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color color;
  final Color backgroundColor;

  const QrCodeWidget({
    super.key,
    required this.data,
    this.size = 180,
    this.color = const Color(0xFF14201A),
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'QR-Code verifikasi',
      // QrImageView memakai LayoutBuilder, yang tidak bisa ditanya ukuran
      // intrinsiknya (AlertDialog melakukannya). Ukuran pasti dari luar
      // menjawab pertanyaan itu tanpa menyentuh LayoutBuilder.
      child: SizedBox.square(
        dimension: size,
        child: QrImageView(
          data: data,
          size: size,
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.all(12),
          eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: color),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: color,
          ),
        ),
      ),
    );
  }
}

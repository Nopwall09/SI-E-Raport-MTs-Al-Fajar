import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app/theme.dart';

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

/// Dialog QR: nama, rincian yang sama dengan isi QR, lalu QR-nya. Isi QR
/// berupa teks biasa agar terbaca di aplikasi pemindai mana pun.
Future<void> tampilkanDialogQr(
  BuildContext context, {
  required String judul,
  required String nama,
  required List<(String, String)> info,
  required String isiQr,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                judul,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                nama,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: kField,
                  borderRadius: BorderRadius.circular(kRadiusControl),
                ),
                child: Column(
                  children: [
                    for (final (label, nilai) in info)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(label, style: const TextStyle(color: kMuted)),
                            const SizedBox(width: 16),
                            Flexible(
                              child: Text(
                                nilai,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kRadiusControl),
                    border: Border.all(color: kBorder),
                  ),
                  child: QrCodeWidget(data: isiQr, size: 220, color: kBrand),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pindai untuk membaca data di atas.',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

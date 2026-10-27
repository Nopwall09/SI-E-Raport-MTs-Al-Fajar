import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme.dart';

/// Tipe konten dari ekstensi berkas gambar (kamera biasanya jpg).
String mimeGambar(XFile f) {
  final nama = f.name.toLowerCase();
  if (nama.endsWith('.png')) return 'image/png';
  if (nama.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

/// Sheet pemilih sumber foto: kamera atau galeri. Foto dipilih sungguhan lewat
/// image_picker, lalu [onPicked] menerima berkasnya. Bila dibatalkan, tidak
/// dipanggil.
class MediaPickerDialog extends StatelessWidget {
  const MediaPickerDialog({
    super.key,
    required this.title,
    required this.studentName,
    required this.onPicked,
  });

  final String title;
  final String studentName;
  final Future<void> Function(XFile file) onPicked;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String studentName,
    required Future<void> Function(XFile file) onPicked,
  }) {
    return showModalBottomSheet(
      context: context,
      builder: (_) => MediaPickerDialog(
        title: title,
        studentName: studentName,
        onPicked: onPicked,
      ),
    );
  }

  Future<void> _ambil(BuildContext context, ImageSource sumber) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    try {
      final file = await ImagePicker().pickImage(
        source: sumber,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      await onPicked(file);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka kamera atau galeri.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Untuk: $studentName',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Sumber(
                    icon: Icons.camera_alt_outlined,
                    label: 'Kamera',
                    onTap: () => _ambil(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Sumber(
                    icon: Icons.photo_library_outlined,
                    label: 'Galeri',
                    onTap: () => _ambil(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Sumber extends StatelessWidget {
  const _Sumber({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kField,
      borderRadius: BorderRadius.circular(kRadiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadiusCard),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: kBrand, size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../app/theme.dart';

/// [Kamera (Bobot 1%)] & [Gallery (Bobot 1%)]: Dialog pemilih foto & dokumen fisik
class MediaPickerDialog extends StatefulWidget {
  final String title;
  final String studentName;
  final Function(String source, String fileName) onMediaSelected;

  const MediaPickerDialog({
    super.key,
    required this.title,
    required this.studentName,
    required this.onMediaSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String studentName,
    required Function(String source, String fileName) onMediaSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => MediaPickerDialog(
        title: title,
        studentName: studentName,
        onMediaSelected: onMediaSelected,
      ),
    );
  }

  @override
  State<MediaPickerDialog> createState() => _MediaPickerDialogState();
}

class _MediaPickerDialogState extends State<MediaPickerDialog> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'Dokumen/Foto untuk: ${widget.studentName}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                // [Kamera (1%)]: Ambil foto lewat kamera
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pop(context);
                      final fileName = 'foto_kamera_${DateTime.now().millisecondsSinceEpoch}.jpg';
                      widget.onMediaSelected('Kamera', fileName);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kBrand.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: kBrand, size: 28),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Kamera',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ambil foto langsung',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // [Gallery (1%)]: Pilih foto dari Galeri HP
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pop(context);
                      final fileName = 'dokumen_galeri_${DateTime.now().millisecondsSinceEpoch}.png';
                      widget.onMediaSelected('Gallery', fileName);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.photo_library, color: Color(0xFF2563EB), size: 28),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Gallery',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pilih dari galeri foto',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
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

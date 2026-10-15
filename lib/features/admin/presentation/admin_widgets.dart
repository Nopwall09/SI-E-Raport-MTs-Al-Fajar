import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/widgets/error_view.dart';
import '../../../widgets/motion.dart';

/// Spinner saat pertama memuat, pesan error bila gagal tanpa data lama,
/// selain itu null (tampilkan isi). Data lama tetap tampil saat refresh.
Widget? statusAsync(AsyncValue<Object?> v, VoidCallback ulangi) {
  if (v.hasValue) return null;
  if (v.hasError) {
    return Center(
      child: ErrorView(
        message: AppException.from(v.error!).message,
        onRetry: ulangi,
      ),
    );
  }
  return const ListSkeleton();
}

/// Menjalankan simpan ke server. Sukses -> snackbar [sukses] dan true;
/// gagal -> snackbar pesan error dan false (form tetap terbuka).
Future<bool> simpan(
  BuildContext context,
  Future<void> Function() aksi,
  String sukses,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await aksi();
    messenger.showSnackBar(SnackBar(content: Text(sukses)));
    return true;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(AppException.from(e).message)),
    );
    return false;
  }
}

/// Dialog konfirmasi. true bila dilanjutkan. [berbahaya] mewarnai tombol aksi
/// merah (untuk hapus).
Future<bool> konfirmasiAksi(
  BuildContext context, {
  required String judul,
  required String isi,
  required String aksi,
  bool berbahaya = false,
}) async {
  final ya = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(judul),
      content: Text(isi),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        TextButton(
          style: berbahaya
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(aksi),
        ),
      ],
    ),
  );
  return ya ?? false;
}

/// Konfirmasi aksi yang tidak bisa dibatalkan.
Future<bool> konfirmasiHapus(
  BuildContext context, {
  required String judul,
  required String isi,
}) => konfirmasiAksi(
  context,
  judul: judul,
  isi: isi,
  aksi: 'Hapus',
  berbahaya: true,
);

/// Dua tombol di dasar sheet detail: Hapus (outline) dan Ubah (utama).
class AksiUbahHapus extends StatelessWidget {
  const AksiUbahHapus({
    super.key,
    required this.onUbah,
    this.onHapus,
    this.hapusLabel = 'Hapus',
  });

  final VoidCallback onUbah;
  final VoidCallback? onHapus;
  final String hapusLabel;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Row(
      children: [
        if (onHapus != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: error,
                side: BorderSide(color: error.withValues(alpha: 0.5)),
              ),
              onPressed: onHapus,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(hapusLabel),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: FilledButton.icon(
            onPressed: onUbah,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Ubah'),
          ),
        ),
      ],
    );
  }
}

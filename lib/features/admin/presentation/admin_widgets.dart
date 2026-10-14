import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/widgets/error_view.dart';

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
  return const Center(child: CircularProgressIndicator());
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
    messenger.showSnackBar(SnackBar(content: Text(AppException.from(e).message)));
    return false;
  }
}

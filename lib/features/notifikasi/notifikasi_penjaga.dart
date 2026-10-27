import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../auth/presentation/auth_controller.dart';
import 'notifikasi_providers.dart';
import 'notifikasi_rute.dart';

/// Menyalakan notifikasi begitu pengguna siap memakai aplikasi (sudah masuk
/// dan tidak sedang dipaksa ganti password). Penghentiannya ada di
/// `AuthController.logout`, karena harus terjadi sebelum sesi berakhir.
class NotifikasiPenjaga extends ConsumerStatefulWidget {
  const NotifikasiPenjaga({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotifikasiPenjaga> createState() => _NotifikasiPenjagaState();
}

class _NotifikasiPenjagaState extends ConsumerState<NotifikasiPenjaga> {
  String? _aktifUntuk;

  @override
  void initState() {
    super.initState();
    ref.listenManual(authControllerProvider, (_, auth) {
      final user = auth.value;
      final id = user != null && !user.mustChangePassword ? user.id : null;
      if (id == _aktifUntuk) return;
      _aktifUntuk = id;
      if (id != null) {
        ref
            .read(notifikasiServiceProvider)
            .mulai(saatDiketuk: _buka, saatMasuk: _tampilkanBanner);
      }
    }, fireImmediately: true);
  }

  void _buka(PesanNotifikasi pesan) {
    final rute = ruteNotifikasi(pesan, ref.read(authControllerProvider).value);
    if (rute != null) ref.read(routerProvider).go(rute);
  }

  // Aplikasi sedang terbuka: banner kecil, tidak mengganggu layar yang dipakai.
  void _tampilkanBanner(PesanNotifikasi pesan) {
    final pesanBanner = [pesan.judul, pesan.isi].whereType<String>().join('\n');
    pesanKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(pesanBanner),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(label: 'Lihat', onPressed: () => _buka(pesan)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

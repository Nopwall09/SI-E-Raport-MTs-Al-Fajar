import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:si_e_rapor_mts_al_fajar/widgets/qr_code_widget.dart';

void main() {
  testWidgets('QrCodeWidget aman dipakai di dalam AlertDialog', (tester) async {
    // QrImageView memakai LayoutBuilder; AlertDialog menghitung ukuran
    // intrinsik anaknya. Tanpa ukuran pasti, dialog QR crash.
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [QrCodeWidget(data: 'ALFAJAR|SISWA|1|VII-A')],
                ),
              ),
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('dialog QR menampilkan rincian dan isi QR terbaca', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => tampilkanDialogQr(
              context,
              judul: 'Kartu Pelajar Digital',
              nama: 'Zidan Al-Mubarak',
              info: const [('NIS', '2026007'), ('Kelas', 'IX-A')],
              isiQr: 'Nama: Zidan Al-Mubarak\nNIS: 2026007\nKelas: IX-A',
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Zidan Al-Mubarak'), findsOneWidget);
    expect(find.text('2026007'), findsOneWidget);
    expect(find.text('IX-A'), findsOneWidget);
    final qr = tester.widget<QrCodeWidget>(find.byType(QrCodeWidget));
    expect(qr.data, contains('NIS: 2026007'));
    expect(qr.data, contains('Kelas: IX-A'));
  });
}

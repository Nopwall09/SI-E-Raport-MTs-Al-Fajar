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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si_e_rapor_mts_al_fajar/app/app.dart';

import 'helpers/test_overrides.dart';

Future<void> _login(WidgetTester tester, String username) async {
  await tester.pumpWidget(
    ProviderScope(overrides: testOverrides(), child: const EraporApp()),
  );
  await tester.pumpAndSettle();

  await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'), username);
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'), 'rahasia');
  await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tanpa sesi, aplikasi membuka layar login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: testOverrides(), child: const EraporApp()),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Masuk'), findsOneWidget);
  });

  testWidgets('guru biasa masuk ke beranda tanpa tab wali kelas',
      (tester) async {
    await _login(tester, 'guru');

    expect(find.text('Halo, Guru Contoh'), findsOneWidget);
    expect(find.text('Nilai'), findsWidgets);
    expect(find.text('Wali kelas'), findsNothing);
  });

  testWidgets('guru wali kelas melihat tab wali kelas', (tester) async {
    await _login(tester, 'walikelas');

    expect(find.text('Halo, Guru Wali Kelas'), findsOneWidget);
    expect(find.text('Wali kelas'), findsWidgets);
  });

  testWidgets('password salah menampilkan pesan dan tetap di login',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: testOverrides(), child: const EraporApp()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'), 'tidak-ada');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'x');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Username atau password salah.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Masuk'), findsOneWidget);
  });
}

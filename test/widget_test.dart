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
    find.widgetWithText(TextFormField, 'Username'),
    username,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    'rahasia',
  );
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

  testWidgets('guru biasa hanya melihat dashboard guru mapel', (tester) async {
    await _login(tester, 'guru');

    expect(find.text('Halo, Guru Contoh'), findsOneWidget);
    expect(find.text('Nilai'), findsWidgets);
    expect(find.textContaining('Wali Kelas'), findsNothing);
  });

  testWidgets('guru wali kelas melihat dashboard gabungan di beranda', (
    tester,
  ) async {
    await _login(tester, 'walikelas');

    expect(find.text('Halo, Guru Wali Kelas'), findsOneWidget);
    expect(find.textContaining('Wali Kelas 7A'), findsWidgets);
    expect(find.text('Siswa kelas 7A'), findsOneWidget);
    expect(find.text('Kelengkapan kelas'), findsOneWidget);

    // Gulir ke bagian detail wali kelas di dalam list
    await tester.scrollUntilVisible(
      find.text('Progres Nilai Kelas 7A (Wali Kelas)'),
      300,
    );
    expect(find.text('Progres Nilai Kelas 7A (Wali Kelas)'), findsOneWidget);
    expect(find.text('Siswa Contoh A'), findsOneWidget);
  });

  testWidgets('password salah menampilkan pesan dan tetap di login', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(overrides: testOverrides(), child: const EraporApp()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'tidak-ada',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'x');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Username atau password salah.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Masuk'), findsOneWidget);
  });

  testWidgets('wali murid masuk dan melihat halaman perkembangan anak', (
    tester,
  ) async {
    await _login(tester, 'wali');

    expect(find.text('Perkembangan Anak'), findsWidgets);
    expect(find.text('Muhammad Farhan Al-Ghifari'), findsOneWidget);
    expect(find.text('Grafik Perkembangan Berkala'), findsOneWidget);
  });

  testWidgets(
    'siswa memakai halaman perkembangan yang sama dengan wali murid',
    (tester) async {
      await _login(tester, 'siswa');

      expect(find.text('Perkembangan Saya'), findsWidgets);
      expect(find.text('Muhammad Farhan Al-Ghifari'), findsOneWidget);
      expect(find.text('Rapor'), findsNothing);
    },
  );
}

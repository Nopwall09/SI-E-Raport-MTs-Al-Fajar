import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si_e_rapor_mts_al_fajar/core/error/app_exception.dart';
import 'package:si_e_rapor_mts_al_fajar/core/storage/token_storage.dart';
import 'package:si_e_rapor_mts_al_fajar/features/auth/domain/user.dart';
import 'package:si_e_rapor_mts_al_fajar/features/auth/presentation/auth_controller.dart';

import '../../helpers/test_overrides.dart';

void main() {
  ProviderContainer makeContainer([InMemoryTokenStorage? storage]) {
    final container =
        ProviderContainer(overrides: testOverrides(storage: storage));
    addTearDown(container.dispose);
    return container;
  }

  test('tanpa token tersimpan, pengguna belum masuk', () async {
    final container = makeContainer();
    expect(await container.read(authControllerProvider.future), isNull);
  });

  test('login guru biasa bukan wali kelas', () async {
    final container = makeContainer();
    await container.read(authControllerProvider.future);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'guru', password: 'rahasia');

    final user = container.read(authControllerProvider).value;
    expect(user?.role, UserRole.guru);
    expect(user?.isWaliKelas, isFalse);
  });

  test('login guru yang merangkap wali kelas', () async {
    final container = makeContainer();
    await container.read(authControllerProvider.future);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'walikelas', password: 'rahasia');

    final user = container.read(authControllerProvider).value;
    expect(user?.role, UserRole.guru);
    expect(user?.isWaliKelas, isTrue);
    expect(user?.waliKelas?.namaKelas, '7A');
  });

  test('login gagal melempar AppException unauthorized', () async {
    final container = makeContainer();
    await container.read(authControllerProvider.future);

    await expectLater(
      container
          .read(authControllerProvider.notifier)
          .login(username: 'tidak-ada', password: 'x'),
      throwsA(
        isA<AppException>()
            .having((e) => e.type, 'type', AppErrorType.unauthorized),
      ),
    );
    expect(container.read(authControllerProvider).value, isNull);
  });

  test('sesi tersimpan dipulihkan saat aplikasi dibuka lagi', () async {
    final storage = InMemoryTokenStorage();
    await storage.write('fake:siswa');
    final container = makeContainer(storage);

    final user = await container.read(authControllerProvider.future);

    expect(user?.role, UserRole.siswa);
  });

  test('logout menghapus sesi dan token', () async {
    final storage = InMemoryTokenStorage();
    final container = makeContainer(storage);
    await container.read(authControllerProvider.future);
    final notifier = container.read(authControllerProvider.notifier);

    await notifier.login(username: 'wali', password: 'rahasia');
    await notifier.logout();

    expect(container.read(authControllerProvider).value, isNull);
    expect(await storage.read(), isNull);
  });
}

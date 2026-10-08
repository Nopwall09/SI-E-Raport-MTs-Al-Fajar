import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:si_e_rapor_mts_al_fajar/features/auth/data/fake_auth_repository.dart';
import 'package:si_e_rapor_mts_al_fajar/features/auth/presentation/auth_controller.dart';

/// Override standar untuk test: repository contoh tanpa jeda, sehingga tidak
/// menyentuh Supabase maupun jaringan. `signedInAs` meniru sesi tersimpan.
List<Override> testOverrides({String? signedInAs}) {
  return [
    authRepositoryProvider.overrideWithValue(
      FakeAuthRepository(latency: Duration.zero, signedInAs: signedInAs),
    ),
  ];
}

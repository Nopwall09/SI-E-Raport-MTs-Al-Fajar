import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:si_e_rapor_mts_al_fajar/core/providers.dart';
import 'package:si_e_rapor_mts_al_fajar/core/storage/token_storage.dart';
import 'package:si_e_rapor_mts_al_fajar/features/auth/data/fake_auth_repository.dart';
import 'package:si_e_rapor_mts_al_fajar/features/auth/presentation/auth_controller.dart';

/// Override standar untuk test: token di memori dan repository contoh
/// tanpa jeda, sehingga tidak menyentuh platform channel maupun jaringan.
List<Override> testOverrides({InMemoryTokenStorage? storage}) {
  final tokenStorage = storage ?? InMemoryTokenStorage();
  return [
    tokenStorageProvider.overrideWithValue(tokenStorage),
    authRepositoryProvider.overrideWithValue(
      FakeAuthRepository(tokenStorage: tokenStorage, latency: Duration.zero),
    ),
  ];
}

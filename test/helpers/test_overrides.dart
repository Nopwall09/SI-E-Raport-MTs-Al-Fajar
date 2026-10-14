import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:si_e_rapor_mts_al_fajar/features/admin/data/admin_repository.dart';
import 'package:si_e_rapor_mts_al_fajar/features/admin/presentation/admin_providers.dart';
import 'package:si_e_rapor_mts_al_fajar/features/auth/data/fake_auth_repository.dart';
import 'package:si_e_rapor_mts_al_fajar/features/auth/presentation/auth_controller.dart';
import 'package:si_e_rapor_mts_al_fajar/features/nilai/data/nilai_repository.dart';
import 'package:si_e_rapor_mts_al_fajar/features/nilai/presentation/nilai_providers.dart';

/// Override standar untuk test: repository contoh tanpa jeda, sehingga tidak
/// menyentuh Supabase maupun jaringan. `signedInAs` meniru sesi tersimpan.
/// Data beranda guru (tahun ajaran dan progres nilai) diganti data kosong.
List<Override> testOverrides({String? signedInAs}) {
  return [
    authRepositoryProvider.overrideWithValue(
      FakeAuthRepository(latency: Duration.zero, signedInAs: signedInAs),
    ),
    tahunAjaranAktifProvider.overrideWith(
      (ref) async => const TahunAjaranAktif(1, '2026/2027', 'ganjil'),
    ),
    progresPenugasanProvider.overrideWith(
      (ref) async => const <PenugasanProgres>[],
    ),
  ];
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/providers.dart';
import '../../../models/dashboard_model.dart';
import '../../../models/guru_model.dart';
import '../../../models/kelas_model.dart';
import '../../../models/siswa_model.dart';
import '../../../models/user_model.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  if (Env.useFakeApi) {
    throw StateError('Fitur admin butuh Supabase. Jalankan dengan '
        '--dart-define-from-file=env.json');
  }
  return AdminRepository(ref.watch(supabaseClientProvider));
});

final tahunAjaranAktifProvider = FutureProvider.autoDispose<TahunAjaranAktif>(
    (ref) => ref.watch(adminRepositoryProvider).tahunAjaranAktif());

final adminStatistikProvider = FutureProvider.autoDispose<DashboardStatistik>(
    (ref) => ref.watch(adminRepositoryProvider).statistik());

final adminProgresProvider =
    FutureProvider.autoDispose<List<ProgressInputNilai>>(
        (ref) => ref.watch(adminRepositoryProvider).progresInputNilai());

final adminSiswaProvider = FutureProvider.autoDispose<List<SiswaModel>>(
    (ref) => ref.watch(adminRepositoryProvider).daftarSiswa());

final adminGuruProvider = FutureProvider.autoDispose<List<GuruModel>>(
    (ref) => ref.watch(adminRepositoryProvider).daftarGuru());

final adminKelasProvider = FutureProvider.autoDispose<List<KelasModel>>(
    (ref) => ref.watch(adminRepositoryProvider).daftarKelas());

final adminPenggunaProvider = FutureProvider.autoDispose<List<UserModel>>(
    (ref) => ref.watch(adminRepositoryProvider).daftarPengguna());

final opsiKelasProvider = FutureProvider.autoDispose<List<Opsi>>(
    (ref) => ref.watch(adminRepositoryProvider).opsiKelas());

final opsiGuruProvider = FutureProvider.autoDispose<List<Opsi>>(
    (ref) => ref.watch(adminRepositoryProvider).opsiGuru());

final opsiWaliMuridProvider = FutureProvider.autoDispose<List<Opsi>>(
    (ref) => ref.watch(adminRepositoryProvider).opsiWaliMurid());

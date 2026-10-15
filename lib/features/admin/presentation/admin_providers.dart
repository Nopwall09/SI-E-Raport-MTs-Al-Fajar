import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/providers.dart';
import '../../../models/dashboard_model.dart';
import '../../../models/data_rapor_model.dart';
import '../../../models/guru_model.dart';
import '../../../models/kelas_model.dart';
import '../../../models/siswa_model.dart';
import '../../../models/user_model.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  if (Env.useFakeApi) {
    throw StateError(
      'Fitur admin butuh Supabase. Jalankan tanpa '
      '--dart-define=USE_FAKE_API=true.',
    );
  }
  return AdminRepository(ref.watch(supabaseClientProvider));
});

final tahunAjaranAktifProvider = FutureProvider<TahunAjaranAktif>(
  (ref) => ref.watch(adminRepositoryProvider).tahunAjaranAktif(),
);

final adminStatistikProvider = FutureProvider<DashboardStatistik>(
  (ref) => ref.watch(adminRepositoryProvider).statistik(),
);

final adminProgresProvider = FutureProvider<List<ProgressInputNilai>>(
  (ref) => ref.watch(adminRepositoryProvider).progresInputNilai(),
);

final adminSiswaProvider = FutureProvider<List<SiswaModel>>(
  (ref) => ref.watch(adminRepositoryProvider).daftarSiswa(),
);

final adminGuruProvider = FutureProvider<List<GuruModel>>(
  (ref) => ref.watch(adminRepositoryProvider).daftarGuru(),
);

final adminKelasProvider = FutureProvider<List<KelasModel>>(
  (ref) => ref.watch(adminRepositoryProvider).daftarKelas(),
);

final adminPenggunaProvider = FutureProvider<List<UserModel>>(
  (ref) => ref.watch(adminRepositoryProvider).daftarPengguna(),
);

final adminRaporProvider =
    FutureProvider.family<
      List<DataRaporModel>,
      ({int kelasId, String kelasNama, String semester})
    >(
      (ref, k) => ref
          .watch(adminRepositoryProvider)
          .daftarRapor(
            kelasId: k.kelasId,
            kelasNama: k.kelasNama,
            semester: k.semester,
          ),
    );

final opsiKelasProvider = FutureProvider<List<Opsi>>(
  (ref) => ref.watch(adminRepositoryProvider).opsiKelas(),
);

final opsiGuruProvider = FutureProvider<List<Opsi>>(
  (ref) => ref.watch(adminRepositoryProvider).opsiGuru(),
);

final opsiWaliMuridProvider = FutureProvider<List<Opsi>>(
  (ref) => ref.watch(adminRepositoryProvider).opsiWaliMurid(),
);

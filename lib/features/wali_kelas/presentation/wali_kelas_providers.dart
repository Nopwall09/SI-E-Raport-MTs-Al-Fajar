import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../admin/presentation/admin_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/wali_kelas_repository.dart';

final waliKelasRepositoryProvider = Provider<WaliKelasRepository>((ref) {
  return WaliKelasRepository(ref.watch(supabaseClientProvider));
});

final progresKelasProvider = FutureProvider<List<SiswaProgres>>((ref) async {
  // Bergantung pada pengguna agar data akun sebelumnya tidak terbawa.
  ref.watch(authControllerProvider.select((u) => u.value?.id));
  final kelas = ref.watch(authControllerProvider).value?.waliKelas;
  if (kelas == null) return const [];
  final ta = await ref.watch(tahunAjaranAktifProvider.future);
  return ref
      .watch(waliKelasRepositoryProvider)
      .progres(kelasId: kelas.kelasId, semester: ta.semester);
});



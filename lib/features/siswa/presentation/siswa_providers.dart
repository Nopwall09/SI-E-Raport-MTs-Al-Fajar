import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../admin/data/admin_repository.dart';
import '../../admin/presentation/admin_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/siswa_repository.dart';

final siswaRepositoryProvider = Provider<SiswaRepository>((ref) {
  return SiswaRepository(ref.watch(supabaseClientProvider));
});

/// Pilihan semester yang sedang dilihat oleh siswa ('ganjil' atau 'genap').
final siswaSemesterFilterProvider = StateProvider<String>((ref) => 'ganjil');

/// Provider data rapor siswa berdasarkan semester yang dipilih.
final siswaRaporProvider = FutureProvider<RaporSiswaModel>((ref) async {
  // Bergantung pada user yang login agar tidak tercampur saat ganti akun
  ref.watch(authControllerProvider.select((u) => u.value?.id));
  final semester = ref.watch(siswaSemesterFilterProvider);

  final ta = await ref.watch(tahunAjaranAktifProvider.future).catchError(
        (_) => const TahunAjaranAktif(1, '2026/2027', 'ganjil'),
      );

  return ref.watch(siswaRepositoryProvider).getRaporSiswa(
        semester: semester,
        tahunAjaranId: ta.id,
      );
});


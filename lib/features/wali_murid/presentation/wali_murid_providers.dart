import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../admin/data/admin_repository.dart';
import '../../admin/presentation/admin_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/wali_murid_repository.dart';

final waliMuridRepositoryProvider = Provider<WaliMuridRepository>((ref) {
  return WaliMuridRepository(ref.watch(supabaseClientProvider));
});

final perkembanganAnakProvider = FutureProvider<List<AnakModel>>((ref) async {
  // Bergantung pada user yang login agar tidak bercampur antar akun
  ref.watch(authControllerProvider.select((u) => u.value?.id));

  final ta = await ref.watch(tahunAjaranAktifProvider.future).catchError(
        (_) => const TahunAjaranAktif(1, '2026/2027', 'ganjil'),
      );

  return ref.watch(waliMuridRepositoryProvider).getPerkembanganAnak(
        semester: ta.semester,
        tahunAjaranId: ta.id,
      );
});


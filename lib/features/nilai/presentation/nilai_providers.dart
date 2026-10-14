import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../admin/presentation/admin_providers.dart';
import '../data/nilai_repository.dart';

final nilaiRepositoryProvider = Provider<NilaiRepository>(
    (ref) => NilaiRepository(ref.watch(supabaseClientProvider)));

final penugasanSayaProvider = FutureProvider<List<Penugasan>>((ref) async {
  final ta = await ref.watch(tahunAjaranAktifProvider.future);
  return ref.watch(nilaiRepositoryProvider).penugasanSaya(ta.id);
});

/// Kunci provider: kelas dan mapel yang sedang dibuka.
typedef KelasMapel = ({int kelasId, int mapelId});

final siswaNilaiProvider =
    FutureProvider.autoDispose.family<List<SiswaNilai>, KelasMapel>((ref, k) async {
  final ta = await ref.watch(tahunAjaranAktifProvider.future);
  return ref.watch(nilaiRepositoryProvider).siswaDanNilai(
        kelasId: k.kelasId,
        mapelId: k.mapelId,
        semester: ta.semester,
      );
});

final progresPenugasanProvider =
    FutureProvider<List<PenugasanProgres>>((ref) async {
  final ta = await ref.watch(tahunAjaranAktifProvider.future);
  return ref
      .watch(nilaiRepositoryProvider)
      .progres(tahunAjaranId: ta.id, semester: ta.semester);
});

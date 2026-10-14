import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../../widgets/motion.dart';
import '../../admin/presentation/admin_providers.dart';
import '../../admin/presentation/admin_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/wali_kelas_repository.dart';

final progresKelasProvider = FutureProvider<List<SiswaProgres>>((ref) async {
  final kelas = ref.watch(authControllerProvider).value?.waliKelas;
  if (kelas == null) return const [];
  final ta = await ref.watch(tahunAjaranAktifProvider.future);
  return WaliKelasRepository(ref.watch(supabaseClientProvider))
      .progres(kelasId: kelas.kelasId, semester: ta.semester);
});

/// Tab "Wali kelas": progres nilai UTS tiap siswa di kelas wali.
class WaliKelasPage extends ConsumerWidget {
  const WaliKelasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kelas = ref.watch(authControllerProvider).value?.waliKelas;
    final data = ref.watch(progresKelasProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Kelas ${kelas?.namaKelas ?? ''}')),
      body: statusAsync(data, () => ref.invalidate(progresKelasProvider)) ??
          RefreshIndicator(
            color: kBrand,
            onRefresh: () async {
              ref.invalidate(progresKelasProvider);
              try {
                await ref.read(progresKelasProvider.future);
              } catch (_) {}
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: data.value!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => FadeSlideIn(
                index: i,
                child: _KartuSiswa(data.value![i]),
              ),
            ),
          ),
    );
  }
}

class _KartuSiswa extends StatelessWidget {
  const _KartuSiswa(this.s);

  final SiswaProgres s;

  @override
  Widget build(BuildContext context) {
    final total = s.mapel.length;
    final lengkap = total > 0 && s.terisi == total;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kBorder),
        boxShadow: kCardShadow,
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(s.nama, style: theme.textTheme.titleSmall),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : s.terisi / total,
                      minHeight: 6,
                      color: kBrand,
                      backgroundColor: kField,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${s.terisi}/$total mapel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: lengkap ? kBrand : kMuted,
                  ),
                ),
              ],
            ),
          ),
          children: [
            for (final m in s.mapel)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(child: Text(m.mapel)),
                    Text(
                      m.nilai == null
                          ? 'Belum'
                          : (m.nilai! % 1 == 0
                              ? m.nilai!.toInt().toString()
                              : m.nilai.toString()),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: m.nilai == null ? kMuted : kText,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

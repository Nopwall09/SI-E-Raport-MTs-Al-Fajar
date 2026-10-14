import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../widgets/motion.dart';
import '../../admin/presentation/admin_providers.dart';
import '../../admin/presentation/admin_widgets.dart';
import '../data/nilai_repository.dart';
import 'input_nilai_page.dart';
import 'nilai_providers.dart';

/// Tab "Nilai" guru: daftar kelas dan mapel yang diampu semester ini.
class NilaiPage extends ConsumerWidget {
  const NilaiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar = ref.watch(penugasanSayaProvider);
    final periode = ref.watch(tahunAjaranAktifProvider).valueOrNull?.label;

    return Scaffold(
      appBar: AppBar(title: const Text('Nilai')),
      body:
          statusAsync(daftar, () => ref.invalidate(penugasanSayaProvider)) ??
          RefreshIndicator(
            color: kBrand,
            onRefresh: () async {
              ref.invalidate(penugasanSayaProvider);
              try {
                await ref.read(penugasanSayaProvider.future);
              } catch (_) {}
            },
            child: daftar.value!.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    children: const [
                      SizedBox(height: 80),
                      Text(
                        'Belum ada kelas yang Anda ampu semester ini. '
                        'Hubungi Admin TU.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kMuted),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: daftar.value!.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Input nilai UTS${periode == null ? '' : ', $periode'}',
                            style: const TextStyle(color: kMuted),
                          ),
                        );
                      }
                      final p = daftar.value![i - 1];
                      return FadeSlideIn(
                        index: i,
                        child: PressScale(child: _KartuPenugasan(p)),
                      );
                    },
                  ),
          ),
    );
  }
}

class _KartuPenugasan extends StatelessWidget {
  const _KartuPenugasan(this.p);

  final Penugasan p;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(kRadiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadiusCard),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => InputNilaiPage(penugasan: p))),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusCard),
            border: Border.all(color: kBorder),
            boxShadow: kCardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kBrandSoft,
                  borderRadius: BorderRadius.circular(kRadiusControl),
                ),
                child: Text(
                  p.kelas,
                  style: const TextStyle(
                    color: kBrand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.mapel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kelas ${p.kelas}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: kMuted),
            ],
          ),
        ),
      ),
    );
  }
}

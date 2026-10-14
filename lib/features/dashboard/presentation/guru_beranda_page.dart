import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../widgets/motion.dart';
import '../../../widgets/stat_card_widget.dart';
import '../../admin/presentation/admin_providers.dart';
import '../../admin/presentation/admin_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../nilai/data/nilai_repository.dart';
import '../../nilai/presentation/input_nilai_page.dart';
import '../../nilai/presentation/nilai_providers.dart';

/// Beranda guru: sapaan, ringkasan, dan progres input nilai tiap kelas-mapel.
class GuruBerandaPage extends ConsumerWidget {
  const GuruBerandaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final periode = ref.watch(tahunAjaranAktifProvider).valueOrNull?.label;
    final data = ref.watch(progresPenugasanProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: statusAsync(data, () => ref.invalidate(progresPenugasanProvider)) ??
          RefreshIndicator(
            color: kBrand,
            onRefresh: () async {
              ref.invalidate(progresPenugasanProvider);
              try {
                await ref.read(progresPenugasanProvider.future);
              } catch (_) {}
            },
            child: _isi(context, theme, user?.name ?? '',
                user?.waliKelas?.namaKelas, periode, data.value!),
          ),
    );
  }

  Widget _isi(BuildContext context, ThemeData theme, String nama,
      String? waliKelas, String? periode, List<PenugasanProgres> daftar) {
    final terisi = daftar.fold<int>(0, (a, p) => a + p.terisi);
    final total = daftar.fold<int>(0, (a, p) => a + p.total);
    final kelas = {for (final p in daftar) p.penugasan.kelasId}.length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        FadeSlideIn(
          child: Text('Halo, $nama', style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: 4),
        Text(
          [
            if (waliKelas != null) 'Wali kelas $waliKelas',
            ?periode,
          ].join(', '),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 128,
          child: Row(
            children: [
              Expanded(
                child: StatCardWidget(
                  title: 'Kelas diampu',
                  count: '$kelas',
                  icon: Icons.meeting_room_outlined,
                  index: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCardWidget(
                  title: 'Nilai terisi',
                  count: '$terisi/$total',
                  icon: Icons.edit_note_outlined,
                  index: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Progres input nilai', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        if (daftar.isEmpty)
          const Text(
            'Belum ada kelas yang Anda ampu semester ini. Hubungi Admin TU.',
            style: TextStyle(color: kMuted),
          ),
        for (var i = 0; i < daftar.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FadeSlideIn(
              index: i + 3,
              child: PressScale(child: _KartuProgres(daftar[i])),
            ),
          ),
      ],
    );
  }
}

class _KartuProgres extends StatelessWidget {
  const _KartuProgres(this.p);

  final PenugasanProgres p;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lengkap = p.total > 0 && p.terisi == p.total;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(kRadiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadiusCard),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => InputNilaiPage(penugasan: p.penugasan),
        )),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusCard),
            border: Border.all(color: kBorder),
            boxShadow: kCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('${p.penugasan.mapel}, ${p.penugasan.kelas}',
                        style: theme.textTheme.titleSmall),
                  ),
                  Text(
                    '${p.terisi}/${p.total}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: lengkap ? kBrand : kMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween(
                    begin: 0, end: p.total == 0 ? 0 : p.terisi / p.total),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 6,
                    color: kBrand,
                    backgroundColor: kField,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

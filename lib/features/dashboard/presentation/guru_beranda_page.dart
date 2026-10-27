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
import '../../wali_kelas/data/wali_kelas_repository.dart';
import '../../wali_kelas/presentation/wali_kelas_providers.dart';
import '../../wali_murid/presentation/wali_murid_page.dart';
import '../../wali_murid/presentation/wali_murid_providers.dart';

/// Beranda guru terpadu: sapaan, ringkasan guru mapel, serta progres nilai kelas
/// bagi guru yang juga merangkap sebagai wali kelas.
class GuruBerandaPage extends ConsumerWidget {
  const GuruBerandaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final periode = ref.watch(tahunAjaranAktifProvider).valueOrNull?.label;
    final penugasanAsync = ref.watch(progresPenugasanProvider);
    final isWaliKelas = user?.isWaliKelas ?? false;
    final progresKelasAsync =
        isWaliKelas ? ref.watch(progresKelasProvider) : null;
    final anakAsync = ref.watch(perkembanganAnakProvider);
    final theme = Theme.of(context);

    // Cek loading status untuk penugasan utama
    final statusPenugasan = statusAsync(
      penugasanAsync,
      () => ref.invalidate(progresPenugasanProvider),
    );
    if (statusPenugasan != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Beranda')),
        body: statusPenugasan,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: RefreshIndicator(
        color: kBrand,
        onRefresh: () async {
          ref.invalidate(progresPenugasanProvider);
          if (isWaliKelas) ref.invalidate(progresKelasProvider);
          ref.invalidate(perkembanganAnakProvider);
          try {
            await ref.read(progresPenugasanProvider.future);
            if (isWaliKelas) await ref.read(progresKelasProvider.future);
          } catch (_) {}
        },
        child: _isi(
          context: context,
          theme: theme,
          nama: user?.name ?? '',
          waliKelas: user?.waliKelas?.namaKelas,
          periode: periode,
          daftarPenugasan: penugasanAsync.value ?? const [],
          daftarSiswaKelas: progresKelasAsync?.valueOrNull,
          anakList: anakAsync.valueOrNull,
        ),
      ),
    );
  }

  Widget _isi({
    required BuildContext context,
    required ThemeData theme,
    required String nama,
    required String? waliKelas,
    required String? periode,
    required List<PenugasanProgres> daftarPenugasan,
    required List<SiswaProgres>? daftarSiswaKelas,
    required List<dynamic>? anakList,
  }) {
    final isWaliKelas = waliKelas != null;

    // Hitungan statistik guru mapel
    final terisiMapel =
        daftarPenugasan.fold<int>(0, (a, p) => a + p.terisi);
    final totalMapel =
        daftarPenugasan.fold<int>(0, (a, p) => a + p.total);
    final kelasDiampu =
        {for (final p in daftarPenugasan) p.penugasan.kelasId}.length;

    // Hitungan statistik wali kelas (jika merangkap)
    final siswaWali = daftarSiswaKelas ?? const <SiswaProgres>[];
    final totalSiswa = siswaWali.length;
    final totalMapelWali =
        siswaWali.fold<int>(0, (a, s) => a + s.mapel.length);
    final terisiMapelWali =
        siswaWali.fold<int>(0, (a, s) => a + s.terisi);
    final siswaLengkap = siswaWali
        .where((s) => s.mapel.isNotEmpty && s.terisi == s.mapel.length)
        .length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        // Sapaan dan Peran
        FadeSlideIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Halo, $nama', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                [
                  if (isWaliKelas)
                    'Guru Mapel & Wali Kelas $waliKelas'
                  else
                    'Guru Mata Pelajaran',
                  ?periode,
                ].join(' · '),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),

        // Banner pintasan peran Wali Murid (jika user juga memiliki anak di madrasah)
        if (anakList != null && anakList.isNotEmpty) ...[
          const SizedBox(height: 14),
          FadeSlideIn(
            index: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kBrandSoft,
                borderRadius: BorderRadius.circular(kRadiusControl),
                border: Border.all(color: kBrand.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.family_restroom, color: kBrand, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peran Wali Murid',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kBrand,
                            fontSize: 12.5,
                          ),
                        ),
                        Text(
                          'Pantau perkembangan anak Anda secara berkala',
                          style: TextStyle(fontSize: 11.5, color: kText),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WaliMuridPage(),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kBrand,
                            fontSize: 12.5,
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 16, color: kBrand),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Statistik Guru Mapel
        SizedBox(
          height: statCardHeight(context),
          child: Row(
            children: [
              Expanded(
                child: StatCardWidget(
                  title: 'Kelas diampu',
                  count: '$kelasDiampu',
                  icon: Icons.meeting_room_outlined,
                  index: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCardWidget(
                  title: 'Nilai Anda terisi',
                  count: '$terisiMapel/$totalMapel',
                  icon: Icons.edit_note_outlined,
                  index: 2,
                ),
              ),
            ],
          ),
        ),

        // Statistik Tambahan Wali Kelas (jika merangkap)
        if (isWaliKelas) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: statCardHeight(context),
            child: Row(
              children: [
                Expanded(
                  child: StatCardWidget(
                    title: 'Siswa kelas $waliKelas',
                    count: '$totalSiswa siswa',
                    icon: Icons.groups_outlined,
                    index: 3,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCardWidget(
                    title: 'Kelengkapan kelas',
                    count: '$terisiMapelWali/$totalMapelWali',
                    icon: Icons.assignment_turned_in_outlined,
                    index: 4,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // ================= BAGIAN 1: GURU MAPEL =================
        Row(
          children: [
            const Icon(Icons.edit_note_outlined, size: 20, color: kBrand),
            const SizedBox(width: 8),
            Text('Progres Input Nilai Mapel', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Mata pelajaran yang Anda ampu semester ini',
          style: TextStyle(fontSize: 12, color: kMuted),
        ),
        const SizedBox(height: 12),
        if (daftarPenugasan.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Belum ada kelas yang Anda ampu semester ini. Hubungi Admin TU.',
              style: TextStyle(color: kMuted),
            ),
          )
        else
          for (var i = 0; i < daftarPenugasan.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FadeSlideIn(
                index: i + 3,
                child: PressScale(child: _KartuProgres(daftarPenugasan[i])),
              ),
            ),

        // ================= BAGIAN 2: WALI KELAS =================
        if (isWaliKelas) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.groups_outlined, size: 20, color: kBrand),
              const SizedBox(width: 8),
              Text(
                'Progres Nilai Kelas $waliKelas (Wali Kelas)',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Kelengkapan nilai seluruh siswa kelas Anda dari seluruh guru mapel',
            style: const TextStyle(fontSize: 12, color: kMuted),
          ),
          const SizedBox(height: 12),

          // Ringkasan kelengkapan kelas
          if (totalSiswa > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(kRadiusControl),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    siswaLengkap == totalSiswa
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    color: siswaLengkap == totalSiswa ? kBrand : const Color(0xFFD97706),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$siswaLengkap dari $totalSiswa siswa memiliki nilai lengkap dari semua mapel.',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          if (siswaWali.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(kRadiusCard),
                border: Border.all(color: kBorder),
              ),
              child: Text(
                'Belum ada data siswa di kelas $waliKelas.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: kMuted),
              ),
            )
          else
            for (var i = 0; i < siswaWali.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FadeSlideIn(
                  index: i + 6,
                  child: _KartuSiswaWali(siswaWali[i]),
                ),
              ),
        ],
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
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InputNilaiPage(penugasan: p.penugasan),
          ),
        ),
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
                    child: Text(
                      '${p.penugasan.mapel}, ${p.penugasan.kelas}',
                      style: theme.textTheme.titleSmall,
                    ),
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
                  begin: 0,
                  end: p.total == 0 ? 0 : p.terisi / p.total,
                ),
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

class _KartuSiswaWali extends StatelessWidget {
  const _KartuSiswaWali(this.s);

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

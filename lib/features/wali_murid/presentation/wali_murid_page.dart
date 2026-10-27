import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../widgets/motion.dart';
import '../../../widgets/trend_chart_widget.dart';
import '../../admin/presentation/admin_providers.dart';
import '../../admin/presentation/admin_widgets.dart';
import '../../auth/domain/user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/wali_murid_repository.dart';
import 'wali_murid_providers.dart';

/// Halaman utama Wali Murid untuk memantau perkembangan anak secara berkala.
class WaliMuridPage extends ConsumerStatefulWidget {
  const WaliMuridPage({super.key});

  @override
  ConsumerState<WaliMuridPage> createState() => _WaliMuridPageState();
}

class _WaliMuridPageState extends ConsumerState<WaliMuridPage> {
  int _selectedChildIndex = 0;
  String _selectedSemester = 'ganjil';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final ta = ref.watch(tahunAjaranAktifProvider).valueOrNull;
    final dataAsync = ref.watch(perkembanganAnakProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          user?.role == UserRole.siswa ? 'Perkembangan Saya' : 'Perkembangan Anak',
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan data',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(perkembanganAnakProvider),
          ),
        ],
      ),
      body: statusAsync(
            dataAsync,
            () => ref.invalidate(perkembanganAnakProvider),
          ) ??
          RefreshIndicator(
            color: kBrand,
            onRefresh: () async {
              ref.invalidate(perkembanganAnakProvider);
              try {
                await ref.read(perkembanganAnakProvider.future);
              } catch (_) {}
            },
            child: _buildBody(
              context: context,
              theme: theme,
              waliName: user?.name ?? 'Orang Tua',
              periode: ta?.label,
              anakList: dataAsync.value ?? const [],
            ),
          ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required ThemeData theme,
    required String waliName,
    required String? periode,
    required List<AnakModel> anakList,
  }) {
    if (anakList.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.family_restroom, size: 64, color: kMuted),
          SizedBox(height: 16),
          Text(
            'Belum ada data siswa yang terhubung dengan akun wali murid ini.\n'
            'Silakan hubungi Admin TU untuk menghubungkan data anak.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, height: 1.5),
          ),
        ],
      );
    }

    final currentIndex = _selectedChildIndex.clamp(0, anakList.length - 1);
    final anak = anakList[currentIndex];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Sapaan Orang Tua
        FadeSlideIn(
          index: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Halo, $waliName', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Memantau perkembangan belajar berkala ${periode ?? "Semester Berjalan"}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Pemilih Anak (jika lebih dari 1 anak)
        if (anakList.length > 1) ...[
          FadeSlideIn(
            index: 1,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < anakList.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selectedColor: kBrandSoft,
                        side: BorderSide(
                          color: _selectedChildIndex == i ? kBrand : kBorder,
                        ),
                        label: Text(
                          anakList[i].nama,
                          style: TextStyle(
                            fontWeight: _selectedChildIndex == i
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: _selectedChildIndex == i ? kBrand : kText,
                          ),
                        ),
                        selected: _selectedChildIndex == i,
                        onSelected: (val) {
                          if (val) setState(() => _selectedChildIndex = i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Kartu Identitas Siswa
        FadeSlideIn(
          index: 2,
          child: _KartuIdentitasSiswa(anak: anak),
        ),

        const SizedBox(height: 14),

        // Filter Semester
        FadeSlideIn(
          index: 3,
          child: _buildFilterBar(),
        ),

        const SizedBox(height: 14),

        // Kartu Grafik Tren Perkembangan Berkala
        FadeSlideIn(
          index: 4,
          child: _KartuGrafikPerkembangan(anak: anak),
        ),

        const SizedBox(height: 16),

        // Catatan Perkembangan & Kehadiran dari Wali Kelas
        FadeSlideIn(
          index: 5,
          child: _KartuCatatanKehadiran(anak: anak),
        ),

        const SizedBox(height: 16),

        // Tabel Nilai Mata Pelajaran
        FadeSlideIn(
          index: 6,
          child: _KartuDaftarNilai(anak: anak),
        ),

        const SizedBox(height: 20),

        // Tombol Cetak / Unduh Rapor
        FadeSlideIn(
          index: 7,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: kBrand, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadiusControl),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Mengunduh lembar laporan perkembangan ${anak.nama}...',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf_outlined, color: kBrand),
            label: const Text(
              'Unduh Laporan Perkembangan (PDF)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: kBrand,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusControl),
        border: Border.all(color: kBorder),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined, size: 18, color: kBrand),
          const SizedBox(width: 10),
          const Text(
            'Periode:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSemester,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: kBrand),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kText,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'ganjil',
                  child: Text('Semester 1 (Ganjil)'),
                ),
                DropdownMenuItem(
                  value: 'genap',
                  child: Text('Semester 2 (Genap)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedSemester = val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KartuIdentitasSiswa extends StatelessWidget {
  const _KartuIdentitasSiswa({required this.anak});

  final AnakModel anak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kBorder),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: kBrandSoft,
            child: Text(
              anak.nama.isNotEmpty ? anak.nama[0] : 'S',
              style: const TextStyle(
                color: kBrand,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anak.nama,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _BadgeInfo(text: 'Kelas ${anak.kelas}'),
                    _BadgeInfo(
                      text: anak.nisn != null && anak.nisn!.isNotEmpty
                          ? 'NISN ${anak.nisn}'
                          : 'NIS ${anak.nis}',
                    ),
                    if (anak.waliKelas != null)
                      _BadgeInfo(
                        text: 'Wali: ${anak.waliKelas}',
                        highlight: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeInfo extends StatelessWidget {
  const _BadgeInfo({required this.text, this.highlight = false});

  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight ? kBrandSoft : kField,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: highlight ? kBrand : kMuted,
        ),
      ),
    );
  }
}

class _KartuGrafikPerkembangan extends StatelessWidget {
  const _KartuGrafikPerkembangan({required this.anak});

  final AnakModel anak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rata = anak.rataRata;
    final h = anak.historiPerkembangan;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kBorder),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rata-rata Nilai Siswa',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: kMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        rata == null ? '-' : rata.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: kBrand,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (rata != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            anak.predikat,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: kBrandSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: kBrand,
                  size: 24,
                ),
              ),
            ],
          ),

          if (h.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: kBorder),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.show_chart, size: 16, color: kBrand),
                const SizedBox(width: 6),
                Text(
                  'Grafik Perkembangan Berkala',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (h.length > 1 && h.last >= h.first)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: kBrandSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Tren Positif ↑',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: kBrand,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TrendChartWidget(
              values: h,
              labels: anak.labelPerkembangan.isNotEmpty
                  ? anak.labelPerkembangan
                  : [for (var i = 1; i <= h.length; i++) '$i'],
            ),
          ],
        ],
      ),
    );
  }
}

class _KartuCatatanKehadiran extends StatelessWidget {
  const _KartuCatatanKehadiran({required this.anak});

  final AnakModel anak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kBorder),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over_outlined,
                  size: 18, color: kBrand),
              const SizedBox(width: 8),
              const Text(
                'Catatan Wali Kelas',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const Spacer(),
              // Ringkasan Kehadiran
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kField,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Kehadiran: S ${anak.sakit} · I ${anak.izin} · A ${anak.alpa}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: kText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBrandSoft.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(kRadiusControl),
              border: Border.all(color: kBrand.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote, color: kBrand, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    anak.catatanWali ?? 'Belum ada catatan dari wali kelas.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: kText,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KartuDaftarNilai extends StatelessWidget {
  const _KartuDaftarNilai({required this.anak});

  final AnakModel anak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kBorder),
        boxShadow: kCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.menu_book_outlined, size: 18, color: kBrand),
                const SizedBox(width: 8),
                Text(
                  'Rincian Nilai Mata Pelajaran',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (anak.daftarNilai.isNotEmpty)
                  Text(
                    'SKM: ${anak.daftarNilai.first.skm}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: kMuted,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: kField,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Mata Pelajaran',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Nilai',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Keterangan',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (anak.daftarNilai.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Belum ada nilai untuk semester ini.',
                  style: TextStyle(color: kMuted, fontSize: 12.5),
                ),
              ),
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: anak.daftarNilai.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: kBorder),
            itemBuilder: (context, i) {
              final n = anak.daftarNilai[i];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.mapel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kText,
                            ),
                          ),
                          Text(
                            n.kategori,
                            style: const TextStyle(fontSize: 11, color: kMuted),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          n.nilai == null
                              ? '-'
                              : (n.nilai! % 1 == 0
                                  ? n.nilai!.toInt().toString()
                                  : n.nilai.toString()),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: n.nilai != null && n.nilai! >= n.skm
                                ? kBrand
                                : const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: n.nilai == null
                                ? kField
                                : (n.isTuntas
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEF3C7)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            n.statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: n.nilai == null
                                  ? kMuted
                                  : (n.isTuntas
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB45309)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


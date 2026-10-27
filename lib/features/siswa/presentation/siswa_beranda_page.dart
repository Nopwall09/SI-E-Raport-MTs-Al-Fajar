import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../widgets/motion.dart';
import '../../../widgets/trend_chart_widget.dart';
import '../../admin/presentation/admin_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/siswa_repository.dart';
import 'lembar_rapor_dialog.dart';
import 'siswa_providers.dart';

/// Halaman Beranda khusus untuk akun Siswa.
/// Memberikan ringkasan akademik cepat, peringkat kelas, grafik tren perkembangan,
/// dan akses instan untuk mengunduh lembar rapor digital.
class SiswaBerandaPage extends ConsumerWidget {
  const SiswaBerandaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final raporAsync = ref.watch(siswaRaporProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda Siswa'),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(siswaRaporProvider),
          ),
        ],
      ),
      body: statusAsync(raporAsync, () => ref.invalidate(siswaRaporProvider)) ??
          RefreshIndicator(
            color: kBrand,
            onRefresh: () async {
              ref.invalidate(siswaRaporProvider);
              try {
                await ref.read(siswaRaporProvider.future);
              } catch (_) {}
            },
            child: _buildBody(
              context: context,
              namaSiswa: user?.name ?? 'Siswa',
              rapor: raporAsync.value!,
            ),
          ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required String namaSiswa,
    required RaporSiswaModel rapor,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // 1. SAPAAN & PROFIL SINGKAT
        FadeSlideIn(
          index: 0,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(color: kBorder),
              boxShadow: kCardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: kBrandSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: kBrand.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.school, color: kBrand, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assalamu’alaikum,',
                        style: const TextStyle(fontSize: 12, color: kMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        namaSiswa,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelas ${rapor.profil.kelas} • Semester ${rapor.semester}',
                        style: const TextStyle(fontSize: 12, color: kBrand, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. KARTU UTAMA: PERINGKAT & STATUS KELULUSAN
        FadeSlideIn(
          index: 1,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D5C3A), Color(0xFF1B8A5A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(kRadiusCard),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D5C3A).withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.military_tech, color: Colors.amber, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Prestasi Akademik',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Tahun Ajaran ${rapor.tahunAjaran}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Peringkat ${rapor.peringkat}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'dari ${rapor.totalSiswaKelas} Siswa di Kelas',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 48,
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${rapor.rataRata}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Rata-rata Nilai UTS',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Status Ketuntasan
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          rapor.statusKelulusan,
                          style: const TextStyle(
                            color: Color(0xFF0D5C3A),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. AKSES CEPAT: UNDUH RAPOR DIGITAL & LIHAT SEMUA NILAI
        FadeSlideIn(
          index: 2,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => LembarRaporDialog.show(context, rapor),
                  borderRadius: BorderRadius.circular(kRadiusCard),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(kRadiusCard),
                      border: Border.all(color: kBorder),
                      boxShadow: kCardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Unduh Rapor',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: kText,
                                ),
                              ),
                              Text(
                                'Format PDF Resmi',
                                style: TextStyle(fontSize: 10.5, color: kMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => context.go('/siswa/rapor'),
                  borderRadius: BorderRadius.circular(kRadiusCard),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(kRadiusCard),
                      border: Border.all(color: kBorder),
                      boxShadow: kCardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kBrandSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bar_chart, color: kBrand, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Riwayat Nilai',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: kText,
                                ),
                              ),
                              Text(
                                'Per Mata Pelajaran',
                                style: TextStyle(fontSize: 10.5, color: kMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 4. GRAFIK TREN PERKEMBANGAN BELAJAR
        FadeSlideIn(
          index: 3,
          child: Container(
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
                  children: const [
                    Text(
                      'Tren Perkembangan Nilai Siswa',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: kText,
                      ),
                    ),
                    Text(
                      'Semester Ganjil',
                      style: TextStyle(fontSize: 11, color: kMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const TrendChartWidget(
                  values: [82.0, 84.5, 85.0, 86.8, 87.8],
                  labels: ['UH 1', 'UH 2', 'PTS', 'UH 3', 'PAS'],
                  height: 95,
                ),
                const SizedBox(height: 8),
                const Text(
                  '* Grafik menunjukkan konsistensi tren kenaikan nilai ulangan harian dan evaluasi tengah semester.',
                  style: TextStyle(fontSize: 10.5, color: kMuted, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 5. MATA PELAJARAN UNGGULAN (TOP NILAI)
        FadeSlideIn(
          index: 4,
          child: Container(
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
                  children: [
                    const Text(
                      'Capaian Nilai Tertinggi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: kText,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => context.go('/siswa/rapor'),
                      child: const Text('Semua Mapel', style: TextStyle(color: kBrand, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Top 3 Mapel
                for (final mapel in rapor.daftarNilai.take(3)) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kField,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          mapel.kode ?? 'MAPEL',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: kBrand,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mapel.mapel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kText,
                              ),
                            ),
                            Text(
                              mapel.predikatTeks,
                              style: const TextStyle(fontSize: 11, color: kMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        mapel.nilai?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}


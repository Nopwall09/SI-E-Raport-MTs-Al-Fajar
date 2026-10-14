import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../widgets/motion.dart';
import '../../features/admin/presentation/admin_providers.dart';
import '../../features/admin/presentation/admin_widgets.dart';
import '../../models/dashboard_model.dart';
import '../../widgets/stat_card_widget.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statistik = ref.watch(adminStatistikProvider);
    final progres = ref.watch(adminProgresProvider);
    final periode = ref.watch(tahunAjaranAktifProvider).valueOrNull?.label ?? '';
    final nama = ref.watch(authControllerProvider).value?.name ?? '';
    final status = statusAsync(statistik, () {
      ref.invalidate(adminStatistikProvider);
      ref.invalidate(adminProgresProvider);
    }) ?? statusAsync(progres, () => ref.invalidate(adminProgresProvider));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: kText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: status ?? _isi(context, ref, statistik.value!, progres.value!, periode, nama),
    );
  }

  Widget _isi(BuildContext context, WidgetRef ref, DashboardStatistik s,
      List<ProgressInputNilai> daftar, String periode, String nama) {
    const brandColor = kBrand;
    return SafeArea(
        child: RefreshIndicator(
          color: kBrand,
          onRefresh: () async {
            ref.invalidate(adminStatistikProvider);
            ref.invalidate(adminProgresProvider);
            try {
              await ref.read(adminStatistikProvider.future);
            } catch (_) {}
          },
          child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(child: _Sambutan(nama: nama, periode: periode)),
              const SizedBox(height: 16),
              // 2x2 Grid Statistik (Siswa, Guru, Kelas, Orang Tua)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  StatCardWidget(
                    index: 1,
                    title: 'Siswa',
                    count: '${s.totalSiswa}',
                    icon: Icons.school_outlined,
                  ),
                  StatCardWidget(
                    index: 2,
                    title: 'Guru',
                    count: '${s.totalGuru}',
                    icon: Icons.person_outline,
                  ),
                  StatCardWidget(
                    index: 3,
                    title: 'Kelas',
                    count: '${s.totalKelas}',
                    icon: Icons.meeting_room_outlined,
                  ),
                  StatCardWidget(
                    index: 4,
                    title: 'Orang Tua',
                    count: '${s.totalOrangTua}',
                    icon: Icons.family_restroom_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Section Header: Progres input nilai
              const Text(
                    'Progres input nilai',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kText,
                    ),
                  ),

              const SizedBox(height: 12),

              // List Kartu Progres
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: daftar.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = daftar[index];
                  final isCompleted = item.persen >= 100;

                  return FadeSlideIn(
                    index: index,
                    child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(kRadiusCard),
                      border: Border.all(
                        color: isCompleted
                            ? kBrand.withValues(alpha: 0.4)
                            : kBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: kField,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          'Kelas ${item.kelas}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: kText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${item.mapel} · ${item.namaGuru}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? kBrandSoft
                                    : kField,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isCompleted
                                      ? kBrand.withValues(alpha: 0.4)
                                      : kBorder,
                                ),
                              ),
                              child: Text(
                                '${item.persen}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? kBrand
                                      : kText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: item.persen / 100),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 6,
                            backgroundColor: kBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted
                                  ? kBrand
                                  : (item.persen >= 75
                                      ? brandColor
                                      : (item.persen >= 50
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFFEF4444))),
                            ),
                          ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
        ),
      );
  }
}


/// Kepala dashboard: sapaan dan periode aktif. Satu-satunya blok berlatar
/// penuh, supaya mata mendarat di sini dulu.
class _Sambutan extends StatelessWidget {
  const _Sambutan({required this.nama, required this.periode});

  final String nama;
  final String periode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kRadiusCard),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kBrand, Color(0xFF167A50)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x330D5C3A), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selamat datang',
            style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            nama,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          if (periode.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x29FFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                periode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final status = statusAsync(statistik, () {
      ref.invalidate(adminStatistikProvider);
      ref.invalidate(adminProgresProvider);
    }) ?? statusAsync(progres, () => ref.invalidate(adminProgresProvider));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 1,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF64748B)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tidak ada notifikasi baru.')),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: status ?? _isi(context, statistik.value!, progres.value!, periode),
    );
  }

  Widget _isi(BuildContext context, DashboardStatistik s,
      List<ProgressInputNilai> daftar, String periode) {
    const brandColor = Color(0xFF0D5C3A);
    return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    title: 'Siswa',
                    count: '${s.totalSiswa}',
                    icon: Icons.school_outlined,
                    accentColor: const Color(0xFF0D5C3A),
                  ),
                  StatCardWidget(
                    title: 'Guru',
                    count: '${s.totalGuru}',
                    icon: Icons.person_outline,
                    accentColor: const Color(0xFF2563EB),
                  ),
                  StatCardWidget(
                    title: 'Kelas',
                    count: '${s.totalKelas}',
                    icon: Icons.meeting_room_outlined,
                    accentColor: const Color(0xFFD97706),
                  ),
                  StatCardWidget(
                    title: 'Orang Tua',
                    count: '${s.totalOrangTua}',
                    icon: Icons.family_restroom_outlined,
                    accentColor: const Color(0xFF7C3AED),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Section Header: Progres input nilai
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progres input nilai',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    periode,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
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

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompleted
                            ? const Color(0xFF86EFAC)
                            : Colors.grey.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          'Kelas ${item.kelas}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF334155),
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
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isCompleted
                                      ? const Color(0xFF86EFAC)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                '[ ${item.persen}% ]',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: item.persen / 100,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted
                                  ? const Color(0xFF10B981)
                                  : (item.persen >= 75
                                      ? brandColor
                                      : (item.persen >= 50
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFFEF4444))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      );
  }
}

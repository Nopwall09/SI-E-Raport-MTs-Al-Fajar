import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/presentation/auth_controller.dart';

class AdminMenuDrawer extends ConsumerWidget {
  final String currentRoute;

  const AdminMenuDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: const Color(0xFFF1F5F9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Drawer (Sesuai Wireframe)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'e-Rapor MTs Al Fajar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Admin/TU/Kurikulum',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Daftar Menu Sesuai Wireframe
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                children: [
                  _buildMenuItem(
                    context: context,
                    label: 'Dashboard',
                    route: '/admin/beranda',
                    isActive: currentRoute == '/admin/beranda',
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    context: context,
                    label: 'Pengguna',
                    route: '/admin/pengguna',
                    isActive: currentRoute == '/admin/pengguna',
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    context: context,
                    label: 'Data Siswa',
                    route: '/admin/siswa',
                    isActive: currentRoute == '/admin/siswa',
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    context: context,
                    label: 'Data Guru',
                    route: '/admin/guru',
                    isActive: currentRoute == '/admin/guru',
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    context: context,
                    label: 'Data Kelas',
                    route: '/admin/kelas',
                    isActive: currentRoute == '/admin/kelas',
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    context: context,
                    label: 'Mata Pelajaran',
                    route: '/admin/mapel',
                    isActive: currentRoute == '/admin/mapel',
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    context: context,
                    label: 'Tahun Ajaran',
                    route: '/admin/tahun-ajaran',
                    isActive: currentRoute == '/admin/tahun-ajaran',
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    context: context,
                    label: 'Data Rapor',
                    route: '/admin/rapor',
                    isActive: currentRoute == '/admin/rapor',
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    context: context,
                    label: 'Keluar',
                    route: '/logout',
                    isActive: false,
                    isLogout: true,
                    onTap: () => _showLogoutDialog(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String label,
    required String route,
    required bool isActive,
    bool isLogout = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap ??
            () {
              Navigator.of(context).pop();
              if (currentRoute != route) {
                context.go(route);
              }
            },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF1E293B)
                  : (isLogout
                      ? const Color(0xFFFECACA)
                      : const Color(0xFFCBD5E1)),
              width: 1.2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              color: isActive
                  ? Colors.white
                  : (isLogout ? Colors.red.shade700 : const Color(0xFF334155)),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pop(); // close drawer
              ref.read(authControllerProvider.notifier).logout();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/widgets/placeholder_page.dart';
import '../features/auth/domain/user.dart';
import '../features/auth/presentation/profile_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';

/// Satu tab = satu cabang navigasi bawah milik sebuah role.
class AppTab {
  const AppTab({
    required this.slug,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
    this.onlyWaliKelas = false,
  });

  final String slug;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function() builder;

  /// Tab hanya tampil untuk guru yang juga wali kelas.
  final bool onlyWaliKelas;
}

AppTab _beranda() => AppTab(
      slug: 'beranda',
      label: 'Beranda',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      builder: () => const DashboardPage(),
    );

AppTab _profil() => AppTab(
      slug: 'profil',
      label: 'Profil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      builder: () => const ProfilePage(),
    );

AppTab _segera({
  required String slug,
  required String label,
  required IconData icon,
  required IconData selectedIcon,
  required int sprint,
  bool onlyWaliKelas = false,
}) =>
    AppTab(
      slug: slug,
      label: label,
      icon: icon,
      selectedIcon: selectedIcon,
      onlyWaliKelas: onlyWaliKelas,
      builder: () => PlaceholderPage(title: label, sprint: sprint),
    );

/// Daftar tab per role. Admin sengaja minim: pekerjaan admin ada di web.
List<AppTab> tabsFor(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return [_beranda(), _profil()];
    case UserRole.guru:
      return [
        _beranda(),
        _segera(
          slug: 'nilai',
          label: 'Nilai',
          icon: Icons.edit_note_outlined,
          selectedIcon: Icons.edit_note,
          sprint: 2,
        ),
        _segera(
          slug: 'wali-kelas',
          label: 'Wali kelas',
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups,
          sprint: 2,
          onlyWaliKelas: true,
        ),
        _profil(),
      ];
    case UserRole.siswa:
      return [
        _beranda(),
        _segera(
          slug: 'rapor',
          label: 'Rapor',
          icon: Icons.description_outlined,
          selectedIcon: Icons.description,
          sprint: 3,
        ),
        _profil(),
      ];
    case UserRole.waliMurid:
      return [
        _beranda(),
        _segera(
          slug: 'anak',
          label: 'Anak',
          icon: Icons.family_restroom_outlined,
          selectedIcon: Icons.family_restroom,
          sprint: 3,
        ),
        _profil(),
      ];
  }
}

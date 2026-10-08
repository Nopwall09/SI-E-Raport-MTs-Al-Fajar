import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import 'role_tabs.dart';

class RoleShell extends ConsumerWidget {
  const RoleShell({
    super.key,
    required this.navigationShell,
    required this.tabs,
  });

  final StatefulNavigationShell navigationShell;
  final List<AppTab> tabs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWaliKelas =
        ref.watch(authControllerProvider).value?.isWaliKelas ?? false;

    // Indeks cabang yang boleh tampil. Cabang wali kelas tetap terdaftar di
    // router, tetapi disembunyikan dari navigasi bila bukan wali kelas.
    final visible = [
      for (var i = 0; i < tabs.length; i++)
        if (!tabs[i].onlyWaliKelas || isWaliKelas) i,
    ];
    final selected = visible.indexOf(navigationShell.currentIndex);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected < 0 ? 0 : selected,
        onDestinationSelected: (index) => navigationShell.goBranch(
          visible[index],
          initialLocation: index == selected,
        ),
        destinations: [
          for (final i in visible)
            NavigationDestination(
              icon: Icon(tabs[i].icon),
              selectedIcon: Icon(tabs[i].selectedIcon),
              label: tabs[i].label,
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/user.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/splash_page.dart';
import 'role_shell.dart';
import 'role_tabs.dart';

/// Aturan arah halaman, dipisah supaya mudah diuji.
///
/// - Sedang memeriksa sesi atau gagal memeriksa: tahan di /splash
/// - Belum masuk: paksa ke /login
/// - Sudah masuk: arahkan ke beranda role-nya, dan tolak area role lain
/// - Tab wali kelas hanya untuk guru yang menjadi wali kelas
@visibleForTesting
String? redirectFor(AsyncValue<AppUser?> auth, String location) {
  if (auth.isLoading || auth.hasError) {
    return location == '/splash' ? null : '/splash';
  }

  final user = auth.value;
  if (user == null) {
    return location == '/login' ? null : '/login';
  }

  if (location == '/splash' || location == '/login') return user.homePath;
  if (!location.startsWith(user.role.basePath)) return user.homePath;
  if (location.startsWith('${user.role.basePath}/wali-kelas') &&
      !user.isWaliKelas) {
    return user.homePath;
  }
  return null;
}

StatefulShellRoute _roleShell(UserRole role) {
  final tabs = tabsFor(role);
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        RoleShell(navigationShell: navigationShell, tabs: tabs),
    branches: [
      for (final tab in tabs)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '${role.basePath}/${tab.slug}',
              builder: (context, state) => tab.builder(),
            ),
          ],
        ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  // go_router tidak tahu Riverpod, jadi state login diteruskan lewat notifier.
  final refresh = ValueNotifier<int>(0);
  ref.listen<AsyncValue<AppUser?>>(
    authControllerProvider,
    (previous, next) => refresh.value++,
  );

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) =>
        redirectFor(ref.read(authControllerProvider), state.matchedLocation),
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      for (final role in UserRole.values) _roleShell(role),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

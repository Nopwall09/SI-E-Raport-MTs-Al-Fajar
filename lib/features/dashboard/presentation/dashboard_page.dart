import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null) ...[
            Text('Halo, ${user.name}', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(user.role.label),
            if (user.isWaliKelas) Text('Wali kelas ${user.waliKelas!.namaKelas}'),
          ],
          const SizedBox(height: 24),
          const Text(
            'Ringkasan akan tampil di sini setelah fitur penilaian dan rapor selesai.',
          ),
        ],
      ),
    );
  }
}

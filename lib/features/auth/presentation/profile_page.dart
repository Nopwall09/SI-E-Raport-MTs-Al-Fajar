import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null) ...[
            Text(user.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(user.role.label),
            if (user.isWaliKelas) Text('Wali kelas ${user.waliKelas!.namaKelas}'),
          ],
          const SizedBox(height: 32),
          FilledButton.tonal(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

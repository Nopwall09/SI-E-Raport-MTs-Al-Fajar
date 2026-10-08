import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class EraporApp extends ConsumerWidget {
  const EraporApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'E-Raport MTs Al Fajar',
      theme: buildTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

import 'package:flutter/material.dart';

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1F5C4A));
  return ThemeData(useMaterial3: true, colorScheme: scheme);
}

<<<<<<< HEAD
﻿import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env.dart';
=======
import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
>>>>>>> origin/Dimas

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

<<<<<<< HEAD
  if (!Env.useFakeApi) {
    if (Env.supabaseUrl.isEmpty || Env.supabasePublishableKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY wajib diisi lewat --dart-define '
        'saat USE_FAKE_API=false.',
      );
    }
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
=======
  @override
  Widget build(BuildContext context) {
    const brandPrimary = Color(0xFF0D5C3A); // Islamic Emerald Green MTs Al-Fajar

    return MaterialApp(
      title: 'SI e-Raport MTs Al-Fajar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandPrimary,
          primary: brandPrimary,
          surface: const Color(0xFFF8FAF9),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAF9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
      home: const LoginPage(),
>>>>>>> origin/Dimas
    );
  }

  runApp(const ProviderScope(child: EraporApp()));
}

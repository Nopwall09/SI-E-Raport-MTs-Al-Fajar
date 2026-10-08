import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    );
  }

  runApp(const ProviderScope(child: EraporApp()));
}

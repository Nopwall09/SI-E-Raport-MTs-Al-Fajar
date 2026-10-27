import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  unawaited(_spikeFcm());
}

/// SPIKE (sementara, jangan di-merge): tidak boleh menahan runApp.
Future<void> _spikeFcm() async {
  try {
    await Firebase.initializeApp();
    debugPrint('FCM_INIT=ok');
    final fcm = FirebaseMessaging.instance;
    final izin = await fcm.requestPermission();
    debugPrint('FCM_IZIN=${izin.authorizationStatus}');
    debugPrint('FCM_TOKEN=${await fcm.getToken()}');
    FirebaseMessaging.onMessage.listen(
      (m) => debugPrint(
        'FCM_FOREGROUND=${m.notification?.title}|${m.notification?.body}',
      ),
    );
    FirebaseMessaging.onMessageOpenedApp.listen(
      (m) => debugPrint('FCM_DIKETUK=${m.notification?.title}|${m.data}'),
    );
  } catch (e, st) {
    debugPrint('FCM_ERROR=$e $st');
  }
}

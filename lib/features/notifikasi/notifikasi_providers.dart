import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/providers.dart';
import 'notifikasi_service.dart';

/// Test dan `USE_FAKE_API` memakai `NotifikasiKosong` (tanpa Firebase).
final notifikasiServiceProvider = Provider<NotifikasiService>((ref) {
  if (Env.useFakeApi) return const NotifikasiKosong();
  return NotifikasiFirebase(ref.watch(supabaseClientProvider));
});

/// Dipakai `MaterialApp.router` agar banner notifikasi bisa tampil dari luar
/// pohon layar.
final pesanKey = GlobalKey<ScaffoldMessengerState>();

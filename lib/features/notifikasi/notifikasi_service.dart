import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notifikasi_rute.dart';

/// Pendaftaran perangkat dan penerimaan notifikasi. Gagal atau ditolaknya
/// izin tidak boleh mengganggu aplikasi, jadi implementasi tidak melempar.
abstract class NotifikasiService {
  /// Dipanggil sesudah masuk (dan ganti password selesai).
  Future<void> mulai({
    required void Function(PesanNotifikasi) saatDiketuk,
    required void Function(PesanNotifikasi) saatMasuk,
  });

  /// Dipanggil SEBELUM keluar, selagi sesi masih berlaku (RLS butuh itu untuk
  /// menghapus token). Supaya akun berikutnya di HP ini tidak menerima
  /// notifikasi akun lama.
  Future<void> berhenti();
}

/// Untuk tes dan `USE_FAKE_API`: tidak menyentuh Firebase.
class NotifikasiKosong implements NotifikasiService {
  const NotifikasiKosong();

  @override
  Future<void> mulai({
    required void Function(PesanNotifikasi) saatDiketuk,
    required void Function(PesanNotifikasi) saatMasuk,
  }) async {}

  @override
  Future<void> berhenti() async {}
}

class NotifikasiFirebase implements NotifikasiService {
  NotifikasiFirebase(this._db);

  final SupabaseClient _db;
  final _langganan = <StreamSubscription<Object?>>[];
  String? _token;

  @override
  Future<void> mulai({
    required void Function(PesanNotifikasi) saatDiketuk,
    required void Function(PesanNotifikasi) saatMasuk,
  }) async {
    try {
      _batalkan();
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final fcm = FirebaseMessaging.instance;
      final izin = await fcm.requestPermission();
      if (izin.authorizationStatus == AuthorizationStatus.denied) return;

      // ponytail: getToken/onTokenRefresh sudah usang di v17 tetapi terbukti
      // jalan dengan FCM HTTP v1; pindah ke register()/onRegistered nanti.
      // ignore: deprecated_member_use
      await _simpan(await fcm.getToken());
      _langganan
        // ignore: deprecated_member_use
        ..add(fcm.onTokenRefresh.listen(_simpan))
        ..add(FirebaseMessaging.onMessage.listen((m) => saatMasuk(_ubah(m))))
        ..add(
          FirebaseMessaging.onMessageOpenedApp.listen(
            (m) => saatDiketuk(_ubah(m)),
          ),
        );

      final awal = await fcm.getInitialMessage();
      if (awal != null) saatDiketuk(_ubah(awal));
    } catch (e) {
      debugPrint('Notifikasi tidak aktif: $e');
    }
  }

  @override
  Future<void> berhenti() async {
    _batalkan();
    final token = _token;
    _token = null;
    if (token != null) {
      await _db.from('device_token').delete().eq('token', token);
    }
    if (Firebase.apps.isNotEmpty) {
      // ignore: deprecated_member_use
      await FirebaseMessaging.instance.deleteToken();
    }
  }

  Future<void> _simpan(String? token) async {
    if (token == null) return;
    _token = token;
    try {
      await _db.rpc('daftarkan_device_token', params: {'p_token': token});
    } catch (e) {
      debugPrint('Token perangkat belum tersimpan: $e');
    }
  }

  void _batalkan() {
    for (final s in _langganan) {
      s.cancel();
    }
    _langganan.clear();
  }

  PesanNotifikasi _ubah(RemoteMessage m) => PesanNotifikasi(
    judul: m.notification?.title,
    isi: m.notification?.body,
    data: m.data,
  );
}

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:si_e_rapor_mts_al_fajar/core/error/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AppException.from (Postgres)', () {
    test('42501 (ditolak RLS) menjadi forbidden', () {
      final error = AppException.from(
        PostgrestException(message: 'denied', code: '42501'),
      );
      expect(error.type, AppErrorType.forbidden);
    });

    test('P0001 membawa pesan dari trigger sebagai conflict', () {
      final error = AppException.from(
        PostgrestException(
          message: 'Rapor sudah final dan tidak bisa diubah.',
          code: 'P0001',
        ),
      );
      expect(error.type, AppErrorType.conflict);
      expect(error.message, 'Rapor sudah final dan tidak bisa diubah.');
    });

    test('23505 menjadi conflict, 23514 menjadi validation', () {
      expect(
        AppException.from(
          PostgrestException(message: 'dup', code: '23505'),
        ).type,
        AppErrorType.conflict,
      );
      expect(
        AppException.from(
          PostgrestException(message: 'check', code: '23514'),
        ).type,
        AppErrorType.validation,
      );
    });

    test('JWT kedaluwarsa menjadi unauthorized', () {
      final error = AppException.from(
        PostgrestException(message: 'JWT expired', code: 'PGRST301'),
      );
      expect(error.type, AppErrorType.unauthorized);
    });

    test('kode tak dikenal menjadi server', () {
      final error = AppException.from(
        PostgrestException(message: 'boom', code: 'XX000'),
      );
      expect(error.type, AppErrorType.server);
    });
  });

  group('AppException.from (lainnya)', () {
    test('kredensial salah dari Auth menjadi unauthorized', () {
      final error = AppException.from(
        AuthException('Invalid login credentials', statusCode: '400'),
      );
      expect(error.type, AppErrorType.unauthorized);
      expect(error.message, 'Username atau password salah.');
    });

    test('timeout dan socket dibedakan', () {
      expect(
        AppException.from(TimeoutException('lama')).type,
        AppErrorType.timeout,
      );
      expect(
        AppException.from(SocketException('putus')).type,
        AppErrorType.network,
      );
    });

    test('AppException dilewatkan apa adanya', () {
      const original = AppException(AppErrorType.conflict, 'x');
      expect(identical(AppException.from(original), original), isTrue);
    });
  });
}

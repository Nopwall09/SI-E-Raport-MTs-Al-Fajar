import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart';

enum AppErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  validation,
  conflict,
  server,
  unknown,
}

/// Error yang aman ditampilkan ke pengguna. Layar tidak perlu tahu soal
/// Supabase atau Postgres.
///
/// Pemetaan kode Postgres:
///   42501  ditolak RLS (bukan haknya)         -> forbidden
///   P0001  `raise exception` dari trigger/RPC -> conflict (mis. rapor final)
///   23505  nilai unik ganda                   -> conflict
///   23514  melanggar CHECK (mis. nilai 0-100) -> validation
///   PGRST301  JWT kedaluwarsa                 -> unauthorized
class AppException implements Exception {
  const AppException(this.type, this.message);

  final AppErrorType type;
  final String message;

  /// Satu pintu untuk semua error mentah dari lapisan data.
  factory AppException.from(Object error) {
    if (error is AppException) return error;
    if (error is AuthRetryableFetchException) return _network;
    if (error is AuthException) return _fromAuth(error);
    if (error is PostgrestException) return _fromPostgrest(error);
    if (error is TimeoutException) {
      return const AppException(
        AppErrorType.timeout,
        'Server terlalu lama merespons. Coba lagi sebentar lagi.',
      );
    }
    if (error is SocketException) return _network;
    if (error is TypeError || error is FormatException) {
      return const AppException(
        AppErrorType.unknown,
        'Respons server tidak sesuai. Hubungi tim pengembang.',
      );
    }
    return const AppException(
      AppErrorType.unknown,
      'Terjadi kesalahan. Coba lagi.',
    );
  }

  static const _network = AppException(
    AppErrorType.network,
    'Tidak ada koneksi. Periksa internet lalu coba lagi.',
  );

  static AppException _fromAuth(AuthException error) {
    final status = error.statusCode;
    if (status == '400' || status == '401' || status == '422') {
      return const AppException(
        AppErrorType.unauthorized,
        'Username atau password salah.',
      );
    }
    return const AppException(
      AppErrorType.unknown,
      'Terjadi kesalahan saat masuk. Coba lagi.',
    );
  }

  static AppException _fromPostgrest(PostgrestException error) {
    switch (error.code) {
      case '42501':
        return const AppException(
          AppErrorType.forbidden,
          'Kamu tidak punya akses ke data ini.',
        );
      case 'PGRST301':
        return const AppException(
          AppErrorType.unauthorized,
          'Sesi berakhir. Silakan masuk lagi.',
        );
      case 'P0001':
        return AppException(AppErrorType.conflict, error.message);
      case '23505':
        return const AppException(
          AppErrorType.conflict,
          'Data ini sudah ada.',
        );
      case '23514':
        return const AppException(
          AppErrorType.validation,
          'Data belum sesuai aturan. Periksa isian lalu coba lagi.',
        );
      default:
        return const AppException(
          AppErrorType.server,
          'Server sedang bermasalah. Coba lagi nanti.',
        );
    }
  }

  @override
  String toString() => message;
}

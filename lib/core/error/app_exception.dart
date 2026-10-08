import 'dart:io' show SocketException;

import 'package:dio/dio.dart';

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

/// Error yang aman ditampilkan ke pengguna. Layar tidak perlu tahu soal Dio.
///
/// Pemetaan mengikuti konvensi API: 401 sesi habis, 403 ditolak Policy,
/// 409 data sudah dikunci (rapor final), 422 validasi gagal.
class AppException implements Exception {
  const AppException(
    this.type,
    this.message, {
    this.fieldErrors = const {},
  });

  final AppErrorType type;
  final String message;
  final Map<String, List<String>> fieldErrors;

  factory AppException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(
          AppErrorType.timeout,
          'Server terlalu lama merespons. Coba lagi sebentar lagi.',
        );
      case DioExceptionType.connectionError:
        return const AppException(
          AppErrorType.network,
          'Tidak ada koneksi. Periksa internet lalu coba lagi.',
        );
      case DioExceptionType.badResponse:
        return _fromResponse(e.response);
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return const AppException(
            AppErrorType.network,
            'Tidak ada koneksi. Periksa internet lalu coba lagi.',
          );
        }
        return const AppException(
          AppErrorType.unknown,
          'Terjadi kesalahan. Coba lagi.',
        );
    }
  }

  static AppException _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode ?? 0;
    final data = response?.data;
    final serverMessage = _readMessage(data);

    switch (status) {
      case 401:
        return AppException(
          AppErrorType.unauthorized,
          serverMessage ?? 'Sesi berakhir. Silakan masuk lagi.',
        );
      case 403:
        return const AppException(
          AppErrorType.forbidden,
          'Kamu tidak punya akses ke data ini.',
        );
      case 409:
        return AppException(
          AppErrorType.conflict,
          serverMessage ?? 'Data sudah dikunci dan tidak bisa diubah.',
        );
      case 422:
        return AppException(
          AppErrorType.validation,
          serverMessage ?? 'Data belum valid. Periksa isian lalu coba lagi.',
          fieldErrors: _readFieldErrors(data),
        );
      default:
        if (status >= 500) {
          return const AppException(
            AppErrorType.server,
            'Server sedang bermasalah. Coba lagi nanti.',
          );
        }
        return const AppException(
          AppErrorType.unknown,
          'Terjadi kesalahan. Coba lagi.',
        );
    }
  }

  static String? _readMessage(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final message = data['message'];
    return message is String && message.isNotEmpty ? message : null;
  }

  static Map<String, List<String>> _readFieldErrors(Object? data) {
    if (data is! Map<String, dynamic>) return const {};
    final errors = data['errors'];
    if (errors is! Map<String, dynamic>) return const {};
    return {
      for (final entry in errors.entries)
        if (entry.value is List)
          entry.key: [for (final m in entry.value as List) m.toString()],
    };
  }

  @override
  String toString() => message;
}

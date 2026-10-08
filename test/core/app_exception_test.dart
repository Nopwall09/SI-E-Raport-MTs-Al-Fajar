import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si_e_rapor_mts_al_fajar/core/error/app_exception.dart';

DioException _badResponse(int status, [Object? data]) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: data,
    ),
  );
}

void main() {
  group('AppException.fromDio', () {
    test('422 membawa pesan dan error per kolom', () {
      final error = AppException.fromDio(_badResponse(422, {
        'message': 'Data tidak valid',
        'errors': {
          'username': ['Username wajib diisi'],
        },
      }));
      expect(error.type, AppErrorType.validation);
      expect(error.message, 'Data tidak valid');
      expect(error.fieldErrors['username'], ['Username wajib diisi']);
    });

    test('401, 403, 409 dipetakan sesuai konvensi API', () {
      expect(AppException.fromDio(_badResponse(401)).type,
          AppErrorType.unauthorized);
      expect(AppException.fromDio(_badResponse(403)).type,
          AppErrorType.forbidden);
      expect(AppException.fromDio(_badResponse(409)).type,
          AppErrorType.conflict);
    });

    test('5xx dipetakan ke server', () {
      expect(
          AppException.fromDio(_badResponse(503)).type, AppErrorType.server);
    });

    test('timeout dan koneksi putus dibedakan', () {
      final options = RequestOptions(path: '/x');
      expect(
        AppException.fromDio(DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        )).type,
        AppErrorType.timeout,
      );
      expect(
        AppException.fromDio(DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        )).type,
        AppErrorType.network,
      );
    });
  });
}

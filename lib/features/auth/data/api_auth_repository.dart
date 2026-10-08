import 'package:dio/dio.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

/// Kontrak yang diasumsikan (konfirmasi dengan jalur backend):
///
/// POST /auth/login  {username, password, device_name}
///   -> 200 {"data": {"token": "...", "user": {...}}}
/// GET  /auth/me
///   -> 200 {"data": {"id": 1, "name": "...", "role": "guru",
///                    "wali_kelas": null | {"kelas_id": 3, "nama": "7A"}}}
/// POST /auth/logout -> 200/204
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({required Dio dio, required TokenStorage tokenStorage})
      : _dio = dio,
        _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;

  @override
  Future<AppUser> login({
    required String username,
    required String password,
    required String deviceName,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
          'device_name': deviceName,
        },
      );
      final data = _unwrap(response.data);
      final token = data['token'] as String;
      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      await _tokenStorage.write(token);
      return user;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } on TypeError {
      throw _badResponse();
    } on FormatException {
      throw _badResponse();
    }
  }

  @override
  Future<AppUser?> restoreSession() async {
    final token = await _tokenStorage.read();
    if (token == null) return null;

    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return AppUser.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      final error = AppException.fromDio(e);
      if (error.type == AppErrorType.unauthorized) {
        await _tokenStorage.clear();
        return null;
      }
      throw error;
    } on TypeError {
      throw _badResponse();
    } on FormatException {
      throw _badResponse();
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } on DioException {
      // Token lokal tetap dihapus di bawah, apa pun jawaban server.
    } finally {
      await _tokenStorage.clear();
    }
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    final inner = body?['data'];
    if (inner is Map<String, dynamic>) return inner;
    if (body != null) return body;
    throw const FormatException('Respons kosong');
  }

  AppException _badResponse() {
    return const AppException(
      AppErrorType.unknown,
      'Respons server tidak sesuai. Hubungi tim pengembang.',
    );
  }
}

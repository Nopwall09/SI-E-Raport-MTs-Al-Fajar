import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.onUnauthorized,
  });

  final TokenStorage tokenStorage;
  final void Function() onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStorage.read();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 401 pada login berarti username/password salah, bukan sesi habis.
    final isLogin = err.requestOptions.path.endsWith('/auth/login');
    if (err.response?.statusCode == 401 && !isLogin) {
      await tokenStorage.clear();
      onUnauthorized();
    }
    handler.next(err);
  }
}

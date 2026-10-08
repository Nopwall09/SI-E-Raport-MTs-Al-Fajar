import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si_e_rapor_mts_al_fajar/core/network/auth_interceptor.dart';
import 'package:si_e_rapor_mts_al_fajar/core/storage/token_storage.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.statusCode);

  final int statusCode;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      '{"message":"stub"}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_StubAdapter adapter, InMemoryTokenStorage storage, void Function() onExpired) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(
    AuthInterceptor(tokenStorage: storage, onUnauthorized: onExpired),
  );
  return dio;
}

void main() {
  test('menempelkan token sebagai Bearer', () async {
    final storage = InMemoryTokenStorage();
    await storage.write('abc');
    final adapter = _StubAdapter(200);

    await _dio(adapter, storage, () {}).get<dynamic>('/ping');

    expect(adapter.lastRequest!.headers['Authorization'], 'Bearer abc');
  });

  test('401 menghapus token dan memberi sinyal sesi habis', () async {
    final storage = InMemoryTokenStorage();
    await storage.write('abc');
    var expired = 0;

    try {
      await _dio(_StubAdapter(401), storage, () => expired++)
          .get<dynamic>('/auth/me');
    } on DioException {
      // diharapkan
    }

    expect(await storage.read(), isNull);
    expect(expired, 1);
  });

  test('401 pada login tidak dianggap sesi habis', () async {
    final storage = InMemoryTokenStorage();
    await storage.write('abc');
    var expired = 0;

    try {
      await _dio(_StubAdapter(401), storage, () => expired++)
          .post<dynamic>('/auth/login');
    } on DioException {
      // diharapkan
    }

    expect(await storage.read(), 'abc');
    expect(expired, 0);
  });
}

import 'dart:async';

/// Penghubung antara lapisan jaringan dan state login.
///
/// Interceptor memanggil [expire] saat server menjawab 401, dan
/// AuthController mendengarkan [onExpired] untuk kembali ke layar login.
/// Dengan begitu `core` tidak perlu mengimpor fitur auth.
class SessionEvents {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get onExpired => _controller.stream;

  void expire() {
    if (!_controller.isClosed) _controller.add(null);
  }

  void dispose() => _controller.close();
}

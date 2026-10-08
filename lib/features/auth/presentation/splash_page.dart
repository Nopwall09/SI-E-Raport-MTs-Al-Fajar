import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/widgets/error_view.dart';
import 'auth_controller.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final error = auth.error;

    return Scaffold(
      body: Center(
        child: error != null
            ? ErrorView(
                message: error is AppException
                    ? error.message
                    : 'Terjadi kesalahan. Coba lagi.',
                onRetry: () => ref.invalidate(authControllerProvider),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

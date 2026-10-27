import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/error/app_exception.dart';
import 'auth_controller.dart';

const kPasswordMinimal = 8;

/// Ganti password. Wajib (tanpa tombol kembali, hanya bisa keluar) saat akun
/// memakai password awal atau hasil reset; sukarela bila dibuka dari Profil.
class GantiPasswordPage extends ConsumerStatefulWidget {
  const GantiPasswordPage({super.key});

  @override
  ConsumerState<GantiPasswordPage> createState() => _GantiPasswordPageState();
}

class _GantiPasswordPageState extends ConsumerState<GantiPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _baru = TextEditingController();
  final _ulang = TextEditingController();
  bool _submitting = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _baru.dispose();
    _ulang.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final user = await ref
          .read(authControllerProvider.notifier)
          .gantiPassword(_baru.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diganti.')),
      );
      context.go(user.homePath);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wajib =
        ref.watch(authControllerProvider).value?.mustChangePassword ?? false;

    return PopScope(
      canPop: !wajib,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ganti password'),
          automaticallyImplyLeading: !wajib,
          actions: [
            if (wajib)
              TextButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).logout(),
                child: const Text('Keluar'),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    wajib
                        ? 'Demi keamanan, ganti password awal dari sekolah '
                              'sebelum melanjutkan.'
                        : 'Masukkan password baru untuk akun ini.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: kMuted),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _baru,
                    enabled: !_submitting,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Password baru',
                      helperText: 'Minimal $kPasswordMinimal karakter',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscure
                            ? 'Tampilkan password'
                            : 'Sembunyikan password',
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < kPasswordMinimal)
                        ? 'Minimal $kPasswordMinimal karakter'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _ulang,
                    enabled: !_submitting,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Ulangi password baru',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) =>
                        v == _baru.text ? null : 'Password tidak sama',
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(kRadiusControl),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Simpan password'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

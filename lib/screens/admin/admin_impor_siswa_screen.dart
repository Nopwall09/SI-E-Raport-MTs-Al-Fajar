import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/error/app_exception.dart';
import '../../features/admin/data/impor_siswa.dart';
import '../../features/admin/presentation/admin_providers.dart';

/// Batas Edge Function admin-import-siswa per permintaan.
const _ukuranBatch = 100;

/// Impor siswa dari Excel (UC-08): pilih berkas, pratinjau, kirim per batch,
/// lalu laporan per baris. Password awal hanya tampil di sini, sekali.
class AdminImporSiswaScreen extends ConsumerStatefulWidget {
  const AdminImporSiswaScreen({super.key});

  @override
  ConsumerState<AdminImporSiswaScreen> createState() =>
      _AdminImporSiswaScreenState();
}

class _AdminImporSiswaScreenState extends ConsumerState<AdminImporSiswaScreen> {
  String? _namaBerkas;
  List<BarisImpor>? _baris;
  final List<HasilImpor> _hasil = [];
  bool _sibuk = false;
  String? _galat;

  List<BarisSiswa> get _valid => [
    for (final b in _baris ?? const <BarisImpor>[])
      if (b.siswa != null) b.siswa!,
  ];

  /// Baris valid yang belum punya hasil; dasar untuk lanjut setelah gagal di
  /// tengah jalan (server melewati NIS yang sudah ada, jadi aman diulang).
  List<BarisSiswa> get _belum {
    final sudah = {for (final h in _hasil) h.nis};
    return [
      for (final b in _valid)
        if (!sudah.contains(b.nis)) b,
    ];
  }

  Future<void> _pilih() async {
    setState(() => _galat = null);
    try {
      final f = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );
      if (f == null) return;
      final baris = bacaExcelSiswa(await f.readAsBytes());
      setState(() {
        _namaBerkas = f.name;
        _baris = baris;
        _hasil.clear();
      });
    } on FormatException catch (e) {
      setState(() => _galat = e.message);
    } catch (_) {
      setState(() => _galat = 'Berkas tidak bisa dibuka.');
    }
  }

  Future<void> _impor() async {
    setState(() {
      _sibuk = true;
      _galat = null;
    });
    final repo = ref.read(adminRepositoryProvider);
    final antre = _belum;
    try {
      for (var i = 0; i < antre.length; i += _ukuranBatch) {
        final batch = antre.sublist(
          i,
          math.min(i + _ukuranBatch, antre.length),
        );
        final hasil = await repo.imporSiswa(batch);
        if (mounted) setState(() => _hasil.addAll(hasil));
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _galat =
              '${AppException.from(e).message} Tekan "Lanjutkan impor" untuk '
              'melanjutkan sisanya.',
        );
      }
    } finally {
      if (mounted) setState(() => _sibuk = false);
      ref.invalidate(adminSiswaProvider);
      ref.invalidate(adminPenggunaProvider);
      ref.invalidate(adminStatistikProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baris = _baris;
    final salah = [
      for (final b in baris ?? const <BarisImpor>[])
        if (b.galat != null) b,
    ];
    final selesai = baris != null && _hasil.isNotEmpty && _belum.isEmpty;
    final dibuat = _hasil.where((h) => h.status == StatusImpor.dibuat).toList();
    final gagal = _hasil.where((h) => h.status == StatusImpor.gagal).toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Impor siswa dari Excel')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Sheet pertama, baris pertama berisi header: nis, nisn, nama, jk '
            '(L/P), tgl_lahir (yyyy-mm-dd atau dd/mm/yyyy), kelas. Kolom nis, '
            'nama, jk, tgl_lahir wajib; kelas harus sama dengan nama kelas '
            'tahun ajaran aktif. NIS menjadi username, dan setiap siswa '
            'mendapat password awal acak.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _sibuk ? null : _pilih,
            icon: const Icon(Icons.upload_file),
            label: Text(_namaBerkas ?? 'Pilih berkas .xlsx'),
          ),
          if (_galat != null) ...[
            const SizedBox(height: 12),
            _Kotak(
              _galat!,
              theme.colorScheme.errorContainer,
              theme.colorScheme.onErrorContainer,
            ),
          ],
          if (baris != null) ...[
            const SizedBox(height: 16),
            Text(
              '${_valid.length} baris siap diimpor, ${salah.length} baris '
              'bermasalah',
              style: theme.textTheme.titleSmall,
            ),
            for (final b in salah)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Baris ${b.nomor}: ${b.galat}',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
            if (!selesai) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _sibuk || _belum.isEmpty ? null : _impor,
                child: _sibuk
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _hasil.isEmpty
                            ? 'Impor ${_valid.length} siswa'
                            : 'Lanjutkan impor (${_belum.length} sisa)',
                      ),
              ),
            ],
          ],
          if (_hasil.isNotEmpty) ...[
            const Divider(height: 32),
            Text(
              'Hasil: ${dibuat.length} dibuat, '
              '${_hasil.where((h) => h.status == StatusImpor.sudahAda).length} '
              'sudah ada (dilewati), ${gagal.length} gagal',
              style: theme.textTheme.titleSmall,
            ),
            for (final h in gagal)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'NIS ${h.nis}: ${h.pesan}',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
            if (dibuat.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Kotak(
                'Catat password awal berikut sekarang. Setelah halaman ini '
                'ditutup, password tidak bisa ditampilkan lagi (gunakan Reset '
                'password di menu Pengguna bila hilang).',
                kBrandSoft,
                kText,
              ),
              const SizedBox(height: 8),
              for (final h in dibuat)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('NIS ${h.nis}'),
                  trailing: SelectableText(
                    h.password!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text: [
                        'nis\tpassword',
                        for (final h in dibuat) '${h.nis}\t${h.password}',
                      ].join('\n'),
                    ),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Daftar password disalin.')),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Salin semua'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Kotak extends StatelessWidget {
  const _Kotak(this.teks, this.latar, this.warnaTeks);

  final String teks;
  final Color latar;
  final Color warnaTeks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(kRadiusControl),
      ),
      child: Text(teks, style: TextStyle(color: warnaTeks)),
    );
  }
}

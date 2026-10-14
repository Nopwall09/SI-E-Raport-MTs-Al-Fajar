import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../admin/presentation/admin_providers.dart';
import '../../admin/presentation/admin_widgets.dart';
import '../data/nilai_repository.dart';
import 'nilai_providers.dart';

/// Satu kolom nilai per siswa. Kolom kosong tidak dikirim; yang berubah
/// atau baru diisi disimpan sekaligus lewat tombol Simpan.
class InputNilaiPage extends ConsumerStatefulWidget {
  const InputNilaiPage({super.key, required this.penugasan});

  final Penugasan penugasan;

  @override
  ConsumerState<InputNilaiPage> createState() => _InputNilaiPageState();
}

class _InputNilaiPageState extends ConsumerState<InputNilaiPage> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = <int, TextEditingController>{};
  final _awal = <int, String>{};
  bool _menyimpan = false;

  KelasMapel get _kunci => (
        kelasId: widget.penugasan.kelasId,
        mapelId: widget.penugasan.mapelId,
      );

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _teks(num? n) =>
      n == null ? '' : (n % 1 == 0 ? n.toInt().toString() : n.toString());

  TextEditingController _kontrol(SiswaNilai s) =>
      _ctrl.putIfAbsent(s.kelasSiswaId, () {
        _awal[s.kelasSiswaId] = _teks(s.nilai);
        return TextEditingController(text: _awal[s.kelasSiswaId]);
      });

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final berubah = <int, num>{};
    _ctrl.forEach((id, c) {
      final t = c.text.trim().replaceAll(',', '.');
      if (t.isNotEmpty && t != _awal[id]) berubah[id] = num.parse(t);
    });
    if (berubah.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tidak ada perubahan')));
      return;
    }
    final ta = await ref.read(tahunAjaranAktifProvider.future);
    if (!mounted) return;
    setState(() => _menyimpan = true);
    final ok = await simpan(
      context,
      () => ref.read(nilaiRepositoryProvider).simpan(
            mapelId: widget.penugasan.mapelId,
            semester: ta.semester,
            nilaiPerKelasSiswa: berubah,
          ),
      '${berubah.length} nilai tersimpan',
    );
    if (!mounted) return;
    setState(() => _menyimpan = false);
    if (ok) {
      _awal.addAll({for (final e in berubah.entries) e.key: _teks(e.value)});
      ref.invalidate(siswaNilaiProvider(_kunci));
      ref.invalidate(adminProgresProvider);
      ref.invalidate(progresPenugasanProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.penugasan;
    final data = ref.watch(siswaNilaiProvider(_kunci));

    return Scaffold(
      appBar: AppBar(title: Text('${p.mapel}, ${p.kelas}')),
      body: statusAsync(data, () => ref.invalidate(siswaNilaiProvider(_kunci))) ??
          Form(
            key: _formKey,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: data.value!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final s = data.value![i];
                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(kRadiusCard),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.nama,
                                style: Theme.of(context).textTheme.titleSmall),
                            Text('NIS ${s.nis}',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 84,
                        child: TextFormField(
                          controller: _kontrol(s),
                          enabled: !_menyimpan,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]')),
                          ],
                          decoration: const InputDecoration(
                            hintText: '0-100',
                            isDense: true,
                          ),
                          validator: (v) {
                            final t = (v ?? '').trim().replaceAll(',', '.');
                            if (t.isEmpty) return null;
                            final n = num.tryParse(t);
                            return n == null || n < 0 || n > 100
                                ? '0-100'
                                : null;
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      floatingActionButton: data.hasValue
          ? FloatingActionButton.extended(
              onPressed: _menyimpan ? null : _simpan,
              icon: _menyimpan
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Simpan'),
            )
          : null,
    );
  }
}

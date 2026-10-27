import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../admin/presentation/admin_providers.dart';
import '../../admin/presentation/admin_widgets.dart';
import '../data/wali_kelas_repository.dart';
import 'wali_kelas_providers.dart';

class _Presensi {
  const _Presensi(this.sakit, this.izin, this.alpa, this.catatan);

  final int sakit;
  final int izin;
  final int alpa;
  final String? catatan;
}

/// UC-17: wali kelas mengisi presensi dan catatan satu siswa untuk semester
/// aktif, lalu memuat ulang progres kelas bila tersimpan.
Future<void> isiPresensi(
  BuildContext context,
  WidgetRef ref,
  SiswaProgres s,
) async {
  final hasil = await showModalBottomSheet<_Presensi>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (_) => _FormPresensi(s),
  );
  if (hasil == null || !context.mounted) return;
  final ta = await ref.read(tahunAjaranAktifProvider.future);
  if (!context.mounted) return;
  final ok = await simpan(
    context,
    () => WaliKelasRepository(ref.read(supabaseClientProvider)).simpanPresensi(
      kelasSiswaId: s.kelasSiswaId,
      semester: ta.semester,
      sakit: hasil.sakit,
      izin: hasil.izin,
      alpa: hasil.alpa,
      catatan: hasil.catatan,
    ),
    'Presensi ${s.nama} disimpan.',
  );
  if (ok) ref.invalidate(progresKelasProvider);
}

class _FormPresensi extends StatefulWidget {
  const _FormPresensi(this.s);

  final SiswaProgres s;

  @override
  State<_FormPresensi> createState() => _FormPresensiState();
}

class _FormPresensiState extends State<_FormPresensi> {
  final _formKey = GlobalKey<FormState>();
  late final _sakit = TextEditingController(text: '${widget.s.sakit}');
  late final _izin = TextEditingController(text: '${widget.s.izin}');
  late final _alpa = TextEditingController(text: '${widget.s.alpa}');
  late final _catatan = TextEditingController(text: widget.s.catatan ?? '');

  @override
  void dispose() {
    _sakit.dispose();
    _izin.dispose();
    _alpa.dispose();
    _catatan.dispose();
    super.dispose();
  }

  Widget _angka(String label, TextEditingController c) => Expanded(
    child: TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
      validator: (v) => (v == null || v.isEmpty) ? 'Isi angka' : null,
    ),
  );

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    final catatan = _catatan.text.trim();
    Navigator.pop(
      context,
      _Presensi(
        int.parse(_sakit.text),
        int.parse(_izin.text),
        int.parse(_alpa.text),
        catatan.isEmpty ? null : catatan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Presensi ${widget.s.nama}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _angka('Sakit', _sakit),
                const SizedBox(width: 12),
                _angka('Izin', _izin),
                const SizedBox(width: 12),
                _angka('Alpa', _alpa),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _catatan,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Catatan perkembangan (opsional)',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _simpan, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }
}

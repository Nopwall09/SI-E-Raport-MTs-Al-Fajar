import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../../widgets/motion.dart';
import '../../admin/presentation/admin_providers.dart';
import '../../admin/presentation/admin_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/wali_kelas_repository.dart';

final progresKelasProvider = FutureProvider<List<SiswaProgres>>((ref) async {
  // Bergantung pada pengguna agar data akun sebelumnya tidak terbawa.
  ref.watch(authControllerProvider.select((u) => u.value?.id));
  final kelas = ref.watch(authControllerProvider).value?.waliKelas;
  if (kelas == null) return const [];
  final ta = await ref.watch(tahunAjaranAktifProvider.future);
  return WaliKelasRepository(
    ref.watch(supabaseClientProvider),
  ).progres(kelasId: kelas.kelasId, semester: ta.semester);
});

/// Tab "Wali kelas": progres nilai UTS tiap siswa di kelas wali.
class WaliKelasPage extends ConsumerWidget {
  const WaliKelasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kelas = ref.watch(authControllerProvider).value?.waliKelas;
    final data = ref.watch(progresKelasProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Kelas ${kelas?.namaKelas ?? ''}')),
      body:
          statusAsync(data, () => ref.invalidate(progresKelasProvider)) ??
          RefreshIndicator(
            color: kBrand,
            onRefresh: () async {
              ref.invalidate(progresKelasProvider);
              try {
                await ref.read(progresKelasProvider.future);
              } catch (_) {}
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: data.value!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  FadeSlideIn(index: i, child: _KartuSiswa(data.value![i])),
            ),
          ),
    );
  }
}

class _KartuSiswa extends ConsumerWidget {
  const _KartuSiswa(this.s);

  final SiswaProgres s;

  Future<void> _isiPresensi(BuildContext context, WidgetRef ref) async {
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
      () =>
          WaliKelasRepository(ref.read(supabaseClientProvider)).simpanPresensi(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = s.mapel.length;
    final lengkap = total > 0 && s.terisi == total;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kBorder),
        boxShadow: kCardShadow,
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(s.nama, style: theme.textTheme.titleSmall),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : s.terisi / total,
                      minHeight: 6,
                      color: kBrand,
                      backgroundColor: kField,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${s.terisi}/$total mapel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: lengkap ? kBrand : kMuted,
                  ),
                ),
              ],
            ),
          ),
          children: [
            for (final m in s.mapel)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(child: Text(m.mapel)),
                    Text(
                      m.nilai == null
                          ? 'Belum'
                          : (m.nilai! % 1 == 0
                                ? m.nilai!.toInt().toString()
                                : m.nilai.toString()),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: m.nilai == null ? kMuted : kText,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sakit ${s.sakit}  ·  Izin ${s.izin}  ·  Alpa ${s.alpa}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (s.terkunci)
                  const Text('Rapor final', style: TextStyle(color: kMuted))
                else
                  TextButton.icon(
                    onPressed: () => _isiPresensi(context, ref),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Isi presensi'),
                  ),
              ],
            ),
            if (s.catatan != null && s.catatan!.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Catatan: ${s.catatan}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Presensi {
  const _Presensi(this.sakit, this.izin, this.alpa, this.catatan);

  final int sakit;
  final int izin;
  final int alpa;
  final String? catatan;
}

/// Form presensi dan catatan perkembangan satu siswa (UC-17).
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

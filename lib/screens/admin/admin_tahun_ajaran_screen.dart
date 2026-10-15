import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../features/admin/presentation/admin_providers.dart';
import '../../features/admin/presentation/admin_widgets.dart';
import '../../models/tahun_ajaran_model.dart';
import '../../widgets/motion.dart';
import 'widgets/admin_menu_drawer.dart';

/// Tahun ajaran (tabel `tahun_ajaran`). Hanya satu yang aktif; yang aktif
/// menentukan kelas, nilai, dan rapor yang tampil di seluruh aplikasi.
class AdminTahunAjaranScreen extends ConsumerStatefulWidget {
  const AdminTahunAjaranScreen({super.key});

  @override
  ConsumerState<AdminTahunAjaranScreen> createState() =>
      _AdminTahunAjaranScreenState();
}

class _AdminTahunAjaranScreenState
    extends ConsumerState<AdminTahunAjaranScreen> {
  void _segarkan() {
    // Tahun aktif mengubah hampir semua data lain.
    for (final p in [
      adminTahunAjaranProvider,
      tahunAjaranAktifProvider,
      adminKelasProvider,
      adminSiswaProvider,
      adminStatistikProvider,
      adminProgresProvider,
      opsiKelasProvider,
    ]) {
      ref.invalidate(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(adminTahunAjaranProvider);
    final list = data.valueOrNull ?? const <TahunAjaranModel>[];

    return Scaffold(
      drawer: const AdminMenuDrawer(currentRoute: '/admin/tahun-ajaran'),
      appBar: AppBar(title: const Text('Tahun Ajaran')),
      body:
          statusAsync(data, () => ref.invalidate(adminTahunAjaranProvider)) ??
          RefreshIndicator(
            color: kBrand,
            onRefresh: () async {
              ref.invalidate(adminTahunAjaranProvider);
              try {
                await ref.read(adminTahunAjaranProvider.future);
              } catch (_) {}
            },
            child: list.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Belum ada tahun ajaran.',
                          style: TextStyle(color: kMuted),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        FadeSlideIn(index: i, child: _kartu(list[i])),
                  ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }

  Widget _kartu(TahunAjaranModel t) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(kRadiusCard),
    child: InkWell(
      borderRadius: BorderRadius.circular(kRadiusCard),
      onTap: () => _detail(t),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadiusCard),
          border: Border.all(color: t.isActive ? kBrand : kBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TA ${t.tahun}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Semester ${t.semesterLabel}, SKM ${t.skm}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (t.isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: kBrandSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Aktif',
                  style: TextStyle(
                    color: kBrand,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  void _detail(TahunAjaranModel t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('TA ${t.tahun}', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              _baris('Semester', t.semesterLabel),
              _baris('Standar ketuntasan (SKM)', '${t.skm}'),
              _baris('Status', t.isActive ? 'Aktif' : 'Tidak aktif'),
              const SizedBox(height: 16),
              if (!t.isActive) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    final yakin = await konfirmasiAksi(
                      ctx,
                      judul: 'Jadikan TA ${t.tahun} aktif?',
                      isi:
                          'Kelas, nilai, dan rapor yang tampil akan mengikuti tahun ajaran ini.',
                      aksi: 'Aktifkan',
                    );
                    if (!yakin || !mounted) return;
                    final ok = await simpan(
                      context,
                      () => ref
                          .read(adminRepositoryProvider)
                          .aktifkanTahunAjaran(int.parse(t.id)),
                      'TA ${t.tahun} sekarang aktif.',
                    );
                    if (!ok) return;
                    _segarkan();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Jadikan aktif'),
                ),
                const SizedBox(height: 8),
              ],
              AksiUbahHapus(
                onUbah: () {
                  Navigator.pop(ctx);
                  _form(context, awal: t);
                },
                onHapus: () async {
                  final yakin = await konfirmasiHapus(
                    ctx,
                    judul: 'Hapus TA ${t.tahun}?',
                    isi:
                        'Tahun ajaran yang sudah punya kelas tidak bisa dihapus.',
                  );
                  if (!yakin || !mounted) return;
                  final ok = await simpan(
                    context,
                    () => ref.read(adminRepositoryProvider).hapusTahunAjaran(t),
                    'TA ${t.tahun} dihapus.',
                  );
                  if (!ok) return;
                  _segarkan();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _baris(String label, String nilai) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: kMuted)),
        Text(nilai, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );

  /// Form tambah (awal == null) atau ubah.
  void _form(BuildContext context, {TahunAjaranModel? awal}) {
    final tahun = TextEditingController(text: awal?.tahun);
    final skm = TextEditingController(text: '${awal?.skm ?? 75}');
    var semester = awal?.semester ?? 'ganjil';
    var langsungAktif = false;
    String? galat;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                awal == null ? 'Tambah Tahun Ajaran' : 'Ubah Tahun Ajaran',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tahun,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Tahun ajaran',
                  hintText: '2026/2027',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Semester',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              RadioGroup<String>(
                groupValue: semester,
                onChanged: (v) => setModal(() => semester = v ?? semester),
                child: const Row(
                  children: [
                    Radio<String>(value: 'ganjil'),
                    Text('Ganjil'),
                    SizedBox(width: 16),
                    Radio<String>(value: 'genap'),
                    Text('Genap'),
                  ],
                ),
              ),
              TextField(
                controller: skm,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Standar ketuntasan (SKM)',
                  helperText: '0 sampai 100, berlaku untuk semua mapel',
                ),
              ),
              if (awal == null)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Langsung jadikan aktif'),
                  value: langsungAktif,
                  onChanged: (v) => setModal(() => langsungAktif = v ?? false),
                ),
              if (galat != null) ...[
                const SizedBox(height: 8),
                Text(
                  galat!,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final t = tahun.text.trim();
                  final angka = int.tryParse(skm.text.trim());
                  if (!RegExp(r'^\d{4}/\d{4}$').hasMatch(t)) {
                    setModal(() => galat = 'Format tahun ajaran: 2026/2027.');
                    return;
                  }
                  if (angka == null || angka < 0 || angka > 100) {
                    setModal(() => galat = 'SKM harus angka 0 sampai 100.');
                    return;
                  }
                  final repo = ref.read(adminRepositoryProvider);
                  final ok = await simpan(
                    context,
                    () async {
                      if (awal == null) {
                        final id = await repo.tambahTahunAjaran(
                          tahun: t,
                          semester: semester,
                          skm: angka,
                        );
                        if (langsungAktif) await repo.aktifkanTahunAjaran(id);
                      } else {
                        await repo.ubahTahunAjaran(
                          id: int.parse(awal.id),
                          tahun: t,
                          semester: semester,
                          skm: angka,
                        );
                      }
                    },
                    awal == null ? 'TA $t ditambahkan.' : 'TA $t diperbarui.',
                  );
                  if (!ok) return;
                  _segarkan();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(awal == null ? 'Simpan' : 'Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

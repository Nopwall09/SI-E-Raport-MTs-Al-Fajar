import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../features/admin/presentation/admin_providers.dart';
import '../../features/admin/presentation/admin_widgets.dart';
import '../../models/mapel_model.dart';
import '../../widgets/motion.dart';
import 'widgets/admin_menu_drawer.dart';

/// Daftar mata pelajaran (tabel `mapel`). Pengampu diambil dari penugasan
/// mengajar, jadi tidak diisi di sini.
class AdminMataPelajaranScreen extends ConsumerStatefulWidget {
  const AdminMataPelajaranScreen({super.key});

  @override
  ConsumerState<AdminMataPelajaranScreen> createState() =>
      _AdminMataPelajaranScreenState();
}

class _AdminMataPelajaranScreenState
    extends ConsumerState<AdminMataPelajaranScreen> {
  final _cari = TextEditingController();

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  void _segarkan() {
    ref.invalidate(adminMapelProvider);
    ref.invalidate(adminGuruProvider);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(adminMapelProvider);
    final q = _cari.text.trim().toLowerCase();
    final list = [
      for (final m in data.valueOrNull ?? const <MapelModel>[])
        if (q.isEmpty ||
            m.nama.toLowerCase().contains(q) ||
            m.kode.toLowerCase().contains(q))
          m,
    ];

    return Scaffold(
      drawer: const AdminMenuDrawer(currentRoute: '/admin/mapel'),
      appBar: AppBar(title: const Text('Mata Pelajaran')),
      body:
          statusAsync(data, () => ref.invalidate(adminMapelProvider)) ??
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: TextField(
                    controller: _cari,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Cari nama atau kode',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Text(
                            q.isEmpty
                                ? 'Belum ada mata pelajaran.'
                                : 'Tidak ditemukan.',
                            style: const TextStyle(color: kMuted),
                          ),
                        )
                      : RefreshIndicator(
                          color: kBrand,
                          onRefresh: () async {
                            _segarkan();
                            try {
                              await ref.read(adminMapelProvider.future);
                            } catch (_) {}
                          },
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                            itemCount: list.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) =>
                                FadeSlideIn(index: i, child: _kartu(list[i])),
                          ),
                        ),
                ),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }

  Widget _kartu(MapelModel m) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(kRadiusCard),
    child: InkWell(
      borderRadius: BorderRadius.circular(kRadiusCard),
      onTap: () => _detail(m),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadiusCard),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kBrandSoft,
                borderRadius: BorderRadius.circular(kRadiusControl),
              ),
              child: Text(
                m.kode,
                style: const TextStyle(
                  color: kBrand,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.nama,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pengampu: ${m.guruPengampu}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kMuted),
          ],
        ),
      ),
    ),
  );

  void _detail(MapelModel m) {
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
              Text(m.nama, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              _baris('Kode', m.kode),
              _baris('Pengampu', m.guruPengampu),
              const SizedBox(height: 16),
              AksiUbahHapus(
                onUbah: () {
                  Navigator.pop(ctx);
                  _form(context, awal: m);
                },
                onHapus: () async {
                  final yakin = await konfirmasiHapus(
                    ctx,
                    judul: 'Hapus ${m.nama}?',
                    isi:
                        'Mata pelajaran yang sudah dipakai penugasan atau nilai tidak bisa dihapus.',
                  );
                  if (!yakin || !mounted) return;
                  final ok = await simpan(
                    context,
                    () => ref
                        .read(adminRepositoryProvider)
                        .hapusMapel(int.parse(m.id)),
                    '${m.nama} dihapus.',
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: kMuted)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            nilai,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  /// Form tambah (awal == null) atau ubah.
  void _form(BuildContext context, {MapelModel? awal}) {
    final kode = TextEditingController(text: awal?.kode);
    final nama = TextEditingController(text: awal?.nama);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
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
              awal == null ? 'Tambah Mata Pelajaran' : 'Ubah Mata Pelajaran',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: kode,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Kode',
                hintText: 'Contoh: MTK',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nama,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama mata pelajaran',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                final k = kode.text.trim().toUpperCase();
                final n = nama.text.trim();
                if (k.isEmpty || n.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kode dan nama wajib diisi.')),
                  );
                  return;
                }
                final repo = ref.read(adminRepositoryProvider);
                final ok = await simpan(
                  context,
                  () => awal == null
                      ? repo.tambahMapel(kode: k, nama: n)
                      : repo.ubahMapel(
                          id: int.parse(awal.id),
                          kode: k,
                          nama: n,
                        ),
                  awal == null ? '$n ditambahkan.' : '$n diperbarui.',
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
    );
  }
}

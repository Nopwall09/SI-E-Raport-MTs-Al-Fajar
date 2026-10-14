import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/motion.dart';
import '../../features/admin/presentation/admin_providers.dart';
import '../../features/admin/presentation/admin_widgets.dart';
import '../../models/kelas_model.dart';

class AdminDataKelasScreen extends ConsumerStatefulWidget {
  const AdminDataKelasScreen({super.key});

  @override
  ConsumerState<AdminDataKelasScreen> createState() =>
      _AdminDataKelasScreenState();
}

class _AdminDataKelasScreenState extends ConsumerState<AdminDataKelasScreen> {
  String _selectedTingkat = 'Semua';

  final List<String> _tingkatList = [
    'Semua',
    'Kelas VII',
    'Kelas VIII',
    'Kelas IX',
  ];

  List<KelasModel> _daftarKelas = const [];

  List<KelasModel> get _filteredKelas {
    if (_selectedTingkat == 'Semua') return _daftarKelas;
    final t = _selectedTingkat.replaceAll('Kelas ', '');
    return _daftarKelas.where((k) => k.tingkat == t).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lista = ref.watch(adminKelasProvider);
    _daftarKelas = lista.valueOrNull ?? const [];
    const brandColor = kBrand;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Data Kelas',
          style: TextStyle(
            color: kText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          statusAsync(lista, () => ref.invalidate(adminKelasProvider)) ??
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Filter Tingkat Kelas Chips
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _tingkatList.map((tingkat) {
                        final isSelected = _selectedTingkat == tingkat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () =>
                                setState(() => _selectedTingkat = tingkat),
                            borderRadius: BorderRadius.circular(999),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? brandColor : kField,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isSelected ? brandColor : kBorder,
                                ),
                              ),
                              child: Text(
                                tingkat,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected ? Colors.white : kMuted,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const Divider(height: 1),

                // Daftar Kelas (Sesuai Wireframe)
                Expanded(
                  child: _filteredKelas.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada kelas ditemukan',
                            style: TextStyle(
                              color: kMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: kBrand,
                          onRefresh: () async {
                            ref.invalidate(adminKelasProvider);
                            try {
                              await ref.read(adminKelasProvider.future);
                            } catch (_) {}
                          },
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                            itemCount: _filteredKelas.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final kelas = _filteredKelas[index];
                              return FadeSlideIn(
                                index: index,
                                child: PressScale(
                                  child: _buildKelasCard(kelas, brandColor),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showKelasFormSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }

  Widget _buildKelasCard(KelasModel kelas, Color brandColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kBorder),
        boxShadow: kCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadiusCard),
          onTap: () => _showKelasDetailSheet(context, kelas, brandColor),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelas ${kelas.namaKelas}',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Wali ${kelas.namaWali} · ${kelas.jumlahSiswa} siswa',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: kMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: kMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showKelasDetailSheet(
    BuildContext context,
    KelasModel kelas,
    Color brandColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detail Kelas ${kelas.namaKelas}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kText,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Tingkat', 'Kelas ${kelas.tingkat} (MTs)'),
            _buildDetailRow('Wali Kelas', kelas.namaWali),
            _buildDetailRow('Jumlah Siswa', '${kelas.jumlahSiswa} siswa'),
            _buildDetailRow(
              'Tahun Ajaran',
              ref.read(tahunAjaranAktifProvider).valueOrNull?.label ?? '-',
            ),
            const SizedBox(height: 16),
            AksiUbahHapus(
              onUbah: () {
                Navigator.pop(ctx);
                _showKelasFormSheet(context, awal: kelas);
              },
              onHapus: () async {
                final yakin = await konfirmasiHapus(
                  ctx,
                  judul: 'Hapus kelas ${kelas.namaKelas}?',
                  isi:
                      'Hanya kelas yang sudah tidak berisi siswa yang bisa dihapus.',
                );
                if (!yakin || !context.mounted) return;
                final ok = await simpan(
                  context,
                  () => ref
                      .read(adminRepositoryProvider)
                      .hapusKelas(int.parse(kelas.id)),
                  'Kelas ${kelas.namaKelas} dihapus.',
                );
                if (!ok) return;
                _segarkan();
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: kMuted)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
        ],
      ),
    );
  }

  void _segarkan() {
    ref.invalidate(adminKelasProvider);
    ref.invalidate(adminSiswaProvider);
    ref.invalidate(opsiKelasProvider);
    ref.invalidate(adminGuruProvider);
    ref.invalidate(adminStatistikProvider);
  }

  /// Form tambah (awal == null) atau ubah kelas.
  Future<void> _showKelasFormSheet(
    BuildContext context, {
    KelasModel? awal,
  }) async {
    final namaCtrl = TextEditingController(text: awal?.namaKelas);
    int? selectedWaliId;
    final guru = await ref.read(opsiGuruProvider.future);
    if (!context.mounted) return;
    String selectedTingkat = awal?.tingkat ?? 'VII';
    if (guru.any((g) => g.id == awal?.waliKelasId)) {
      selectedWaliId = awal!.waliKelasId;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    awal == null ? 'Tambah Kelas Baru' : 'Ubah Kelas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedTingkat,
                decoration: InputDecoration(labelText: 'Tingkat Kelas'),
                items: const [
                  DropdownMenuItem(value: 'VII', child: Text('Tingkat VII')),
                  DropdownMenuItem(value: 'VIII', child: Text('Tingkat VIII')),
                  DropdownMenuItem(value: 'IX', child: Text('Tingkat IX')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => selectedTingkat = val);
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: namaCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Kelas',
                  hintText: 'Contoh: VII-D atau VIII-C',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                initialValue: selectedWaliId,
                decoration: InputDecoration(labelText: 'Wali Kelas (opsional)'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Belum ditentukan'),
                  ),
                  for (final g in guru)
                    DropdownMenuItem<int?>(value: g.id, child: Text(g.label)),
                ],
                onChanged: (val) => setModalState(() => selectedWaliId = val),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadiusControl),
                  ),
                ),
                onPressed: () async {
                  final nama = namaCtrl.text.trim();
                  if (nama.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama kelas wajib diisi.')),
                    );
                    return;
                  }
                  final repo = ref.read(adminRepositoryProvider);
                  final ok = await simpan(
                    context,
                    () => awal == null
                        ? repo.tambahKelas(
                            tingkat: selectedTingkat,
                            nama: nama,
                            waliKelasId: selectedWaliId,
                          )
                        : repo.ubahKelas(
                            id: int.parse(awal.id),
                            tingkat: selectedTingkat,
                            nama: nama,
                            waliKelasId: selectedWaliId,
                          ),
                    awal == null
                        ? 'Kelas $nama berhasil ditambahkan.'
                        : 'Kelas $nama diperbarui.',
                  );
                  if (!ok) return;
                  _segarkan();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(
                  awal == null ? 'Simpan Kelas' : 'Simpan Perubahan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/admin/presentation/admin_providers.dart';
import '../../features/admin/presentation/admin_widgets.dart';
import '../../models/kelas_model.dart';

class AdminDataKelasScreen extends ConsumerStatefulWidget {
  const AdminDataKelasScreen({
    super.key,
  });

  @override
  ConsumerState<AdminDataKelasScreen> createState() => _AdminDataKelasScreenState();
}

class _AdminDataKelasScreenState extends ConsumerState<AdminDataKelasScreen> {
  String _selectedTingkat = 'Semua';

  final List<String> _tingkatList = ['Semua', 'Kelas VII', 'Kelas VIII', 'Kelas IX'];

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
    const brandColor = Color(0xFF0D5C3A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 1,
        title: const Text(
          'Data Kelas',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: statusAsync(lista, () => ref.invalidate(adminKelasProvider)) ??
          SafeArea(
        child: Column(
          children: [
            // Filter Tingkat Kelas Chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _tingkatList.map((tingkat) {
                    final isSelected = _selectedTingkat == tingkat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedTingkat = tingkat),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? brandColor
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? brandColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            tingkat,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
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
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredKelas.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final kelas = _filteredKelas[index];
                        return _buildKelasCard(kelas, brandColor);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE2E8F0),
        foregroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        elevation: 2,
        onPressed: () => _showAddKelasSheet(context),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildKelasCard(KelasModel kelas, Color brandColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Wali ${kelas.namaWali} · ${kelas.jumlahSiswa} siswa',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showKelasDetailSheet(
      BuildContext context, KelasModel kelas, Color brandColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                    color: Color(0xFF1E293B),
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
            _buildDetailRow(
                'Jumlah Siswa', '${kelas.jumlahSiswa} / ${kelas.kapasitas} Siswa'),
            _buildDetailRow('Tahun Ajaran', '2025/2026 (Ganjil)'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Membuka daftar seluruh siswa Kelas ${kelas.namaKelas}...'),
                  ),
                );
              },
              icon: const Icon(Icons.groups_outlined, size: 18),
              label: const Text('Lihat Daftar Siswa Kelas Ini'),
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
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddKelasSheet(BuildContext context) async {
    final namaCtrl = TextEditingController();
    int? selectedWaliId;
    final guru = await ref.read(opsiGuruProvider.future);
    if (!context.mounted) return;
    String selectedTingkat = 'VII';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  const Text(
                    'Tambah Kelas Baru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedTingkat,
                decoration: InputDecoration(
                  labelText: 'Tingkat Kelas',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                value: selectedWaliId,
                decoration: InputDecoration(
                  labelText: 'Wali Kelas (opsional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('Belum ditentukan')),
                  for (final g in guru)
                    DropdownMenuItem<int?>(value: g.id, child: Text(g.label)),
                ],
                onChanged: (val) => setModalState(() => selectedWaliId = val),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D5C3A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
                  final ok = await simpan(
                    context,
                    () => ref.read(adminRepositoryProvider).tambahKelas(
                          tingkat: selectedTingkat,
                          nama: nama,
                          waliKelasId: selectedWaliId,
                        ),
                    'Kelas $nama berhasil ditambahkan.',
                  );
                  if (!ok) return;
                  ref.invalidate(adminKelasProvider);
                  ref.invalidate(opsiKelasProvider);
                  ref.invalidate(adminStatistikProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text(
                  'Simpan Kelas',
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

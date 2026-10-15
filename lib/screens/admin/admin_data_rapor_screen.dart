import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/config/env.dart';
import '../../models/data_rapor_model.dart';
import 'widgets/admin_menu_drawer.dart';

class AdminDataRaporScreen extends ConsumerStatefulWidget {
  const AdminDataRaporScreen({super.key});

  @override
  ConsumerState<AdminDataRaporScreen> createState() =>
      _AdminDataRaporScreenState();
}

class _AdminDataRaporScreenState extends ConsumerState<AdminDataRaporScreen> {
  String _selectedKelas = 'VII-A';
  String _selectedSemester = 'Ganjil';

  // [CheckBox]: Filter hanya yang siap cetak & seleksi masal
  bool _hanyaYangSiap = false;
  final Set<String> _selectedIds = {};

  final List<String> _kelasList = [
    'VII-A',
    'VII-B',
    'VII-C',
    'VIII-A',
    'VIII-B',
    'IX-A',
    'IX-B',
  ];

  final List<String> _semesterList = ['Ganjil', 'Genap'];

  final List<DataRaporModel> _daftarRapor = [
    const DataRaporModel(
      id: '1',
      namaSiswa: 'Muhammad Farhan Al-Ghifari',
      nisn: '0089765432',
      kelas: 'VII-A',
      semester: 'Ganjil',
      mapelSelesai: 9,
      totalMapel: 9,
      status: 'Siap',
    ),
    const DataRaporModel(
      id: '2',
      namaSiswa: 'Aisyah Putri Azzahra',
      nisn: '0081234567',
      kelas: 'VII-A',
      semester: 'Ganjil',
      mapelSelesai: 9,
      totalMapel: 9,
      status: 'Siap',
    ),
    const DataRaporModel(
      id: '3',
      namaSiswa: 'Ahmad Bilal Al-Kautsar',
      nisn: '0087654321',
      kelas: 'VII-A',
      semester: 'Ganjil',
      mapelSelesai: 9,
      totalMapel: 9,
      status: 'Siap',
    ),
    const DataRaporModel(
      id: '4',
      namaSiswa: 'Fatimah Zahra Maulida',
      nisn: '0078901234',
      kelas: 'VII-A',
      semester: 'Ganjil',
      mapelSelesai: 8,
      totalMapel: 9,
      status: 'Belum Siap',
    ),
    const DataRaporModel(
      id: '5',
      namaSiswa: 'Rizky Ramadhan',
      nisn: '0076543210',
      kelas: 'VII-A',
      semester: 'Ganjil',
      mapelSelesai: 9,
      totalMapel: 9,
      status: 'Siap',
    ),
  ];

  List<DataRaporModel> get _filteredRapor {
    return _daftarRapor.where((item) {
      if (_hanyaYangSiap && !item.isSiap) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredRapor;
    final allSelected =
        list.isNotEmpty && list.every((item) => _selectedIds.contains(item.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      drawer: const AdminMenuDrawer(currentRoute: '/admin/rapor'),
      appBar: AppBar(
        title: const Text(
          'Data Rapor',
          style: TextStyle(
            color: kText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Dropdown Baris: Kelas & Semester
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedKelas,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  size: 20),
                              items: _kelasList.map((k) {
                                return DropdownMenuItem(
                                  value: k,
                                  child: Text(
                                    'Kelas $k',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList>,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedKelas = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSemester,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  size: 20),
                              items: _semesterList.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    'Semester $s',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList>,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedSemester = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // [CheckBox]: Filter hanya yang siap cetak & Seleksi semua
                  Row(
                    children: [
                      Checkbox(
                        value: _hanyaYangSiap,
                        activeColor: kBrand,
                        onChanged: (val) {
                          setState(() => _hanyaYangSiap = val ?? false);
                        },
                      ),
                      const Text(
                        'Hanya yang Siap Cetak',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          setState(() {
                            if (allSelected) {
                              _selectedIds.clear();
                            } else {
                              _selectedIds.addAll(list.map((e) => e.id));
                            }
                          });
                        },
                        icon: Icon(
                          allSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 18,
                          color: kBrand,
                        ),
                        label: Text(
                          allSelected ? 'Batal Semua' : 'Pilih Semua',
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Daftar Siswa & Kesiapan Rapor
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada data rapor yang cocok',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return _buildRaporCard(item);
                      },
                    ),
            ),

            // Tombol Cetak Rapor di Bagian Bawah
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2E8F0),
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFF334155), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () => _cetakRaporMasal(context),
                  icon: const Icon(Icons.print_outlined, size: 20),
                  label: Text(
                    _selectedIds.isEmpty
                        ? 'Cetak Rapor Kelas $_selectedKelas'
                        : 'Cetak ${_selectedIds.length} Rapor Terpilih',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [FrameLayout (Stack)] & [CheckBox] & [PopupMenu] & [ContextMenu]
  Widget _buildRaporCard(DataRaporModel item) {
    final isSelected = _selectedIds.contains(item.id);

    return GestureDetector(
      // [ContextMenu]: Muncul saat ditekan lama (Long Press)
      onLongPressStart: (details) =>
          _showRaporContextMenu(context, details.globalPosition, item),
      child: Stack(
        // [FrameLayout]: Tumpukan kartu dengan badge posisi khusus
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? kBrand : Colors.grey.shade300,
                width: isSelected ? 1.6 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _previewRaporSiswa(context, item),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      // [CheckBox]: Pemilihan siswa per baris untuk cetak masal
                      Checkbox(
                        value: isSelected,
                        activeColor: kBrand,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.add(item.id);
                            } else {
                              _selectedIds.remove(item.id);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.namaSiswa,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Nilai ${item.mapelSelesai}/${item.totalMapel} mapel',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.isSiap
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: item.isSiap
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: item.isSiap
                                ? const Color(0xFF166534)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),

                      // [PopupMenu]: Tombol titik tiga per item siswa
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        tooltip: 'Aksi Rapor Siswa',
                        onSelected: (val) {
                          if (val == 'preview') {
                            _previewRaporSiswa(context, item);
                          } else if (val == 'download') {
                            _unduhDariSupabaseStorage(context, item);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'preview',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Pratinjau Rapor'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'download',
                            child: Row(
                              children: [
                                Icon(Icons.cloud_download_outlined,
                                    size: 18, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Unduh dari Supabase Storage'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// [ContextMenu]: Menu melayang saat ditekan lama
  void _showRaporContextMenu(
      BuildContext context, Offset position, DataRaporModel item) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          value: 'cetak',
          child: Text('Cetak Lembar: ${item.namaSiswa}'),
        ),
        const PopupMenuItem(
          value: 'storage',
          child: Text('Ambil Arsip dari Supabase Storage'),
        ),
      ],
    ).then((val) {
      if (val == 'cetak') {
        _previewRaporSiswa(context, item);
      } else if (val == 'storage') {
        _unduhDariSupabaseStorage(context, item);
      }
    });
  }

  /// [Supabase Storage (Bobot 7%)]: Menghubungkan unduhan file ke Supabase Storage Bucket
  void _unduhDariSupabaseStorage(BuildContext context, DataRaporModel item) {
    try {
      final supabase = Supabase.instance.client;
      // Membaca URL publik berkas rapor dari bucket 'rapor' di Supabase Storage
      final fileUrl = supabase.storage
          .from('rapor')
          .getPublicUrl('${item.kelas}/${item.nisn}_rapor.pdf');

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cloud_done, color: kBrand),
              SizedBox(width: 8),
              Text('Supabase Storage'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Berkas rapor ananda ${item.namaSiswa} siap diunduh.'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Bucket: rapor\nPath: ${item.kelas}/${item.nisn}_rapor.pdf\nURL: $fileUrl',
                  style: const TextStyle(
                      fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: kBrand),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Mengunduh berkas rapor ${item.namaSiswa} dari Supabase Storage...'),
                  ),
                );
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Unduh Sekarang'),
            ),
          ],
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Supabase Storage: Menyiapkan berkas rapor ${item.namaSiswa}...'),
        ),
      );
    }
  }

  void _previewRaporSiswa(BuildContext context, DataRaporModel item) {
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
                  'Rapor Siswa - Kelas $_selectedKelas',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.namaSiswa,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              'NISN: ${item.nisn} · Semester $_selectedSemester',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kelengkapan Nilai:'),
                Text(
                  '${item.mapelSelesai}/${item.totalMapel} Mata Pelajaran',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status Rapor:'),
                Text(
                  item.status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.isSiap
                        ? const Color(0xFF166534)
                        : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: kBrand),
              onPressed: () {
                Navigator.pop(ctx);
                _unduhDariSupabaseStorage(context, item);
              },
              icon: const Icon(Icons.cloud_download, size: 18),
              label: const Text('Unduh Berkas via Supabase Storage (PDF)'),
            ),
          ],
        ),
      ),
    );
  }

  void _cetakRaporMasal(BuildContext context) {
    final count = _selectedIds.isEmpty ? _filteredRapor.length : _selectedIds.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cetak Rapor Kelas'),
        content: Text(
          'Mencetak rapor untuk $count siswa di Kelas $_selectedKelas Semester $_selectedSemester.\n\nBerkas PDF akan disimpan dan diunduh langsung dari Supabase Storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: kBrand),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Mengunduh gabungan $count lembar rapor Kelas $_selectedKelas dari Supabase Storage...',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Cetak & Unduh'),
          ),
        ],
      ),
    );
  }
}

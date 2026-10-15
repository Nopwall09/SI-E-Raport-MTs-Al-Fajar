import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
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
      status: 'Siap',
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

  @override
  Widget build(BuildContext context) {
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
            // Filter Dropdown Baris: Kelas & Semester (Sesuai Wireframe)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
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
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
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
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedKelas = val);
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
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
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
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSemester = val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Daftar Siswa & Kesiapan Rapor
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _daftarRapor.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _daftarRapor[index];
                  return _buildRaporCard(item);
                },
              ),
            ),

            // Tombol Cetak Rapor di Bagian Bawah (Sesuai Wireframe)
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
                  label: const Text(
                    'Cetak Rapor',
                    style: TextStyle(
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

  Widget _buildRaporCard(DataRaporModel item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.isSiap
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: item.isSiap
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: item.isSiap
                          ? const Color(0xFF334155)
                          : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: kBrand),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Menyiapkan berkas PDF e-Rapor ${item.namaSiswa}...'),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Unduh Lembar Rapor Siswa (PDF)'),
            ),
          ],
        ),
      ),
    );
  }

  void _cetakRaporMasal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cetak Rapor Kelas'),
        content: Text(
          'Apakah Anda ingin mencetak lembar rapor untuk seluruh siswa di Kelas $_selectedKelas Semester $_selectedSemester?',
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
                    'Mengunduh gabungan PDF Rapor Kelas $_selectedKelas...',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Cetak Semua'),
          ),
        ],
      ),
    );
  }
}

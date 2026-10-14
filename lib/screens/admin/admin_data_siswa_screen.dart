import 'package:flutter/material.dart';
import '../../models/siswa_model.dart';

class AdminDataSiswaScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const AdminDataSiswaScreen({
    super.key,
    this.onOpenDrawer,
  });

  @override
  State<AdminDataSiswaScreen> createState() => _AdminDataSiswaScreenState();
}

class _AdminDataSiswaScreenState extends State<AdminDataSiswaScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedKelas = 'Semua';

  final List<String> _kelasList = [
    'Semua',
    'VII-A',
    'VII-B',
    'VIII-A',
    'VIII-B',
    'IX-A',
    'IX-B',
  ];

  final List<SiswaModel> _daftarSiswa = [
    const SiswaModel(
      id: '1',
      nama: 'Muhammad Farhan Al-Ghifari',
      nisn: '0089765432',
      kelas: 'VII-A',
      jenisKelamin: 'L',
      namaWali: 'H. Bambang Setiawan',
    ),
    const SiswaModel(
      id: '2',
      nama: 'Aisyah Putri Azzahra',
      nisn: '0081234567',
      kelas: 'VII-A',
      jenisKelamin: 'P',
      namaWali: 'Hj. Siti Mariam',
    ),
    const SiswaModel(
      id: '3',
      nama: 'Ahmad Bilal Al-Kautsar',
      nisn: '0087654321',
      kelas: 'VII-B',
      jenisKelamin: 'L',
      namaWali: 'Rahmat Hidayat',
    ),
    const SiswaModel(
      id: '4',
      nama: 'Fatimah Zahra Maulida',
      nisn: '0078901234',
      kelas: 'VIII-A',
      jenisKelamin: 'P',
      namaWali: 'Ir. Hendra Wijaya',
    ),
    const SiswaModel(
      id: '5',
      nama: 'Rizky Ramadhan',
      nisn: '0076543210',
      kelas: 'VIII-B',
      jenisKelamin: 'L',
      namaWali: 'Subhan Santoso',
    ),
    const SiswaModel(
      id: '6',
      nama: 'Zaskia Nurul Izzati',
      nisn: '0065432198',
      kelas: 'IX-A',
      jenisKelamin: 'P',
      namaWali: 'Drs. H. Mulyadi',
    ),
    const SiswaModel(
      id: '7',
      nama: 'Zidan Al-Mubarak',
      nisn: '0069876543',
      kelas: 'IX-B',
      jenisKelamin: 'L',
      namaWali: 'Agus Salim',
    ),
  ];

  List<SiswaModel> get _filteredSiswa {
    final query = _searchController.text.trim().toLowerCase();
    return _daftarSiswa.where((siswa) {
      final matchesQuery = query.isEmpty ||
          siswa.nama.toLowerCase().contains(query) ||
          siswa.nisn.toLowerCase().contains(query);
      final matchesKelas =
          _selectedKelas == 'Semua' || siswa.kelas == _selectedKelas;
      return matchesQuery && matchesKelas;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF0D5C3A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 1,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
            onPressed: () {
              if (widget.onOpenDrawer != null) {
                widget.onOpenDrawer!();
              } else {
                Scaffold.of(ctx).openDrawer();
              }
            },
          ),
        ),
        title: const Text(
          'Data Siswa',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Box & Filter Kelas
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Text Field: Cari nama/NISN (sesuai wireframe)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari nama/NISN',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Filter Chip Kelas
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _kelasList.map((kelas) {
                        final isSelected = _selectedKelas == kelas;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => setState(() => _selectedKelas = kelas),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
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
                                kelas == 'Semua' ? 'Semua Kelas' : 'Kelas $kelas',
                                style: TextStyle(
                                  fontSize: 12,
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
                ],
              ),
            ),

            const Divider(height: 1),

            // Daftar Siswa
            Expanded(
              child: _filteredSiswa.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Siswa tidak ditemukan',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredSiswa.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final siswa = _filteredSiswa[index];
                        return _buildSiswaCard(siswa, brandColor);
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
        onPressed: () => _showAddSiswaSheet(context),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildSiswaCard(SiswaModel siswa, Color brandColor) {
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
          onTap: () => _showSiswaDetailSheet(context, siswa, brandColor),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: brandColor.withOpacity(0.1),
                  child: Text(
                    siswa.nama.isNotEmpty ? siswa.nama[0] : 'S',
                    style: TextStyle(
                      color: brandColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        siswa.nama,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'NISN: ${siswa.nisn} · Kelas ${siswa.kelas}',
                        style: TextStyle(
                          fontSize: 12,
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

  void _showSiswaDetailSheet(
      BuildContext context, SiswaModel siswa, Color brandColor) {
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
                const Text(
                  'Detail Siswa',
                  style: TextStyle(
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
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: brandColor.withOpacity(0.12),
                child: Text(
                  siswa.nama[0],
                  style: TextStyle(
                    color: brandColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              title: Text(
                siswa.nama,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text('Status: ${siswa.status}'),
            ),
            const Divider(),
            _buildDetailRow('NISN', siswa.nisn),
            _buildDetailRow('Kelas', siswa.kelas),
            _buildDetailRow('Jenis Kelamin',
                siswa.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan'),
            _buildDetailRow(
                'Nama Orang Tua / Wali',
                siswa.namaWali.isNotEmpty
                    ? siswa.namaWali
                    : 'Belum terhubung'),
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
                    content: Text('Membuka lembar nilai ${siswa.nama}...'),
                  ),
                );
              },
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('Lihat Rekap Nilai Siswa'),
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

  void _showAddSiswaSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final nisnCtrl = TextEditingController();
    final waliCtrl = TextEditingController();
    String selectedKelas = 'VII-A';
    String selectedJK = 'L';

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
                    'Tambah Siswa Baru',
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
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap Siswa',
                  hintText: 'Contoh: Ahmad Fauzan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nisnCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'NISN',
                  hintText: '10 digit angka',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedKelas,
                      decoration: InputDecoration(
                        labelText: 'Kelas',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _kelasList
                          .where((k) => k != 'Semua')
                          .map((k) => DropdownMenuItem(
                                value: k,
                                child: Text(k),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedKelas = val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedJK,
                      decoration: InputDecoration(
                        labelText: 'Jenis Kelamin',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'L', child: Text('Laki-laki')),
                        DropdownMenuItem(
                            value: 'P', child: Text('Perempuan')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedJK = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: waliCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Orang Tua / Wali',
                  hintText: 'Nama lengkap wali',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty ||
                      nisnCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nama dan NISN wajib diisi.'),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _daftarSiswa.insert(
                      0,
                      SiswaModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        nama: nameCtrl.text.trim(),
                        nisn: nisnCtrl.text.trim(),
                        kelas: selectedKelas,
                        jenisKelamin: selectedJK,
                        namaWali: waliCtrl.text.trim(),
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Siswa ${nameCtrl.text.trim()} berhasil ditambahkan.',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Simpan Data Siswa',
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

import 'package:flutter/material.dart';
import '../../models/guru_model.dart';

class AdminDataGuruScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const AdminDataGuruScreen({
    super.key,
    this.onOpenDrawer,
  });

  @override
  State<AdminDataGuruScreen> createState() => _AdminDataGuruScreenState();
}

class _AdminDataGuruScreenState extends State<AdminDataGuruScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<GuruModel> _daftarGuru = [
    const GuruModel(
      id: '1',
      nama: 'Ust. Zulkifli, S.Pd.I',
      nip: '198503152010011012',
      mapel: "Al-Qur'an Hadits",
      waliKelas: 'VII-A',
      email: 'zulkifli@mtsalfajar.sch.id',
      telepon: '081234567890',
    ),
    const GuruModel(
      id: '2',
      nama: 'Ibu Nur Azizah, S.Pd',
      nip: '198906222015022008',
      mapel: 'Matematika',
      waliKelas: 'VIII-B',
      email: 'nur.azizah@mtsalfajar.sch.id',
      telepon: '081234567891',
    ),
    const GuruModel(
      id: '3',
      nama: 'Ust. M. Rasyid, Lc',
      nip: '198711092012011005',
      mapel: 'Fiqih',
      waliKelas: 'IX-A',
      email: 'm.rasyid@mtsalfajar.sch.id',
      telepon: '081234567892',
    ),
    const GuruModel(
      id: '4',
      nama: 'Ust. Ahmad Fauzi, S.Pd.I',
      nip: '199002142018031002',
      mapel: 'Bahasa Arab',
      email: 'ahmad.fauzi@mtsalfajar.sch.id',
      telepon: '081234567893',
    ),
    const GuruModel(
      id: '5',
      nama: 'Ibu Siti Rahma, S.Si',
      nip: '199204182019022004',
      mapel: 'IPA Terpadu',
      waliKelas: 'VIII-A',
      email: 'siti.rahma@mtsalfajar.sch.id',
      telepon: '081234567894',
    ),
    const GuruModel(
      id: '6',
      nama: 'Bpk. Hendra Wijaya, M.Pd',
      nip: '198207102008011003',
      mapel: 'Bahasa Inggris',
      email: 'hendra.wijaya@mtsalfajar.sch.id',
      telepon: '081234567895',
    ),
  ];

  List<GuruModel> get _filteredGuru {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _daftarGuru;
    return _daftarGuru.where((guru) {
      return guru.nama.toLowerCase().contains(query) ||
          guru.nip.toLowerCase().contains(query) ||
          guru.mapel.toLowerCase().contains(query);
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
          'Data Guru',
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
            // Search Input Container (Cari...)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari...',
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
            ),

            const Divider(height: 1),

            // Daftar Guru
            Expanded(
              child: _filteredGuru.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Guru tidak ditemukan',
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
                      itemCount: _filteredGuru.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final guru = _filteredGuru[index];
                        return _buildGuruCard(guru, brandColor);
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
        onPressed: () => _showAddGuruSheet(context),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildGuruCard(GuruModel guru, Color brandColor) {
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
          onTap: () => _showGuruDetailSheet(context, guru, brandColor),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                  child: Text(
                    guru.nama.isNotEmpty ? guru.nama[0] : 'G',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
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
                        guru.nama,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'NIP ${guru.nip} · Mapel ${guru.mapel}',
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

  void _showGuruDetailSheet(
      BuildContext context, GuruModel guru, Color brandColor) {
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
                  'Detail Guru',
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
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
                child: Text(
                  guru.nama[0],
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              title: Text(
                guru.nama,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text('Guru Mapel: ${guru.mapel}'),
            ),
            const Divider(),
            _buildDetailRow('NIP', guru.nip),
            _buildDetailRow('Mata Pelajaran', guru.mapel),
            _buildDetailRow('Wali Kelas',
                guru.waliKelas != null ? 'Kelas ${guru.waliKelas}' : 'Bukan Wali Kelas'),
            _buildDetailRow('Email', guru.email),
            _buildDetailRow('Nomor Telepon', guru.telepon),
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
                    content: Text('Membuka jadwal mengajar ${guru.nama}...'),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: const Text('Lihat Jadwal Mengajar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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

  void _showAddGuruSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final nipCtrl = TextEditingController();
    final mapelCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
                  'Tambah Guru Baru',
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
                labelText: 'Nama Lengkap & Gelar',
                hintText: 'Contoh: Ust. Ahmad Fauzi, S.Pd.I',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nipCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'NIP / NUPTK',
                hintText: '18 digit nomor',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: mapelCtrl,
              decoration: InputDecoration(
                labelText: 'Mata Pelajaran yang Diampu',
                hintText: "Contoh: Fiqih / Matematika",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Resmi',
                hintText: 'guru@mtsalfajar.sch.id',
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
                    nipCtrl.text.trim().isEmpty ||
                    mapelCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama, NIP, dan Mapel wajib diisi.'),
                    ),
                  );
                  return;
                }
                setState(() {
                  _daftarGuru.insert(
                    0,
                    GuruModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      nama: nameCtrl.text.trim(),
                      nip: nipCtrl.text.trim(),
                      mapel: mapelCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                    ),
                  );
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Guru ${nameCtrl.text.trim()} berhasil ditambahkan.',
                    ),
                  ),
                );
              },
              child: const Text(
                'Simpan Data Guru',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

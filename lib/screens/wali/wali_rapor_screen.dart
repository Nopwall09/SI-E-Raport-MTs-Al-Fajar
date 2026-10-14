import 'package:flutter/material.dart';
import '../../models/rapor_model.dart';
import '../../widgets/trend_chart_widget.dart';

class WaliRaporScreen extends StatefulWidget {
  final VoidCallback? onSwitchRole;
  final VoidCallback? onLogout;

  const WaliRaporScreen({
    super.key,
    this.onSwitchRole,
    this.onLogout,
  });

  @override
  State<WaliRaporScreen> createState() => _WaliRaporScreenState();
}

class _WaliRaporScreenState extends State<WaliRaporScreen> {
  String _selectedSemester = 'Semester 1 (Ganjil)';
  String _selectedTA = 'TA 2025/2026';

  final List<String> _semesterOptions = [
    'Semester 1 (Ganjil)',
    'Semester 2 (Genap)',
  ];

  final List<String> _taOptions = [
    'TA 2025/2026',
    'TA 2024/2025',
  ];

  final SiswaProfile _siswa = const SiswaProfile(
    nama: 'Muhammad Farhan Al-Ghifari',
    kelas: 'VII-A',
    nisn: '0089765432',
    rataRata: 87.8,
    catatanWali:
        'Ananda Farhan menunjukkan adab yang sangat baik dan peningkatan pesat dalam mata pelajaran Tahfidz & Fiqih. Terus pertahankan semangat belajarnya!',
    sakit: 1,
    izin: 0,
    alfa: 0,
    historiPerkembangan: [82.0, 84.5, 85.0, 86.8, 87.8],
  );

  final List<NilaiMapel> _daftarNilai = const [
    NilaiMapel(
      namaMapel: "Al-Qur'an Hadits",
      nilai: 92,
      tanggalUpdate: '14 Okt',
      kategori: 'Agama',
    ),
    NilaiMapel(
      namaMapel: 'Akidah Akhlak',
      nilai: 90,
      tanggalUpdate: '12 Okt',
      kategori: 'Agama',
    ),
    NilaiMapel(
      namaMapel: 'Fiqih',
      nilai: 88,
      tanggalUpdate: '13 Okt',
      kategori: 'Agama',
    ),
    NilaiMapel(
      namaMapel: 'Sejarah Kebudayaan Islam',
      nilai: 85,
      tanggalUpdate: '10 Okt',
      kategori: 'Agama',
    ),
    NilaiMapel(
      namaMapel: 'Bahasa Arab',
      nilai: 86,
      tanggalUpdate: '11 Okt',
      kategori: 'Bahasa',
    ),
    NilaiMapel(
      namaMapel: 'Matematika',
      nilai: 82,
      tanggalUpdate: '12 Okt',
      kategori: 'Umum',
    ),
    NilaiMapel(
      namaMapel: 'Bahasa Indonesia',
      nilai: 89,
      tanggalUpdate: '09 Okt',
      kategori: 'Bahasa',
    ),
    NilaiMapel(
      namaMapel: 'IPA Terpadu',
      nilai: 85,
      tanggalUpdate: '11 Okt',
      kategori: 'Umum',
    ),
    NilaiMapel(
      namaMapel: 'Bahasa Inggris',
      nilai: 84,
      tanggalUpdate: '08 Okt',
      kategori: 'Bahasa',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF0D5C3A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 1,
        title: const Text(
          'e-Rapor Orang Tua',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              if (widget.onLogout != null) {
                widget.onLogout!();
              } else {
                _showLogoutDialog(context);
              }
            },
            icon: const Icon(Icons.logout, size: 16, color: Colors.redAccent),
            label: const Text(
              'Keluar',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Identitas Siswa (Anak)
              _buildStudentHeader(brandColor),

              const SizedBox(height: 14),

              // Filter Dropdowns: Semester & TA
              _buildFilterRow(brandColor),

              const SizedBox(height: 16),

              // Rata-rata Nilai & Perkembangan (Grafik)
              _buildAverageAndChartCard(brandColor),

              const SizedBox(height: 18),

              // Tabel Nilai Mata Pelajaran
              _buildGradesTable(brandColor),

              const SizedBox(height: 16),

              // Catatan Wali Kelas & Kehadiran
              _buildAttendanceAndNotesCard(),

              const SizedBox(height: 20),

              // Tombol Lihat dan Unduh Rapor
              _buildDownloadButton(context, brandColor),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentHeader(Color brandColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: brandColor.withOpacity(0.12),
            child: Text(
              _siswa.nama.isNotEmpty ? _siswa.nama[0] : 'S',
              style: TextStyle(
                color: brandColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anak',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _siswa.nama,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Kelas ${_siswa.kelas} · NISN ${_siswa.nisn}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(Color brandColor) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSemester,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                items: _semesterOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSemester = val);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTA,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                items: _taOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTA = val);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAverageAndChartCard(Color brandColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rata-rata nilai',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _siswa.rataRata.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D5C3A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Text(
                          'Predikat A',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: brandColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_graph_rounded, color: brandColor, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.show_chart, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              Text(
                'Perkembangan: [grafik sederhana]',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TrendChartWidget(
            values: _siswa.historiPerkembangan,
            labels: const ['UH 1', 'UH 2', 'PTS', 'UH 3', 'PAS'],
          ),
        ],
      ),
    );
  }

  Widget _buildGradesTable(Color brandColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header
          Container(
            color: const Color(0xFFE2E8F0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Mata Pelajaran',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Nilai',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Update',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _daftarNilai.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final item = _daftarNilai[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        item.namaMapel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.nilai >= 85
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item.nilai}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: item.nilai >= 85
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.tanggalUpdate,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceAndNotesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Catatan wali kelas',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Kehadiran: S ${_siswa.sakit} · I ${_siswa.izin} · A ${_siswa.alfa}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"${_siswa.catatanWali}"',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context, Color brandColor) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFFE2E8F0),
        foregroundColor: const Color(0xFF0F172A),
        side: const BorderSide(color: Color(0xFF334155), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Menyiapkan unduhan rapor semester lengkap (PDF)...',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
      label: const Text(
        'Lihat dan Unduh Rapor (akhir semester)',
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari e-Rapor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Berhasil keluar.')),
              );
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

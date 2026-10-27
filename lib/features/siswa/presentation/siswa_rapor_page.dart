import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../widgets/motion.dart';
import '../../admin/presentation/admin_widgets.dart';
import '../data/siswa_repository.dart';
import 'lembar_rapor_dialog.dart';
import 'siswa_providers.dart';

/// Halaman Rapor Siswa: Menampilkan riwayat nilai mata pelajaran per semester,
/// status kelulusan/peringkat, dan opsi unduh lembar rapor digital.
class SiswaRaporPage extends ConsumerStatefulWidget {
  const SiswaRaporPage({super.key});

  @override
  ConsumerState<SiswaRaporPage> createState() => _SiswaRaporPageState();
}

class _SiswaRaporPageState extends ConsumerState<SiswaRaporPage> {
  String _kategoriDipilih = 'Semua';

  @override
  Widget build(BuildContext context) {
    final semesterAktif = ref.watch(siswaSemesterFilterProvider);
    final raporAsync = ref.watch(siswaRaporProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapor Siswa'),
        actions: [
          IconButton(
            tooltip: 'Segarkan data',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(siswaRaporProvider),
          ),
        ],
      ),
      body: statusAsync(raporAsync, () => ref.invalidate(siswaRaporProvider)) ??
          RefreshIndicator(
            color: kBrand,
            onRefresh: () async {
              ref.invalidate(siswaRaporProvider);
              try {
                await ref.read(siswaRaporProvider.future);
              } catch (_) {}
            },
            child: _buildBody(
              context: context,
              rapor: raporAsync.value!,
              semesterAktif: semesterAktif,
            ),
          ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required RaporSiswaModel rapor,
    required String semesterAktif,
  }) {
    final filteredNilai = _kategoriDipilih == 'Semua'
        ? rapor.daftarNilai
        : rapor.daftarNilai.where((m) => m.kategori == _kategoriDipilih).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // 1. PEMILIH SEMESTER (GANJIL / GENAP)
        FadeSlideIn(
          index: 0,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kField,
              borderRadius: BorderRadius.circular(kRadiusControl),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _tombolSemester(
                    label: 'Semester Ganjil',
                    isActive: semesterAktif == 'ganjil',
                    onTap: () {
                      ref.read(siswaSemesterFilterProvider.notifier).state = 'ganjil';
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _tombolSemester(
                    label: 'Semester Genap',
                    isActive: semesterAktif == 'genap',
                    onTap: () {
                      ref.read(siswaSemesterFilterProvider.notifier).state = 'genap';
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. KARTU STATUS KELULUSAN & PERINGKAT KELAS
        FadeSlideIn(
          index: 1,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D5C3A), Color(0xFF147A4E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(kRadiusCard),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D5C3A).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rapor.profil.nama,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Kelas ${rapor.profil.kelas} • NISN ${rapor.profil.nisn ?? rapor.profil.nis}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'TA ${rapor.tahunAjaran}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // BADGE STATUS KELULUSAN
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Status: ${rapor.statusKelulusan}',
                        style: const TextStyle(
                          color: Color(0xFF0D5C3A),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // BARIS STATISTIK PERINGKAT & NILAI
                Row(
                  children: [
                    _itemStatistikKecil(
                      label: 'Peringkat Kelas',
                      value: 'Ke-${rapor.peringkat}',
                      subtext: 'dari ${rapor.totalSiswaKelas} Siswa',
                    ),
                    Container(
                      height: 36,
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.25),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    _itemStatistikKecil(
                      label: 'Rata-Rata Nilai',
                      value: '${rapor.rataRata}',
                      subtext: 'Rata-rata kelas: ${rapor.rataRataKelas}',
                    ),
                    Container(
                      height: 36,
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.25),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    _itemStatistikKecil(
                      label: 'Mapel Tuntas',
                      value: '${rapor.mapelTuntas}/${rapor.totalMapel}',
                      subtext: rapor.semuaTuntas ? '100% Tuntas' : 'Perlu Remedial',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. TOMBOL UNDUH LEMBAR RAPOR DIGITAL
        FadeSlideIn(
          index: 2,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(color: kBorder),
              boxShadow: kCardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kBrandSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: kBrand, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Lembar Rapor Digital Sah',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kText,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Dilengkapi QR Code verifikasi & tanda tangan kepala madrasah.',
                        style: TextStyle(fontSize: 11.5, color: kMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kBrand,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusControl),
                    ),
                  ),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text(
                    'Unduh',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => LembarRaporDialog.show(context, rapor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 4. HEADER DAFTAR NILAI & FILTER KATEGORI MAPEL
        FadeSlideIn(
          index: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Nilai Mata Pelajaran',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kText,
                ),
              ),
              Text(
                'SKM: 75',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // FILTER CHIP KATEGORI (Semua, Agama, Bahasa, Umum)
        FadeSlideIn(
          index: 4,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chipKategori('Semua'),
                const SizedBox(width: 8),
                _chipKategori('Agama'),
                const SizedBox(width: 8),
                _chipKategori('Bahasa'),
                const SizedBox(width: 8),
                _chipKategori('Umum'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 5. DAFTAR KARTU NILAI TIAP MAPEL
        for (var i = 0; i < filteredNilai.length; i++)
          FadeSlideIn(
            index: 5 + i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _kartuNilaiMapel(filteredNilai[i]),
            ),
          ),
        const SizedBox(height: 14),

        // 6. CATATAN WALI KELAS & REKAP ABSENSI
        FadeSlideIn(
          index: 5 + filteredNilai.length,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(color: kBorder),
              boxShadow: kCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.rate_review_outlined, color: kBrand, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Catatan Wali Kelas',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const Spacer(),
                    Text(
                      rapor.profil.waliKelas ?? 'Wali Kelas',
                      style: const TextStyle(fontSize: 11, color: kMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '"${rapor.catatanWali}"',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                    color: Color(0xFF334155),
                  ),
                ),
                const Divider(height: 24),

                // Rekap Absensi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _itemAbsensi('Sakit', '${rapor.sakit} Hari', Colors.blue),
                    _itemAbsensi('Izin', '${rapor.izin} Hari', Colors.amber.shade800),
                    _itemAbsensi('Alpa', '${rapor.alpa} Hari', Colors.red),
                    _itemAbsensi(
                      'Kehadiran',
                      '${rapor.persentaseKehadiran.toStringAsFixed(1)}%',
                      const Color(0xFF16A34A),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tombolSemester({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadiusControl - 2),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(kRadiusControl - 2),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? kBrand : kMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemStatistikKecil({
    required String label,
    required String value,
    required String subtext,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 9.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _chipKategori(String kategori) {
    final isSelected = _kategoriDipilih == kategori;
    return ChoiceChip(
      label: Text(kategori),
      selected: isSelected,
      onSelected: (_) => setState(() => _kategoriDipilih = kategori),
      selectedColor: kBrandSoft,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? kBrand : kBorder),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? kBrand : kText,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }

  Widget _kartuNilaiMapel(NilaiMapelSiswa m) {
    final nilai = m.nilai;
    final nilaiTeks = nilai == null ? '-' : (nilai % 1 == 0 ? nilai.toInt().toString() : nilai.toString());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kBorder),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Badge Kategori Mapel
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kField,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  m.kode ?? m.kategori,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: kMuted,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  m.mapel,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: kText,
                  ),
                ),
              ),
              // Nilai Angka
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: m.isTuntas
                      ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      nilaiTeks,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: m.isTuntas ? const Color(0xFF16A34A) : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${m.predikat})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: m.isTuntas ? const Color(0xFF16A34A) : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Bar SKM
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: nilai == null ? 0 : (nilai / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    color: m.isTuntas ? kBrand : Colors.red,
                    backgroundColor: kField,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'SKM: ${m.skm}',
                style: const TextStyle(fontSize: 11, color: kMuted),
              ),
            ],
          ),
          if (m.catatanGuru != null) ...[
            const SizedBox(height: 8),
            Text(
              m.catatanGuru!,
              style: const TextStyle(fontSize: 11.5, color: kMuted, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemAbsensi(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: kMuted)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}


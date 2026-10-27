import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/services/pdf_rapor_service.dart';
import '../../../core/storage/local_storage_service.dart';
import '../data/siswa_repository.dart';

/// Modal dialog pratinjau lembar rapor standar resmi sekolah (format baku madrasah)
/// yang siap diunduh / dicetak oleh siswa.
class LembarRaporDialog extends StatefulWidget {
  const LembarRaporDialog({super.key, required this.rapor});

  final RaporSiswaModel rapor;

  static Future<void> show(BuildContext context, RaporSiswaModel rapor) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LembarRaporDialog(rapor: rapor),
    );
  }

  @override
  State<LembarRaporDialog> createState() => _LembarRaporDialogState();
}

class _LembarRaporDialogState extends State<LembarRaporDialog> {
  bool _isDownloading = false;
  PdfDownloadResult? _downloadResult;

  Future<void> _unduhRapor() async {
    setState(() => _isDownloading = true);

    try {
      final result = await PdfRaporService.downloadRaporPdf(rapor: widget.rapor);

      final storage = LocalStorageService();
      await storage.simpanString(
        'rapor_terunduh_${widget.rapor.profil.nis}_${widget.rapor.semester}',
        DateTime.now().toIso8601String(),
      );
      await storage.simpanString(
        'rapor_lokasi_${widget.rapor.profil.nis}_${widget.rapor.semester}',
        result.filePath,
      );

      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _downloadResult = result;
      });

      _tampilkanDialogSukses(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          content: Text('Gagal mengunduh berkas: $e'),
        ),
      );
    }
  }

  Future<void> _bukaBerkas(PdfDownloadResult result) async {
    final opened = await PdfRaporService.openPdf(
      contentUri: result.contentUri,
      filePath: result.filePath,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kBrand,
          content: Text(
            'Berkas tersimpan di: ${result.filePath}.\nBuka lewat aplikasi Pengelola File HP.',
          ),
        ),
      );
    }
  }

  void _tampilkanDialogSukses(PdfDownloadResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Unduh Rapor Berhasil',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Berkas PDF Lembar Rapor ${widget.rapor.profil.nama} telah tersimpan di folder Download HP Anda.',
              style: const TextStyle(fontSize: 13, color: kText, height: 1.4),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _itemDetail('Nama Berkas', result.fileName, isBold: true),
                  const SizedBox(height: 6),
                  _itemDetail('Ukuran Berkas', result.fileSizeFormatted),
                  const SizedBox(height: 6),
                  _itemDetail('Lokasi Simpan', result.filePath),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.notifications_active, color: Color(0xFF2563EB), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notifikasi unduhan telah muncul di HP Anda. Ketuk tombol di bawah untuk langsung membuka rapor.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                    ),
                  ),
                ],
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
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _bukaBerkas(result);
            },
            icon: const Icon(Icons.open_in_new, size: 18, color: Colors.white),
            label: const Text(
              'Buka File PDF Sekarang',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemDetail(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: kText,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rapor;
    final p = r.profil;
    final isDownloaded = _downloadResult != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Bar tombol atas
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 16, 10),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, color: Colors.black87),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Pratinjau Rapor Resmi',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: kText,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              if (isDownloaded)
                Container(
                  color: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tersimpan: ${_downloadResult!.fileName}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text('Buka PDF', style: TextStyle(fontSize: 12)),
                        onPressed: () => _bukaBerkas(_downloadResult!),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 1),

              // LEMBAR RAPOR KERTAS STANDAR RESMI
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade400, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. KOP SURAT STANDAR MADRASAH
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/Logo.png',
                                width: 50,
                                height: 50,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.school,
                                  size: 44,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'KEMENTERIAN AGAMA REPUBLIK INDONESIA',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'KANTOR KEMENTERIAN AGAMA KABUPATEN KEDIRI',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'MADRASAH TSANAWIYAH AL FAJAR KANDAT',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Jl. Raya Kandat No. 45 Kec. Kandat Kab. Kediri Telp. (0354) 671234 | NPSN: 20582415',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Garis Ganda Kop Surat
                          Container(height: 2.0, color: Colors.black),
                          const SizedBox(height: 1.5),
                          Container(height: 0.8, color: Colors.black),
                          const SizedBox(height: 14),

                          // 2. JUDUL RAPOR
                          const Center(
                            child: Text(
                              'LAPORAN CAPAIAN HASIL BELAJAR PESERTA DIDIK',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3. TABEL DATA IDENTITAS SISWA (STANDAR RESMI)
                          Table(
                            columnWidths: const {
                              0: FlexColumnWidth(4.5),
                              1: FlexColumnWidth(5.5),
                            },
                            children: [
                              TableRow(
                                children: [
                                  _barisData('Nama Siswa', p.nama, isBold: true),
                                  _barisData('Kelas / Rombel', p.kelas, isBold: true),
                                ],
                              ),
                              TableRow(
                                children: [
                                  _barisData('NIS / NISN', '${p.nis} / ${p.nisn ?? "-"}'),
                                  _barisData('Semester', r.semester),
                                ],
                              ),
                              TableRow(
                                children: [
                                  _barisData('Madrasah', 'MTs Al Fajar Kandat'),
                                  _barisData('Tahun Ajaran', r.tahunAjaran),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 4. TABEL NILAI MATA PELAJARAN (STANDAR)
                          const Text(
                            'A. Nilai Capaian Akademik',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildTabelNilaiStandar(r),
                          const SizedBox(height: 14),

                          // 5. KETIDAKHADIRAN & CATATAN WALI KELAS (STANDAR)
                          const Text(
                            'B. Ketidakhadiran & Catatan Perkembangan',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tabel Ketidakhadiran
                              Expanded(
                                flex: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black87, width: 0.8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        color: const Color(0xFFF1F5F9),
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: const Center(
                                          child: Text(
                                            'Ketidakhadiran',
                                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const Divider(height: 1, thickness: 0.8, color: Colors.black87),
                                      _barisAbsen('1. Sakit', '${r.sakit} hari'),
                                      const Divider(height: 1, thickness: 0.5),
                                      _barisAbsen('2. Izin', '${r.izin} hari'),
                                      const Divider(height: 1, thickness: 0.5),
                                      _barisAbsen('3. Tanpa Keterangan', '${r.alpa} hari'),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Kotak Catatan Wali Kelas
                              Expanded(
                                flex: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black87, width: 0.8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Catatan Wali Kelas:',
                                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        r.catatanWali,
                                        style: const TextStyle(fontSize: 9, height: 1.3),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Tingkat Kehadiran: ${r.persentaseKehadiran.toStringAsFixed(1)}%',
                                        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 6. TANDA TANGAN STANDAR 3 PIHAK (RESMI)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Kediri, ${r.tanggalTerbit}',
                                style: const TextStyle(fontSize: 9.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Orang Tua
                              Expanded(
                                child: Column(
                                  children: const [
                                    Text('Orang Tua / Wali,', style: TextStyle(fontSize: 9.5)),
                                    SizedBox(height: 46),
                                    Text('( ................................. )', style: TextStyle(fontSize: 9.5)),
                                  ],
                                ),
                              ),

                              // 2. Wali Kelas
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text('Wali Kelas,', style: TextStyle(fontSize: 9.5)),
                                    const SizedBox(height: 46),
                                    Text(
                                      p.waliKelas ?? 'Ust. Ahmad Fauzi, S.Pd.I',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const Text('NIP. 198504122011011003', style: TextStyle(fontSize: 8)),
                                  ],
                                ),
                              ),

                              // 3. Kepala Madrasah
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text('Mengetahui,\nKepala Madrasah,', style: TextStyle(fontSize: 9.5), textAlign: TextAlign.center),
                                    const SizedBox(height: 34),
                                    Text(
                                      p.kepalaMadrasah,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const Text('NIP. 196807121994031002', style: TextStyle(fontSize: 8)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bar Aksi Bawah
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(top: BorderSide(color: kBorder)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.black87),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kRadiusControl),
                            ),
                          ),
                          icon: const Icon(Icons.print, color: Colors.black87, size: 20),
                          label: const Text(
                            'Cetak',
                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isDownloading
                              ? null
                              : () async {
                                  if (!isDownloaded) {
                                    await _unduhRapor();
                                  } else {
                                    await _bukaBerkas(_downloadResult!);
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: isDownloaded ? const Color(0xFF16A34A) : kBrand,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kRadiusControl),
                            ),
                          ),
                          icon: _isDownloading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isDownloaded ? Icons.open_in_new : Icons.download,
                                  color: Colors.white,
                                  size: 20,
                                ),
                          label: Text(
                            _isDownloading
                                ? 'Menyusun PDF...'
                                : (isDownloaded ? 'Buka File PDF' : 'Unduh Rapor (PDF)'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _isDownloading
                              ? null
                              : () async {
                                  if (!isDownloaded) {
                                    await _unduhRapor();
                                  } else {
                                    await _bukaBerkas(_downloadResult!);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _barisData(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.black87)),
          ),
          const Text(': ', style: TextStyle(fontSize: 9.5)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisAbsen(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 8.5)),
          Text(value, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTabelNilaiStandar(RaporSiswaModel r) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87, width: 0.8),
      ),
      child: Column(
        children: [
          // Header Tabel
          Container(
            color: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            child: Row(
              children: const [
                SizedBox(
                  width: 24,
                  child: Text('No', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 5,
                  child: Text('Mata Pelajaran', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 32,
                  child: Text('KKM', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 36,
                  child: Text('Nilai', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 32,
                  child: Text('Pred', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Capaian', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.8, color: Colors.black87),

          // Baris-baris Nilai
          for (var i = 0; i < r.daftarNilai.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('${i + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 8.5)),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      r.daftarNilai[i].mapel,
                      style: const TextStyle(fontSize: 8.5),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${r.daftarNilai[i].skm}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 8.5),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      r.daftarNilai[i].nilai == null
                          ? '-'
                          : (r.daftarNilai[i].nilai! % 1 == 0
                              ? r.daftarNilai[i].nilai!.toInt().toString()
                              : r.daftarNilai[i].nilai!.toString()),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      r.daftarNilai[i].predikat,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.daftarNilai[i].isTuntas ? 'Tuntas' : 'Remedial',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 8),
                    ),
                  ),
                ],
              ),
            ),
            if (i < r.daftarNilai.length - 1)
              const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          ],

          const Divider(height: 1, thickness: 0.8, color: Colors.black87),

          // Baris Total / Rata-rata
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: [
                const SizedBox(width: 24),
                const Expanded(
                  flex: 5,
                  child: Text(
                    'Rata-rata Nilai',
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(
                  width: 32,
                  child: Text('-', textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5)),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${r.rataRata}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    r.rataRata >= 80 ? 'B' : 'C',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    r.statusKelulusan,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'wali_kelas_repository.dart';

/// Layanan untuk menyusun dokumen PDF Rekapitulasi Presensi Siswa (UC-19)
/// dan menampilkannya langsung ke pratinjau / dialog cetak.
class AbsensiPdfService {
  const AbsensiPdfService._();

  /// Menghasilkan berkas PDF rekapitulasi presensi satu kelas.
  static Future<Uint8List> buatDokumenPresensi({
    required List<SiswaProgres> siswa,
    required String kelasNama,
    required String semester,
    required String tahunAjaran,
    String? waliKelasNama,
    String? kepalaMadrasahNama,
  }) async {
    final doc = pw.Document();

    // Muat logo sekolah jika tersedia
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/Logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      // Abaikan bila logo tidak ditemukan
    }

    final semesterLabel = semester.toLowerCase() == 'ganjil' ? 'GANJIL' : 'GENAP';
    final tanggalCetak = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());

    int totalSakit = 0;
    int totalIzin = 0;
    int totalAlpa = 0;
    for (final s in siswa) {
      totalSakit += s.sakit;
      totalIzin += s.izin;
      totalAlpa += s.alpa;
    }
    final totalKetidakhadiran = totalSakit + totalIzin + totalAlpa;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        build: (pw.Context context) {
          return [
            // ---- KOP MADRASAH ----
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 55,
                    height: 55,
                    margin: const pw.EdgeInsets.only(right: 14),
                    child: pw.Image(logoImage),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'YAYASAN PENDIDIKAN ISLAM AL FAJAR',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'MADRASAH TSANAWIYAH AL FAJAR KANDAT',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1B4D3E'),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'NSM: 121235060045 · NPSN: 20582524 · Akreditasi A',
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                      pw.Text(
                        'Jl. Raya Kandat No. 45, Kec. Kandat, Kab. Kediri, Jawa Timur 64173',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            // Garis pembatas kop ganda
            pw.Container(
              height: 2,
              color: PdfColors.black,
            ),
            pw.SizedBox(height: 1),
            pw.Container(
              height: 0.8,
              color: PdfColors.black,
            ),
            pw.SizedBox(height: 14),

            // ---- JUDUL DOKUMEN ----
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'REKAPITULASI PRESENSI SISWA',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'SEMESTER $semesterLabel TAHUN AJARAN $tahunAjaran',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // ---- IDENTITAS KELAS ----
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Text('Kelas: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text(kelasNama, style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text('Wali Kelas: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text(waliKelasNama ?? '-', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // ---- TABEL REKAP PRESENSI ----
            pw.TableHelper.fromTextArray(
              headers: ['No', 'NIS', 'Nama Siswa', 'Sakit', 'Izin', 'Alpa', 'Total', 'Keterangan'],
              data: [
                for (var i = 0; i < siswa.length; i++)
                  [
                    '${i + 1}',
                    siswa[i].nis,
                    siswa[i].nama,
                    '${siswa[i].sakit}',
                    '${siswa[i].izin}',
                    '${siswa[i].alpa}',
                    '${siswa[i].sakit + siswa[i].izin + siswa[i].alpa}',
                    siswa[i].catatan ?? '-',
                  ],
              ],
              headerStyle: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1B4D3E'),
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
                7: pw.Alignment.centerLeft,
              },
              cellStyle: const pw.TextStyle(fontSize: 8),
              columnWidths: {
                0: const pw.FixedColumnWidth(26),
                1: const pw.FixedColumnWidth(55),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FixedColumnWidth(38),
                4: const pw.FixedColumnWidth(38),
                5: const pw.FixedColumnWidth(38),
                6: const pw.FixedColumnWidth(40),
                7: const pw.FlexColumnWidth(2),
              },
            ),

            // Baris Total Ringkasan
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F4F6F4'),
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'TOTAL KETIDAKHADIRAN KELAS',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Text(
                    'Sakit: $totalSakit  ·  Izin: $totalIzin  ·  Alpa: $totalAlpa  ·  Jumlah: $totalKetidakhadiran',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // ---- PENGESAHAN (TANDA TANGAN) ----
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Mengetahui,', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Kepala MTs Al Fajar', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 50),
                    pw.Text(
                      kepalaMadrasahNama ?? 'Drs. H. Moh. Syamsuddin, M.Pd.I',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                    ),
                    pw.Text('NIP. -', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Kandat, $tanggalCetak', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Wali Kelas $kelasNama', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 50),
                    pw.Text(
                      waliKelasNama ?? '( .................................................. )',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                    ),
                    pw.Text('NIP. -', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  /// Menampilkan pratinjau PDF di layar bawaan perangkat dengan opsi cetak / download.
  static Future<void> cetakAtauPratinjauPdf({
    required List<SiswaProgres> siswa,
    required String kelasNama,
    required String semester,
    required String tahunAjaran,
    String? waliKelasNama,
    String? kepalaMadrasahNama,
  }) async {
    final pdfBytes = await buatDokumenPresensi(
      siswa: siswa,
      kelasNama: kelasNama,
      semester: semester,
      tahunAjaran: tahunAjaran,
      waliKelasNama: waliKelasNama,
      kepalaMadrasahNama: kepalaMadrasahNama,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Rekap_Presensi_${kelasNama}_Semester_$semester.pdf',
    );
  }
}

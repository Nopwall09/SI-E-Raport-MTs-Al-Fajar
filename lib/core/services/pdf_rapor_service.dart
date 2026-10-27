import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/siswa/data/siswa_repository.dart';

class PdfDownloadResult {
  const PdfDownloadResult({
    this.file,
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    this.contentUri,
    this.storageUrl,
    required this.isSavedLocally,
    this.isUploadedToStorage = false,
    this.errorMessage,
  });

  final File? file;
  final String filePath;
  final String fileName;
  final int fileSizeBytes;
  final String? contentUri;
  final String? storageUrl;
  final bool isSavedLocally;
  final bool isUploadedToStorage;
  final String? errorMessage;

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    final kb = fileSizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class _LogoImageInfo {
  const _LogoImageInfo({
    required this.rgbBytes,
    required this.width,
    required this.height,
  });

  final Uint8List rgbBytes;
  final int width;
  final int height;
}

/// Service untuk membuat dokumen PDF rapor standar resmi madrasah/sekolah
/// berstandar ISO 32000-1 (PDF 1.4) dengan logo resmi MTs Al Fajar di atas kiri Kop Kementerian Agama.
class PdfRaporService {
  const PdfRaporService();

  static const _channel = MethodChannel('com.example.si_e_rapor_mts_al_fajar/downloader');

  /// Membaca asset Logo.png dan mendekodenya menjadi raw 24-bit RGB (blended over white).
  static Future<_LogoImageInfo?> _loadLogoAsset() async {
    try {
      final ByteData data = await rootBundle.load('assets/Logo.png');
      final Uint8List pngBytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(pngBytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;

      final rgbaBytes = byteData.buffer.asUint8List();
      final width = image.width;
      final height = image.height;

      // Blend pixel RGBA ke latar putih agar menghasilkan 24-bit RGB murni yang tajam
      final rgbBytes = Uint8List(width * height * 3);
      var rgbIdx = 0;
      for (var i = 0; i < rgbaBytes.length; i += 4) {
        final r = rgbaBytes[i];
        final g = rgbaBytes[i + 1];
        final b = rgbaBytes[i + 2];
        final a = rgbaBytes[i + 3] / 255.0;

        rgbBytes[rgbIdx++] = ((r * a) + (255 * (1.0 - a))).round().clamp(0, 255);
        rgbBytes[rgbIdx++] = ((g * a) + (255 * (1.0 - a))).round().clamp(0, 255);
        rgbBytes[rgbIdx++] = ((b * a) + (255 * (1.0 - a))).round().clamp(0, 255);
      }

      return _LogoImageInfo(
        rgbBytes: rgbBytes,
        width: width,
        height: height,
      );
    } catch (_) {
      return null;
    }
  }

  /// Menghasilkan byte array PDF lembar rapor format standar resmi sekolah,
  /// lengkap dengan logo MTs Al Fajar di bagian atas kiri kop Kementerian Agama.
  static Uint8List generatePdfBytes(RaporSiswaModel rapor, [_LogoImageInfo? logoInfo]) {
    final builder = _PdfBuilder(logoInfo: logoInfo);
    final p = rapor.profil;

    // Posisi Logo MTs di Atas Kiri Kop (x=46, y=760, w=48, h=48)
    if (logoInfo != null) {
      builder.drawImage(46, 760, 48, 48);
    }

    // 1. KOP RESMI MADRASAH (Teks Sejajar dengan Logo di Kiri)
    const kopCenterX = 312.0;

    builder.drawText(
      'KEMENTERIAN AGAMA REPUBLIK INDONESIA',
      kopCenterX,
      805,
      isBold: true,
      size: 10,
      align: _TextAlign.center,
    );
    builder.drawText(
      'KANTOR KEMENTERIAN AGAMA KABUPATEN KEDIRI',
      kopCenterX,
      792,
      isBold: true,
      size: 9.5,
      align: _TextAlign.center,
    );
    builder.drawText(
      'MADRASAH TSANAWIYAH AL FAJAR KANDAT',
      kopCenterX,
      777,
      isBold: true,
      size: 13,
      align: _TextAlign.center,
    );
    builder.drawText(
      'Jl. Raya Kandat No. 45 Kec. Kandat Kab. Kediri | Telp: (0354) 671234 | NPSN: 20582415',
      kopCenterX,
      765,
      size: 7.8,
      align: _TextAlign.center,
      r: 0.2,
      g: 0.2,
      b: 0.2,
    );

    // Garis Ganda Pemisah Kop Surat Resmi
    builder.drawLine(40, 754, 555, 754, width: 1.8);
    builder.drawLine(40, 751, 555, 751, width: 0.6);

    // 2. JUDUL RAPOR
    builder.drawText(
      'LAPORAN CAPAIAN HASIL BELAJAR PESERTA DIDIK',
      297.6,
      734,
      isBold: true,
      size: 11,
      align: _TextAlign.center,
    );

    // 3. IDENTITAS SISWA (Format Baris Standar 2 Kolom)
    const labelX1 = 45.0;
    const valX1 = 150.0;
    const labelX2 = 330.0;
    const valX2 = 420.0;

    builder.drawText('Nama Peserta Didik', labelX1, 712, size: 8.5);
    builder.drawText(': ${p.nama}', valX1, 712, isBold: true, size: 8.5);

    builder.drawText('Kelas / Rombel', labelX2, 712, size: 8.5);
    builder.drawText(': ${p.kelas}', valX2, 712, isBold: true, size: 8.5);

    builder.drawText('NIS / NISN', labelX1, 699, size: 8.5);
    builder.drawText(': ${p.nis} / ${p.nisn ?? "-"}', valX1, 699, size: 8.5);

    builder.drawText('Semester', labelX2, 699, size: 8.5);
    builder.drawText(': ${rapor.semester}', valX2, 699, size: 8.5);

    builder.drawText('Nama Madrasah', labelX1, 686, size: 8.5);
    builder.drawText(': MTs Al Fajar Kandat', valX1, 686, size: 8.5);

    builder.drawText('Tahun Ajaran', labelX2, 686, size: 8.5);
    builder.drawText(': ${rapor.tahunAjaran}', valX2, 686, size: 8.5);

    // Garis pemisah identitas
    builder.drawLine(40, 678, 555, 678, width: 0.5, r: 0.6, g: 0.6, b: 0.6);

    // 4. TABEL CAPAIAN HASIL BELAJAR
    builder.drawText('A. Nilai Akademik & Capaian Belajar', 40, 665, isBold: true, size: 9);

    // Header Tabel
    const tableLeft = 40.0;
    const tableWidth = 515.0;
    const headerH = 17.0;
    const headerY = 644.0;

    builder.drawRect(
      tableLeft,
      headerY,
      tableWidth,
      headerH,
      fill: true,
      stroke: true,
      fillR: 0.92,
      fillG: 0.92,
      fillB: 0.92,
      strokeR: 0,
      strokeG: 0,
      strokeB: 0,
    );

    builder.drawText('No', 52, headerY + 5, isBold: true, size: 8, align: _TextAlign.center);
    builder.drawText('Mata Pelajaran', 70, headerY + 5, isBold: true, size: 8);
    builder.drawText('KKM', 305, headerY + 5, isBold: true, size: 8, align: _TextAlign.center);
    builder.drawText('Nilai', 345, headerY + 5, isBold: true, size: 8, align: _TextAlign.center);
    builder.drawText('Predikat', 390, headerY + 5, isBold: true, size: 8, align: _TextAlign.center);
    builder.drawText('Keterangan / Capaian', 475, headerY + 5, isBold: true, size: 8, align: _TextAlign.center);

    // Garis vertikal header
    builder.drawLine(65, headerY, 65, headerY + headerH, width: 0.5);
    builder.drawLine(285, headerY, 285, headerY + headerH, width: 0.5);
    builder.drawLine(325, headerY, 325, headerY + headerH, width: 0.5);
    builder.drawLine(365, headerY, 365, headerY + headerH, width: 0.5);
    builder.drawLine(415, headerY, 415, headerY + headerH, width: 0.5);

    double curY = headerY;
    const rowH = 15.0;

    for (var i = 0; i < rapor.daftarNilai.length; i++) {
      final m = rapor.daftarNilai[i];
      curY -= rowH;

      builder.drawLine(tableLeft, curY, tableLeft + tableWidth, curY, width: 0.5);
      builder.drawLine(65, curY, 65, curY + rowH, width: 0.5);
      builder.drawLine(285, curY, 285, curY + rowH, width: 0.5);
      builder.drawLine(325, curY, 325, curY + rowH, width: 0.5);
      builder.drawLine(365, curY, 365, curY + rowH, width: 0.5);
      builder.drawLine(415, curY, 415, curY + rowH, width: 0.5);

      builder.drawText('${i + 1}', 52, curY + 4, size: 8, align: _TextAlign.center);
      builder.drawText(m.mapel, 70, curY + 4, size: 8);
      builder.drawText('${m.skm}', 305, curY + 4, size: 8, align: _TextAlign.center);

      final nTeks = m.nilai == null ? '-' : (m.nilai! % 1 == 0 ? m.nilai!.toInt().toString() : m.nilai!.toString());
      builder.drawText(nTeks, 345, curY + 4, isBold: true, size: 8, align: _TextAlign.center);
      builder.drawText(m.predikat, 390, curY + 4, isBold: true, size: 8, align: _TextAlign.center);
      builder.drawText(m.isTuntas ? 'Tuntas' : 'Perlu Remedial', 475, curY + 4, size: 7.5, align: _TextAlign.center);
    }

    // Baris Total & Rata-rata
    curY -= rowH;
    builder.drawRect(
      tableLeft,
      curY,
      tableWidth,
      rowH,
      fill: true,
      stroke: true,
      fillR: 0.96,
      fillG: 0.96,
      fillB: 0.96,
    );
    builder.drawText('Jumlah Nilai / Rata-rata', 170, curY + 4, isBold: true, size: 8, align: _TextAlign.center);
    builder.drawLine(285, curY, 285, curY + rowH, width: 0.5);
    builder.drawText('-', 305, curY + 4, size: 8, align: _TextAlign.center);
    builder.drawLine(325, curY, 325, curY + rowH, width: 0.5);
    builder.drawText('${rapor.rataRata}', 345, curY + 4, isBold: true, size: 8, align: _TextAlign.center);
    builder.drawLine(365, curY, 365, curY + rowH, width: 0.5);
    builder.drawText(rapor.rataRata >= 80 ? 'B' : 'C', 390, curY + 4, isBold: true, size: 8, align: _TextAlign.center);
    builder.drawLine(415, curY, 415, curY + rowH, width: 0.5);
    builder.drawText(rapor.statusKelulusan, 475, curY + 4, isBold: true, size: 7.5, align: _TextAlign.center);

    // Border luar tabel
    builder.drawRect(tableLeft, curY, tableWidth, headerY + headerH - curY, stroke: true, width: 0.8);

    // 5. KETIDAKHADIRAN & CATATAN WALI KELAS
    curY -= 15;
    builder.drawText('B. Ketidakhadiran & Catatan Perkembangan', 40, curY, isBold: true, size: 9);

    curY -= 48;
    // Tabel Ketidakhadiran
    builder.drawRect(tableLeft, curY, 190, 44, stroke: true, width: 0.6);
    builder.drawText('Ketidakhadiran', 135, curY + 32, isBold: true, size: 8, align: _TextAlign.center);
    builder.drawLine(tableLeft, curY + 28, tableLeft + 190, curY + 28, width: 0.5);
    builder.drawText('1. Sakit', 50, curY + 18, size: 7.5);
    builder.drawText(': ${rapor.sakit} hari', 120, curY + 18, size: 7.5);
    builder.drawText('2. Izin', 50, curY + 9, size: 7.5);
    builder.drawText(': ${rapor.izin} hari', 120, curY + 9, size: 7.5);
    builder.drawText('3. Tanpa Keterangan', 50, curY + 1, size: 7.5);
    builder.drawText(': ${rapor.alpa} hari', 120, curY + 1, size: 7.5);

    // Kotak Catatan Wali Kelas
    builder.drawRect(tableLeft + 200, curY, 315, 44, stroke: true, width: 0.6);
    builder.drawText('Catatan Wali Kelas:', tableLeft + 208, curY + 32, isBold: true, size: 8);
    builder.drawText(rapor.catatanWali, tableLeft + 208, curY + 18, size: 7.5);
    builder.drawText('Tingkat Kehadiran: ${rapor.persentaseKehadiran.toStringAsFixed(1)}%', tableLeft + 208, curY + 4, size: 7.5);

    // 6. TANDA TANGAN 3 PIHAK STANDAR
    curY -= 20;
    builder.drawText('Kediri, ${rapor.tanggalTerbit}', 460, curY, size: 8.5, align: _TextAlign.center);

    curY -= 12;
    builder.drawText('Orang Tua / Wali,', 105, curY, size: 8.5, align: _TextAlign.center);
    builder.drawText('Wali Kelas,', 285, curY, size: 8.5, align: _TextAlign.center);
    builder.drawText('Mengetahui,', 460, curY, size: 8.5, align: _TextAlign.center);

    curY -= 10;
    builder.drawText('Kepala Madrasah,', 460, curY, size: 8.5, align: _TextAlign.center);

    curY -= 48;
    // Kolom 1: Orang tua
    builder.drawText('( ......................................... )', 105, curY, size: 8.5, align: _TextAlign.center);

    // Kolom 2: Wali Kelas
    builder.drawText(p.waliKelas ?? 'Ust. Ahmad Fauzi, S.Pd.I', 285, curY, isBold: true, size: 8.5, align: _TextAlign.center);
    builder.drawLine(225, curY - 2, 345, curY - 2, width: 0.6);
    builder.drawText('NIP. 198504122011011003', 285, curY - 11, size: 7.5, align: _TextAlign.center);

    // Kolom 3: Kepala Madrasah
    builder.drawText(p.kepalaMadrasah, 460, curY, isBold: true, size: 8.5, align: _TextAlign.center);
    builder.drawLine(400, curY - 2, 520, curY - 2, width: 0.6);
    builder.drawText('NIP. 196807121994031002', 460, curY - 11, size: 7.5, align: _TextAlign.center);

    return builder.build();
  }

  /// Menghasilkan file PDF dan menyimpannya secara nyata di folder Download HP.
  static Future<PdfDownloadResult> downloadRaporPdf({
    required RaporSiswaModel rapor,
  }) async {
    // 1. Muat logo resmi MTs
    final logoInfo = await _loadLogoAsset();

    // 2. Generate byte PDF
    final pdfBytes = generatePdfBytes(rapor, logoInfo);

    final cleanNama = rapor.profil.nama
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .trim()
        .replaceAll(' ', '_');
    final cleanKelas = rapor.profil.kelas.replaceAll(' ', '_');
    final fileName = 'Rapor_${cleanNama}_${cleanKelas}_${rapor.semester}.pdf';

    String savedPath = '';
    String? contentUri;
    File? savedFile;
    bool isSavedLocally = false;

    // A. Jalur Native Android (MediaStore Downloads + Notifikasi Sistem)
    if (Platform.isAndroid) {
      try {
        final Map<dynamic, dynamic>? res = await _channel.invokeMethod('saveAndNotifyPdf', {
          'fileName': fileName,
          'bytes': pdfBytes,
          'studentName': rapor.profil.nama,
        });

        if (res != null) {
          contentUri = res['uri'] as String?;
          savedPath = res['path'] as String? ?? 'Download/$fileName';
          isSavedLocally = true;
        }
      } catch (_) {
        // Fallback ke dart:io
      }
    }

    // B. Jalur dart:io untuk Windows / Desktop atau fallback Android
    if (!isSavedLocally) {
      Directory? targetDir;

      if (Platform.isAndroid) {
        final androidDownload = Directory('/storage/emulated/0/Download');
        if (await androidDownload.exists()) {
          targetDir = androidDownload;
        } else {
          final sdDownload = Directory('/sdcard/Download');
          if (await sdDownload.exists()) {
            targetDir = sdDownload;
          }
        }
      } else if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          final winDownload = Directory('$userProfile\\Downloads');
          if (await winDownload.exists()) {
            targetDir = winDownload;
          }
        }
      } else if (Platform.isMacOS || Platform.isLinux) {
        final home = Platform.environment['HOME'];
        if (home != null) {
          final unixDownload = Directory('$home/Downloads');
          if (await unixDownload.exists()) {
            targetDir = unixDownload;
          }
        }
      }

      targetDir ??= Directory.systemTemp;
      savedPath = '${targetDir.path}${Platform.pathSeparator}$fileName';
      savedFile = File(savedPath);
      await savedFile.writeAsBytes(pdfBytes, flush: true);
      isSavedLocally = true;
    }

    // C. Sinkronisasi ke Supabase Storage (Bobot 7%)
    String? storageUrl;
    bool isUploaded = false;

    try {
      final supabase = Supabase.instance.client;
      final storagePath = '${rapor.profil.kelas}/${rapor.profil.nisn ?? rapor.profil.nis}_rapor.pdf';

      await supabase.storage.from('rapor').uploadBinary(
            storagePath,
            pdfBytes,
            fileOptions: const FileOptions(upsert: true, contentType: 'application/pdf'),
          );
      storageUrl = supabase.storage.from('rapor').getPublicUrl(storagePath);
      isUploaded = true;
    } catch (_) {
      // lanjut
    }

    return PdfDownloadResult(
      file: savedFile,
      filePath: savedPath,
      fileName: fileName,
      fileSizeBytes: pdfBytes.length,
      contentUri: contentUri,
      storageUrl: storageUrl,
      isSavedLocally: isSavedLocally,
      isUploadedToStorage: isUploaded,
    );
  }

  /// Membuka file PDF di HP atau desktop secara langsung
  static Future<bool> openPdf({String? contentUri, String? filePath}) async {
    if (Platform.isAndroid) {
      try {
        final res = await _channel.invokeMethod<bool>('openPdf', {
          'uri': contentUri,
          'filePath': filePath,
        });
        return res ?? false;
      } catch (_) {
        return false;
      }
    } else if (Platform.isWindows && filePath != null) {
      try {
        await Process.run('cmd', ['/c', 'start', '', filePath]);
        return true;
      } catch (_) {
        return false;
      }
    } else if ((Platform.isMacOS || Platform.isLinux) && filePath != null) {
      try {
        await Process.run(Platform.isMacOS ? 'open' : 'xdg-open', [filePath]);
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }
}

enum _TextAlign { left, center }

/// Engine penyusun dokumen PDF 1.4 murni (standard ISO 32000-1) dengan dukungan XObject Gambar (Logo)
class _PdfBuilder {
  _PdfBuilder({this.logoInfo});

  final _LogoImageInfo? logoInfo;
  final StringBuffer _stream = StringBuffer();

  void drawImage(double x, double y, double w, double h) {
    if (logoInfo == null) return;
    _stream.writeln('q');
    _stream.writeln('${w.toStringAsFixed(2)} 0 0 ${h.toStringAsFixed(2)} ${x.toStringAsFixed(2)} ${y.toStringAsFixed(2)} cm');
    _stream.writeln('/Im1 Do');
    _stream.writeln('Q');
  }

  void drawRect(
    double x,
    double y,
    double w,
    double h, {
    bool fill = false,
    bool stroke = true,
    double fillR = 0,
    double fillG = 0,
    double fillB = 0,
    double strokeR = 0,
    double strokeG = 0,
    double strokeB = 0,
    double width = 0.5,
  }) {
    _stream.writeln('${width.toStringAsFixed(2)} w');
    if (fill) {
      _stream.writeln('${fillR.toStringAsFixed(3)} ${fillG.toStringAsFixed(3)} ${fillB.toStringAsFixed(3)} rg');
    }
    if (stroke) {
      _stream.writeln('${strokeR.toStringAsFixed(3)} ${strokeG.toStringAsFixed(3)} ${strokeB.toStringAsFixed(3)} RG');
    }
    final op = fill && stroke ? 'B' : (fill ? 'f' : 'S');
    _stream.writeln('${x.toStringAsFixed(2)} ${y.toStringAsFixed(2)} ${w.toStringAsFixed(2)} ${h.toStringAsFixed(2)} re $op');
  }

  void drawLine(
    double x1,
    double y1,
    double x2,
    double y2, {
    double width = 0.5,
    double r = 0,
    double g = 0,
    double b = 0,
  }) {
    _stream.writeln('${width.toStringAsFixed(2)} w');
    _stream.writeln('${r.toStringAsFixed(3)} ${g.toStringAsFixed(3)} ${b.toStringAsFixed(3)} RG');
    _stream.writeln('${x1.toStringAsFixed(2)} ${y1.toStringAsFixed(2)} m ${x2.toStringAsFixed(2)} ${y2.toStringAsFixed(2)} l S');
  }

  void drawText(
    String text,
    double x,
    double y, {
    bool isBold = false,
    double size = 9,
    _TextAlign align = _TextAlign.left,
    double r = 0,
    double g = 0,
    double b = 0,
  }) {
    final clean = _cleanString(text);
    double startX = x;
    if (align == _TextAlign.center) {
      final approxWidth = clean.length * size * 0.52;
      startX = x - (approxWidth / 2);
    }

    _stream.writeln('BT');
    _stream.writeln('/${isBold ? "F2" : "F1"} ${size.toStringAsFixed(1)} Tf');
    _stream.writeln('${r.toStringAsFixed(3)} ${g.toStringAsFixed(3)} ${b.toStringAsFixed(3)} rg');
    _stream.writeln('1 0 0 1 ${startX.toStringAsFixed(2)} ${y.toStringAsFixed(2)} Tm');
    _stream.writeln('($clean) Tj');
    _stream.writeln('ET');
  }

  static String _cleanString(String s) {
    var res = s
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('–', '-')
        .replaceAll('—', '-');
    res = res.replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');
    return res.replaceAll(RegExp(r'[^\x20-\x7E]'), ' ');
  }

  Uint8List build() {
    final streamBytes = utf8.encode(_stream.toString());
    final streamLength = streamBytes.length;

    final hasLogo = logoInfo != null;
    final imgCompressed = hasLogo ? zlib.encode(logoInfo!.rgbBytes) : null;

    const header = '%PDF-1.4\n';
    const obj1 = '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n';
    const obj2 = '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n';

    final xObjectResource = hasLogo ? ' /XObject << /Im1 7 0 R >>' : '';
    final obj3 =
        '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595.28 841.89] /Resources << /Font << /F1 4 0 R /F2 5 0 R >>$xObjectResource >> /Contents 6 0 R >>\nendobj\n';
    const obj4 = '4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n';
    const obj5 = '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\nendobj\n';
    final obj6Header = '6 0 obj\n<< /Length $streamLength >>\nstream\n';
    const obj6Footer = '\nendstream\nendobj\n';

    final bytesBuilder = BytesBuilder();
    final offsets = <int>[0];

    void writeAscii(String s) {
      bytesBuilder.add(ascii.encode(s));
    }

    writeAscii(header);

    offsets.add(bytesBuilder.length); // obj 1
    writeAscii(obj1);

    offsets.add(bytesBuilder.length); // obj 2
    writeAscii(obj2);

    offsets.add(bytesBuilder.length); // obj 3
    writeAscii(obj3);

    offsets.add(bytesBuilder.length); // obj 4
    writeAscii(obj4);

    offsets.add(bytesBuilder.length); // obj 5
    writeAscii(obj5);

    offsets.add(bytesBuilder.length); // obj 6
    writeAscii(obj6Header);
    bytesBuilder.add(streamBytes);
    writeAscii(obj6Footer);

    if (hasLogo && imgCompressed != null) {
      offsets.add(bytesBuilder.length); // obj 7 (Image XObject)
      final obj7Header =
          '7 0 obj\n<< /Type /XObject /Subtype /Image /Width ${logoInfo!.width} /Height ${logoInfo!.height} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode /Length ${imgCompressed.length} >>\nstream\n';
      writeAscii(obj7Header);
      bytesBuilder.add(imgCompressed);
      writeAscii('\nendstream\nendobj\n');
    }

    final totalObjects = hasLogo ? 8 : 7;
    final startXref = bytesBuilder.length;
    final xref = StringBuffer();
    xref.writeln('xref');
    xref.writeln('0 $totalObjects');
    xref.writeln('0000000000 65535 f ');
    for (int i = 1; i < totalObjects; i++) {
      xref.writeln('${offsets[i].toString().padLeft(10, '0')} 00000 n ');
    }
    xref.writeln('trailer');
    xref.writeln('<< /Size $totalObjects /Root 1 0 R >>');
    xref.writeln('startxref');
    xref.writeln('$startXref');
    xref.writeln('%%EOF');

    writeAscii(xref.toString());
    return bytesBuilder.toBytes();
  }
}

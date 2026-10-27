import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart'
    show
        CellValue,
        Data,
        DateCellValue,
        DateTimeCellValue,
        DoubleCellValue,
        Excel,
        IntCellValue;

/// Satu baris berkas Excel yang lolos validasi di perangkat.
class BarisSiswa {
  const BarisSiswa({
    required this.nis,
    required this.nama,
    required this.jk,
    required this.tglLahir,
    this.nisn,
    this.kelas,
  });

  final String nis;
  final String? nisn;
  final String nama;
  final String jk; // L | P
  final String tglLahir; // yyyy-mm-dd
  final String? kelas;

  Map<String, String?> toJson() => {
    'nis': nis,
    'nisn': nisn,
    'nama': nama,
    'jk': jk,
    'tgl_lahir': tglLahir,
    'kelas': kelas,
  };
}

/// Hasil membaca satu baris: [siswa] terisi bila valid, selain itu [galat].
class BarisImpor {
  const BarisImpor.valid(this.nomor, BarisSiswa this.siswa) : galat = null;
  const BarisImpor.salah(this.nomor, String this.galat) : siswa = null;

  final int nomor; // nomor baris di Excel (header = 1)
  final BarisSiswa? siswa;
  final String? galat;
}

/// Hasil dari server untuk satu NIS.
enum StatusImpor { dibuat, sudahAda, gagal }

class HasilImpor {
  const HasilImpor({
    required this.nis,
    required this.status,
    this.password,
    this.pesan,
  });

  final String nis;
  final StatusImpor status;
  final String? password; // hanya untuk status dibuat; tampil sekali
  final String? pesan;

  factory HasilImpor.fromJson(Map<String, dynamic> j) => HasilImpor(
    nis: j['nis'] as String,
    status: switch (j['status']) {
      'dibuat' => StatusImpor.dibuat,
      'sudah_ada' => StatusImpor.sudahAda,
      _ => StatusImpor.gagal,
    },
    password: j['password'] as String?,
    pesan: j['pesan'] as String?,
  );
}

/// Kolom wajib; nama header dinormalkan (huruf kecil, spasi jadi `_`).
const _wajib = ['nis', 'nama', 'jk', 'tgl_lahir'];

/// Membaca sheet pertama. Baris pertama = header. Baris kosong dilewati.
/// Melempar [FormatException] (pesan Indonesia) bila berkas tidak bisa dipakai.
List<BarisImpor> bacaExcelSiswa(Uint8List bytes) {
  final Excel excel;
  try {
    excel = Excel.decodeBytes(_relatifkanTarget(bytes));
  } catch (_) {
    throw const FormatException('Berkas bukan Excel (.xlsx) yang valid.');
  }
  final sheet = excel.tables.values.firstOrNull;
  if (sheet == null || sheet.rows.isEmpty) {
    throw const FormatException('Sheet kosong.');
  }

  final rows = sheet.rows;
  final kolom = <String, int>{
    for (var i = 0; i < rows.first.length; i++)
      _header(_teks(rows.first[i]?.value)): i,
  };
  final hilang = _wajib.where((k) => !kolom.containsKey(k));
  if (hilang.isNotEmpty) {
    throw FormatException(
      'Kolom wajib tidak ditemukan: ${hilang.join(', ')}. '
      'Header: nis, nisn, nama, jk, tgl_lahir, kelas.',
    );
  }

  String sel(List<Data?> baris, String k) {
    final i = kolom[k];
    return i == null || i >= baris.length ? '' : _teks(baris[i]?.value);
  }

  final hasil = <BarisImpor>[];
  for (var r = 1; r < rows.length; r++) {
    final baris = rows[r];
    if (baris.every((d) => _teks(d?.value).isEmpty)) continue;
    final nomor = r + 1;

    final nis = sel(baris, 'nis');
    final nama = sel(baris, 'nama');
    final jk = _jk(sel(baris, 'jk'));
    final tgl = _tanggal(sel(baris, 'tgl_lahir'));
    final galat = nis.isEmpty
        ? 'NIS kosong'
        : !RegExp(r'^[A-Za-z0-9._-]{3,30}$').hasMatch(nis)
        ? 'NIS harus 3-30 karakter (huruf, angka, titik, minus, garis bawah)'
        : nama.isEmpty
        ? 'Nama kosong'
        : jk == null
        ? 'Jenis kelamin harus L atau P'
        : tgl == null
        ? 'Tanggal lahir tidak valid (pakai yyyy-mm-dd atau dd/mm/yyyy)'
        : null;
    if (galat != null) {
      hasil.add(BarisImpor.salah(nomor, galat));
      continue;
    }
    hasil.add(
      BarisImpor.valid(
        nomor,
        BarisSiswa(
          nis: nis,
          nisn: sel(baris, 'nisn').isEmpty ? null : sel(baris, 'nisn'),
          nama: nama,
          jk: jk!,
          tglLahir: tgl!,
          kelas: sel(baris, 'kelas').isEmpty ? null : sel(baris, 'kelas'),
        ),
      ),
    );
  }

  // NIS ganda di dalam berkas: yang pertama dipakai, sisanya ditandai.
  final terlihat = <String>{};
  return [
    for (final b in hasil)
      if (b.siswa != null && !terlihat.add(b.siswa!.nis.toLowerCase()))
        BarisImpor.salah(
          b.nomor,
          'NIS ${b.siswa!.nis} muncul lebih dari sekali',
        )
      else
        b,
  ];
}

String _header(String s) =>
    s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

String _iso(int y, int m, int d) =>
    '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-'
    '${d.toString().padLeft(2, '0')}';

String _teks(CellValue? v) => switch (v) {
  null => '',
  IntCellValue() => '${v.value}',
  DoubleCellValue() => v.value % 1 == 0 ? '${v.value.toInt()}' : '${v.value}',
  DateCellValue() => _iso(v.year, v.month, v.day),
  DateTimeCellValue() => _iso(v.year, v.month, v.day),
  _ => v.toString().trim(),
};

String? _jk(String s) {
  final t = s.trim().toLowerCase();
  if (t == 'l' || t == 'laki-laki' || t == 'laki laki') return 'L';
  if (t == 'p' || t == 'perempuan') return 'P';
  return null;
}

/// yyyy-mm-dd atau dd/mm/yyyy (juga dd-mm-yyyy). Null bila bukan tanggal nyata.
String? _tanggal(String s) {
  final m =
      RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(s) ??
      RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(s);
  if (m == null) return null;
  final iso = s.contains(RegExp(r'^\d{4}'));
  final y = int.parse(iso ? m[1]! : m[3]!);
  final mo = int.parse(m[2]!);
  final d = int.parse(iso ? m[3]! : m[1]!);
  final dt = DateTime(y, mo, d);
  // DateTime menggulung 31 Februari ke Maret; tolak yang berubah.
  if (dt.year != y || dt.month != mo || dt.day != d) return null;
  return _iso(y, mo, d);
}

/// Paket excel mengira target di workbook.xml.rels relatif terhadap xl/. Berkas
/// dari openpyxl/pandas memakai target absolut (/xl/worksheets/sheet1.xml)
/// sehingga gagal dibuka; di sini diubah menjadi relatif. Berkas lain dibiarkan.
Uint8List _relatifkanTarget(Uint8List bytes) {
  try {
    final arsip = ZipDecoder().decodeBytes(bytes);
    final rels = arsip.findFile('xl/_rels/workbook.xml.rels');
    if (rels == null) return bytes;
    final isi = utf8.decode(rels.content as List<int>);
    if (!isi.contains('Target="/xl/')) return bytes;
    final baru = utf8.encode(isi.replaceAll('Target="/xl/', 'Target="'));
    final hasil = Archive();
    for (final f in arsip) {
      hasil.addFile(f == rels ? ArchiveFile(f.name, baru.length, baru) : f);
    }
    return Uint8List.fromList(ZipEncoder().encode(hasil)!);
  } catch (_) {
    return bytes; // bukan zip: biar Excel.decodeBytes yang melapor
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si_e_rapor_mts_al_fajar/features/admin/data/impor_siswa.dart';

Uint8List _xlsx(List<List<CellValue?>> baris) {
  final excel = Excel.createExcel();
  final sheet = excel[excel.getDefaultSheet()!];
  for (final b in baris) {
    sheet.appendRow(b);
  }
  return Uint8List.fromList(excel.save()!);
}

/// Meniru berkas openpyxl/pandas: target sheet di workbook.xml.rels absolut.
Uint8List _gayaOpenpyxl(Uint8List xlsx) {
  final arsip = ZipDecoder().decodeBytes(xlsx);
  final rels = arsip.findFile('xl/_rels/workbook.xml.rels')!;
  final isi = utf8
      .decode(rels.content as List<int>)
      .replaceAll('Target="worksheets/', 'Target="/xl/worksheets/');
  expect(isi, contains('Target="/xl/worksheets/'));
  final baru = Archive();
  for (final f in arsip) {
    baru.addFile(
      f == rels
          ? ArchiveFile(f.name, utf8.encode(isi).length, utf8.encode(isi))
          : f,
    );
  }
  return Uint8List.fromList(ZipEncoder().encode(baru)!);
}

TextCellValue _t(String s) => TextCellValue(s);

final _header = [
  _t('NIS'),
  _t('NISN'),
  _t('Nama'),
  _t('JK'),
  _t('Tgl Lahir'),
  _t('Kelas'),
];

void main() {
  test('baris valid dibaca, angka NIS dan tanggal Excel dinormalkan', () {
    final hasil = bacaExcelSiswa(
      _xlsx([
        _header,
        [
          IntCellValue(2026001),
          _t('0123456789'),
          _t('Ahmad'),
          _t('l'),
          DateCellValue(year: 2012, month: 5, day: 3),
          _t('VII-A'),
        ],
        [
          _t('2026002'),
          null,
          _t('Siti'),
          _t('Perempuan'),
          _t('30/01/2013'),
          null,
        ],
      ]),
    );

    expect(hasil.map((b) => b.galat), [null, null]);
    final a = hasil[0].siswa!;
    expect(
      [a.nis, a.nisn, a.nama, a.jk, a.tglLahir, a.kelas],
      ['2026001', '0123456789', 'Ahmad', 'L', '2012-05-03', 'VII-A'],
    );
    final b = hasil[1].siswa!;
    expect(
      [b.jk, b.tglLahir, b.nisn, b.kelas],
      ['P', '2013-01-30', null, null],
    );
  });

  test(
    'baris salah ditandai dengan nomor baris Excel, baris kosong dilewati',
    () {
      final hasil = bacaExcelSiswa(
        _xlsx([
          _header,
          [_t('2026001'), null, _t('Ahmad'), _t('X'), _t('2012-05-03'), null],
          [null, null, null, null, null, null],
          [_t('2026003'), null, _t('Budi'), _t('L'), _t('2013-02-31'), null],
          [_t('2026004'), null, _t('Dewi'), _t('P'), _t('2012-05-03'), null],
          [_t('2026004'), null, _t('Dewi 2'), _t('P'), _t('2012-05-03'), null],
        ]),
      );

      expect(hasil.map((b) => b.nomor), [2, 4, 5, 6]);
      expect(hasil[0].galat, contains('Jenis kelamin'));
      expect(hasil[1].galat, contains('Tanggal lahir'));
      expect(hasil[2].siswa, isNotNull);
      expect(hasil[3].galat, contains('lebih dari sekali'));
    },
  );

  test('kolom wajib hilang melempar FormatException', () {
    expect(
      () => bacaExcelSiswa(
        _xlsx([
          [_t('nis'), _t('nama')],
        ]),
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('jk, tgl_lahir'),
        ),
      ),
    );
  });

  test('berkas bukan Excel melempar FormatException', () {
    expect(
      () => bacaExcelSiswa(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
  });

  test('berkas bergaya openpyxl (target sheet absolut) tetap terbaca', () {
    final hasil = bacaExcelSiswa(
      _gayaOpenpyxl(
        _xlsx([
          _header,
          [_t('2026001'), null, _t('Ahmad'), _t('L'), _t('2012-05-03'), null],
        ]),
      ),
    );

    expect(hasil.single.siswa?.nama, 'Ahmad');
  });
}

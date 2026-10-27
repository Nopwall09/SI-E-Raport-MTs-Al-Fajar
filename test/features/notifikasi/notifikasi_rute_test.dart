import 'package:flutter_test/flutter_test.dart';
import 'package:si_e_rapor_mts_al_fajar/features/auth/domain/user.dart';
import 'package:si_e_rapor_mts_al_fajar/features/notifikasi/notifikasi_rute.dart';

void main() {
  const rapor = PesanNotifikasi(data: {'type': 'rapor_final', 'siswa_id': '1'});
  const wali = AppUser(id: 'u1', name: 'Wali', role: UserRole.waliMurid);
  const siswa = AppUser(id: 'u2', name: 'Siswa', role: UserRole.siswa);

  test('rapor final membuka beranda role penerima', () {
    expect(ruteNotifikasi(rapor, wali), '/wali-murid/beranda');
    expect(ruteNotifikasi(rapor, siswa), '/siswa/beranda');
  });

  test('belum masuk: tidak berpindah layar', () {
    expect(ruteNotifikasi(rapor, null), isNull);
  });

  test('jenis pesan tidak dikenal atau tanpa data: diabaikan', () {
    expect(
      ruteNotifikasi(const PesanNotifikasi(data: {'type': 'lain'}), wali),
      isNull,
    );
    expect(ruteNotifikasi(const PesanNotifikasi(), wali), isNull);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si_e_rapor_mts_al_fajar/app/router.dart';
import 'package:si_e_rapor_mts_al_fajar/features/auth/domain/user.dart';

const _guru = AppUser(id: 'g1', name: 'Guru', role: UserRole.guru);
const _waliKelas = AppUser(
  id: 'g2',
  name: 'Wali',
  role: UserRole.guru,
  waliKelas: WaliKelasInfo(kelasId: 1, namaKelas: '7A'),
);

void main() {
  test('memeriksa sesi: tahan di splash', () {
    expect(redirectFor(const AsyncLoading(), '/login'), '/splash');
    expect(redirectFor(const AsyncLoading(), '/splash'), isNull);
  });

  test('belum masuk: paksa ke login', () {
    expect(redirectFor(const AsyncData(null), '/guru/nilai'), '/login');
    expect(redirectFor(const AsyncData(null), '/login'), isNull);
  });

  test('sudah masuk: login dan splash diarahkan ke beranda role', () {
    expect(redirectFor(const AsyncData(_guru), '/login'), '/guru/beranda');
    expect(redirectFor(const AsyncData(_guru), '/splash'), '/guru/beranda');
  });

  test('area role lain ditolak', () {
    expect(redirectFor(const AsyncData(_guru), '/siswa/rapor'), '/guru/beranda');
    expect(redirectFor(const AsyncData(_guru), '/admin/beranda'), '/guru/beranda');
  });

  test('tab wali kelas hanya untuk wali kelas', () {
    expect(redirectFor(const AsyncData(_guru), '/guru/wali-kelas'),
        '/guru/beranda');
    expect(redirectFor(const AsyncData(_waliKelas), '/guru/wali-kelas'), isNull);
  });
}

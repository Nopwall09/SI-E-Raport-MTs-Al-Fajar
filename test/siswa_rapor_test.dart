// Rapor siswa tidak boleh menampilkan data karangan.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si_e_rapor_mts_al_fajar/app/app.dart';
import 'package:si_e_rapor_mts_al_fajar/core/error/app_exception.dart';
import 'package:si_e_rapor_mts_al_fajar/features/siswa/data/siswa_repository.dart';
import 'package:si_e_rapor_mts_al_fajar/features/siswa/presentation/siswa_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'helpers/test_overrides.dart';

void main() {
  test('tanpa data siswa, repository melempar error, bukan rapor contoh', () {
    final db = SupabaseClient(
      'http://localhost',
      'anon',
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );

    expect(
      SiswaRepository(db).getRaporSiswa(semester: 'ganjil'),
      throwsA(isA<AppException>()),
    );
  });

  testWidgets('siswa tanpa nilai: pesan kosong, tanpa peringkat dan unduhan', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(signedInAs: 'siswa'),
          siswaRaporProvider.overrideWith(
            (ref) async => const RaporSiswaModel(
              profil: SiswaProfil(id: 1, nama: 'Anak', nis: '1', kelas: '-'),
              semester: 'Ganjil',
              tahunAjaran: '2026/2027',
              daftarNilai: [],
              rataRata: 0,
              statusKelulusan: 'BELUM ADA NILAI',
              keteranganKelulusan: '-',
              sakit: 0,
              izin: 0,
              alpa: 0,
              catatanWali: '-',
              kodeVerifikasiQr: '-',
              tanggalTerbit: '-',
            ),
          ),
        ],
        child: const EraporApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada nilai untuk semester ini.'), findsOneWidget);
    expect(find.text('Unduh Rapor'), findsNothing);
    expect(find.textContaining('Peringkat'), findsNothing);
    expect(find.textContaining('Tren'), findsNothing);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Rapor'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada nilai untuk semester ini.'), findsOneWidget);
    expect(find.text('Unduh'), findsNothing);
    expect(find.textContaining('Peringkat'), findsNothing);
  });
}

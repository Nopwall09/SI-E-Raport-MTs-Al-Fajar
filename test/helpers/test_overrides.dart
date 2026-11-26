import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:si_e_rapor_mts_al_fajar/features/admin/data/admin_repository.dart';
import 'package:si_e_rapor_mts_al_fajar/features/admin/presentation/admin_providers.dart';
import 'package:si_e_rapor_mts_al_fajar/features/auth/data/fake_auth_repository.dart';
import 'package:si_e_rapor_mts_al_fajar/features/auth/presentation/auth_controller.dart';
import 'package:si_e_rapor_mts_al_fajar/features/nilai/data/nilai_repository.dart';
import 'package:si_e_rapor_mts_al_fajar/features/notifikasi/notifikasi_providers.dart';
import 'package:si_e_rapor_mts_al_fajar/features/notifikasi/notifikasi_service.dart';
import 'package:si_e_rapor_mts_al_fajar/features/nilai/presentation/nilai_providers.dart';
import 'package:si_e_rapor_mts_al_fajar/features/siswa/data/siswa_repository.dart';
import 'package:si_e_rapor_mts_al_fajar/features/siswa/presentation/siswa_providers.dart';
import 'package:si_e_rapor_mts_al_fajar/features/wali_kelas/data/wali_kelas_repository.dart';
import 'package:si_e_rapor_mts_al_fajar/features/wali_kelas/presentation/wali_kelas_providers.dart';
import 'package:si_e_rapor_mts_al_fajar/features/wali_murid/data/wali_murid_repository.dart';
import 'package:si_e_rapor_mts_al_fajar/features/wali_murid/presentation/wali_murid_providers.dart';

/// Override standar untuk test: repository contoh tanpa jeda, sehingga tidak
/// menyentuh Supabase maupun jaringan. `signedInAs` meniru sesi tersimpan.
/// Data beranda guru dan wali murid diganti data kosong/ringan.
List<Override> testOverrides({String? signedInAs}) {
  return [
    authRepositoryProvider.overrideWithValue(
      FakeAuthRepository(latency: Duration.zero, signedInAs: signedInAs),
    ),
    notifikasiServiceProvider.overrideWithValue(const NotifikasiKosong()),
    tahunAjaranAktifProvider.overrideWith(
      (ref) async => const TahunAjaranAktif(1, '2026/2027', 'ganjil'),
    ),
    progresPenugasanProvider.overrideWith(
      (ref) async => const <PenugasanProgres>[],
    ),
    progresKelasProvider.overrideWith(
      (ref) async => const <SiswaProgres>[
        SiswaProgres(
          kelasSiswaId: 1,
          nama: 'Siswa Contoh A',
          nis: '1001',
          mapel: [MapelStatus('Matematika', 85)],
        ),
      ],
    ),
    perkembanganAnakProvider.overrideWith(
      (ref) async => const <AnakModel>[
        AnakModel(
          id: 1,
          nama: 'Muhammad Farhan Al-Ghifari',
          nis: '2026001',
          kelas: 'VII-A',
          rataRata: 87.8,
          historiPerkembangan: [82.0, 84.5, 85.0, 86.8, 87.8],
          labelPerkembangan: ['UH 1', 'UH 2', 'PTS', 'UH 3', 'PAS'],
          daftarNilai: [
            NilaiMapelWali(mapel: "Al-Qur'an Hadits", nilai: 92),
          ],
        ),
      ],
    ),
    siswaRaporProvider.overrideWith(
      (ref) async => const RaporSiswaModel(
        profil: SiswaProfil(
          id: 1,
          nama: 'Muhammad Farhan Al-Ghifari',
          nis: '2026001',
          kelas: 'VII-A',
          waliKelas: 'Ust. Ahmad Fauzi, S.Pd.I',
          tahunAjaran: '2026/2027',
          semester: 'Ganjil',
        ),
        semester: 'Ganjil',
        tahunAjaran: '2026/2027',
        daftarNilai: [
          NilaiMapelSiswa(
            mapel: "Al-Qur'an Hadits",
            nilai: 92,
            skm: 75,
            kategori: 'Agama',
          ),
        ],
        rataRata: 87.8,
        statusKelulusan: 'TUNTAS / LULUS SEMESTER',
        keteranganKelulusan: 'Tuntas semester berjalan.',
        sakit: 1,
        izin: 0,
        alpa: 0,
        catatanWali: 'Pertahankan prestasi belajar.',
        kodeVerifikasiQr: 'RAPOR-2026001-GANJIL',
        tanggalTerbit: '18 Desember 2026',
      ),
    ),
  ];
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';

class SiswaProfil {
  const SiswaProfil({
    required this.id,
    required this.nama,
    required this.nis,
    this.nisn,
    required this.kelas,
    this.waliKelas,
    this.kepalaMadrasah = 'Drs. H. M. Bahrudin, M.Pd.I',
    this.tahunAjaran = '2026/2027',
    this.semester = 'Ganjil',
  });

  final int id;
  final String nama;
  final String nis;
  final String? nisn;
  final String kelas;
  final String? waliKelas;
  final String kepalaMadrasah;
  final String tahunAjaran;
  final String semester;
}

class NilaiMapelSiswa {
  const NilaiMapelSiswa({
    required this.mapel,
    this.kode,
    this.kategori = 'Umum',
    this.skm = 75,
    this.nilai,
    this.catatanGuru,
  });

  final String mapel;
  final String? kode;
  final String kategori; // 'Agama', 'Bahasa', 'Umum'
  final int skm;
  final num? nilai;
  final String? catatanGuru;

  bool get isTuntas => nilai != null && nilai! >= skm;

  String get predikat {
    if (nilai == null) return '-';
    if (nilai! >= 90) return 'A';
    if (nilai! >= 80) return 'B';
    if (nilai! >= 75) return 'C';
    return 'D';
  }

  String get predikatTeks {
    if (nilai == null) return 'Belum Dinilai';
    if (nilai! >= 90) return 'Sangat Baik';
    if (nilai! >= 80) return 'Baik';
    if (nilai! >= 75) return 'Cukup';
    return 'Perlu Perbaikan';
  }
}

class RaporSiswaModel {
  const RaporSiswaModel({
    required this.profil,
    required this.semester,
    required this.tahunAjaran,
    required this.daftarNilai,
    required this.rataRata,
    required this.statusKelulusan,
    required this.keteranganKelulusan,
    required this.sakit,
    required this.izin,
    required this.alpa,
    required this.catatanWali,
    required this.kodeVerifikasiQr,
    required this.tanggalTerbit,
  });

  final SiswaProfil profil;
  final String semester;
  final String tahunAjaran;
  final List<NilaiMapelSiswa> daftarNilai;
  final double rataRata;
  final String statusKelulusan; // 'TUNTAS / LULUS SEMESTER', 'BELUM TUNTAS'
  final String keteranganKelulusan;
  final int sakit;
  final int izin;
  final int alpa;
  final String catatanWali;
  final String kodeVerifikasiQr;
  final String tanggalTerbit;

  int get totalMapel => daftarNilai.length;
  int get mapelTuntas => daftarNilai.where((m) => m.isTuntas).length;
  bool get semuaTuntas => totalMapel > 0 && mapelTuntas == totalMapel;

  double get persentaseKehadiran {
    const totalHariEfektif = 110;
    final absen = sakit + izin + alpa;
    final hadir = totalHariEfektif - absen;
    return (hadir / totalHariEfektif * 100).clamp(0.0, 100.0);
  }
}

class SiswaRepository {
  SiswaRepository(this._db);

  final SupabaseClient _db;

  /// Mengambil data profil dan rekap nilai rapor siswa berdasarkan semester.
  Future<RaporSiswaModel> getRaporSiswa({
    required String semester,
    int? tahunAjaranId,
  }) async {
    final currentUserId = _db.auth.currentUser?.id;
    if (currentUserId == null) {
      throw const AppException(
        AppErrorType.unauthorized,
        'Sesi berakhir. Silakan masuk lagi.',
      );
    }

    // 1. Ambil data siswa yang terhubung dengan akun login
    final siswaRow = await _db
        .from('siswa')
        .select('id, nis, nisn, nama, jk')
        .eq('user_id', currentUserId)
        .maybeSingle();

    if (siswaRow == null) {
      throw const AppException(
        AppErrorType.validation,
        'Data siswa untuk akun ini belum ada. Hubungi admin.',
      );
    }

    final siswaId = siswaRow['id'] as int;
    final namaSiswa = siswaRow['nama'] as String;
    final nis = siswaRow['nis'] as String;
    final nisn = siswaRow['nisn'] as String?;

    // 2. Ambil kelas_siswa aktif
    var queryKs = _db
        .from('kelas_siswa')
        .select(
          'id, kelas:kelas_id(id, nama, wali_kelas:wali_kelas_id(nama)), tahun_ajaran:tahun_ajaran_id(id, tahun, skm, semester_aktif)',
        )
        .eq('siswa_id', siswaId);

    if (tahunAjaranId != null) {
      queryKs = queryKs.eq('tahun_ajaran_id', tahunAjaranId);
    }

    final ksRows = await queryKs;
    if (ksRows.isEmpty) {
      throw const AppException(
        AppErrorType.validation,
        'Kamu belum terdaftar di kelas pada tahun ajaran ini.',
      );
    }

    final ks = ksRows.first;
    final ksId = ks['id'] as int;
    final kelasObj = ks['kelas'] as Map<String, dynamic>?;
    final namaKelas = kelasObj?['nama'] as String? ?? '-';
    final waliKelasObj = kelasObj?['wali_kelas'] as Map<String, dynamic>?;
    final namaWaliKelas = waliKelasObj?['nama'] as String?;
    final taObj = ks['tahun_ajaran'] as Map<String, dynamic>?;
    final tahunTeks = taObj?['tahun'] as String? ?? '-';
    final skm = (taObj?['skm'] as num?)?.toInt() ?? 75;

    // 3. Ambil nilai detail mata pelajaran
    final detnilaiRows = await _db
        .from('detnilai')
        .select('nilai, semester, mapel:mapel_id(nama, kode)')
        .eq('kelas_siswa_id', ksId)
        .eq('semester', semester);

    final daftarNilai = <NilaiMapelSiswa>[];
    var totalNilai = 0.0;
    var jumlahTerisi = 0;

    for (final dn in detnilaiRows) {
      final n = dn['nilai'] as num?;
      final mapelObj = dn['mapel'] as Map<String, dynamic>?;
      final namaMapel = mapelObj?['nama'] as String? ?? 'Mapel';
      final kodeMapel = mapelObj?['kode'] as String?;

      String kategori = 'Umum';
      if (kodeMapel != null) {
        if (['QH', 'AA', 'FQH', 'SKI', 'BAR'].contains(kodeMapel)) {
          kategori = 'Agama';
        } else if (['BIN', 'BIG'].contains(kodeMapel)) {
          kategori = 'Bahasa';
        }
      }

      daftarNilai.add(
        NilaiMapelSiswa(
          mapel: namaMapel,
          kode: kodeMapel,
          kategori: kategori,
          skm: skm,
          nilai: n,
        ),
      );

      if (n != null) {
        totalNilai += n.toDouble();
        jumlahTerisi++;
      }
    }

    // 4. Ambil catatan rapor & kehadiran jika ada
    final raporRow = await _db
        .from('rapor')
        .select('sakit, izin, alpa, catatan, status')
        .eq('kelas_siswa_id', ksId)
        .eq('semester', semester)
        .maybeSingle();

    final sakit = (raporRow?['sakit'] as num?)?.toInt() ?? 0;
    final izin = (raporRow?['izin'] as num?)?.toInt() ?? 0;
    final alpa = (raporRow?['alpa'] as num?)?.toInt() ?? 0;
    final catatan = raporRow?['catatan'] as String? ?? '-';

    final rataRata = jumlahTerisi > 0 ? totalNilai / jumlahTerisi : 0.0;

    final profil = SiswaProfil(
      id: siswaId,
      nama: namaSiswa,
      nis: nis,
      nisn: nisn,
      kelas: namaKelas,
      waliKelas: namaWaliKelas,
      tahunAjaran: tahunTeks,
      semester: semester == 'ganjil' ? 'Ganjil' : 'Genap',
    );

    final isTuntasSemua = daftarNilai.isNotEmpty &&
        daftarNilai.every((m) => m.isTuntas) &&
        alpa == 0;

    return RaporSiswaModel(
      profil: profil,
      semester: semester == 'ganjil' ? 'Ganjil' : 'Genap',
      tahunAjaran: tahunTeks,
      daftarNilai: daftarNilai,
      rataRata: double.parse(rataRata.toStringAsFixed(1)),
      statusKelulusan: daftarNilai.isEmpty
          ? 'BELUM ADA NILAI'
          : isTuntasSemua
          ? (semester == 'genap' ? 'NAIK KE KELAS BERIKUTNYA' : 'TUNTAS / MEMENUHI KKM')
          : 'PERLU PEMENUHAN SKM',
      keteranganKelulusan: isTuntasSemua
          ? 'Memenuhi seluruh Kriteria Ketuntasan Minimal (KKM) dengan baik.'
          : 'Terdapat capaian mata pelajaran di bawah standar KKM yang perlu diselesaikan.',
      sakit: sakit,
      izin: izin,
      alpa: alpa,
      catatanWali: catatan,
      kodeVerifikasiQr: 'RAPOR/MTS-ALFAJAR/${nisn ?? nis}/$semester/$tahunTeks/VALID',
      tanggalTerbit: semester == 'ganjil' ? '20 Desember 2026' : '25 Juni 2027',
    );
  }
}

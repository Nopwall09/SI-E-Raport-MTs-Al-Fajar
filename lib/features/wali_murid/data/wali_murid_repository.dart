import 'package:supabase_flutter/supabase_flutter.dart';

class NilaiMapelWali {
  const NilaiMapelWali({
    required this.mapel,
    this.kode,
    this.nilai,
    this.skm = 75,
    this.kategori = 'Umum',
    this.tanggalUpdate = 'Terbaru',
  });

  final String mapel;
  final String? kode;
  final num? nilai;
  final int skm;
  final String kategori;
  final String tanggalUpdate;

  bool get isTuntas => nilai != null && nilai! >= skm;
  String get statusText =>
      nilai == null ? 'Belum Ada' : (isTuntas ? 'Tuntas' : 'Perlu Bimbingan');
}

class AnakModel {
  const AnakModel({
    required this.id,
    this.kelasSiswaId,
    required this.nama,
    required this.nis,
    this.nisn,
    required this.kelas,
    this.waliKelas,
    this.rataRata,
    this.sakit = 0,
    this.izin = 0,
    this.alpa = 0,
    this.catatanWali,
    this.historiPerkembangan = const [],
    this.labelPerkembangan = const [],
    this.daftarNilai = const [],
  });

  final int id;
  final int? kelasSiswaId;
  final String nama;
  final String nis;
  final String? nisn;
  final String kelas;
  final String? waliKelas;
  final double? rataRata;
  final int sakit;
  final int izin;
  final int alpa;
  final String? catatanWali;
  final List<double> historiPerkembangan;
  final List<String> labelPerkembangan;
  final List<NilaiMapelWali> daftarNilai;

  String get predikat {
    if (rataRata == null) return '-';
    if (rataRata! >= 90) return 'Predikat A';
    if (rataRata! >= 80) return 'Predikat B';
    if (rataRata! >= 70) return 'Predikat C';
    return 'Predikat D';
  }
}

class WaliMuridRepository {
  WaliMuridRepository(this._db);

  final SupabaseClient _db;

  /// Memuat profil anak-anak dari wali murid yang sedang login beserta nilai
  /// dan catatan perkembangannya.
  Future<List<AnakModel>> getPerkembanganAnak({
    required String semester,
    int? tahunAjaranId,
  }) async {
    final currentUserId = _db.auth.currentUser?.id;
    if (currentUserId == null) return const [];

    // 1. Cari data wali murid
    final wali = await _db
        .from('wali_murid')
        .select('id, nama')
        .eq('user_id', currentUserId)
        .maybeSingle();

    // 2. Cari anak yang diasuh. Siswa yang login melihat dirinya sendiri
    // (halaman ini dipakai bersama), dan akun lain seperti guru tidak punya
    // anak sama sekali.
    final List<Map<String, dynamic>> siswaRows;
    if (wali != null) {
      siswaRows = await _db
          .from('siswa')
          .select('id, nis, nisn, nama, jk')
          .eq('wali_murid_id', wali['id'] as int);
    } else {
      siswaRows = await _db
          .from('siswa')
          .select('id, nis, nisn, nama, jk')
          .eq('user_id', currentUserId);
      if (siswaRows.isEmpty) return const [];
    }

    if (siswaRows.isEmpty) return const [];

    final listAnak = <AnakModel>[];

    for (final s in siswaRows) {
      final siswaId = s['id'] as int;

      // 3. Cari penempatan kelas siswa di tahun ajaran ini
      var queryKs = _db
          .from('kelas_siswa')
          .select(
            'id, kelas:kelas_id(id, nama, wali_kelas:wali_kelas_id(nama)), tahun_ajaran:tahun_ajaran_id(id, skm, semester_aktif)',
          )
          .eq('siswa_id', siswaId);

      if (tahunAjaranId != null) {
        queryKs = queryKs.eq('tahun_ajaran_id', tahunAjaranId);
      }

      final ksRows = await queryKs;
      if (ksRows.isEmpty) {
        listAnak.add(
          AnakModel(
            id: siswaId,
            nama: s['nama'] as String,
            nis: s['nis'] as String,
            nisn: s['nisn'] as String?,
            kelas: 'Belum Terdaftar',
          ),
        );
        continue;
      }

      final ks = ksRows.first;
      final ksId = ks['id'] as int;
      final kelasData = ks['kelas'] as Map<String, dynamic>?;
      final namaKelas = kelasData?['nama'] as String? ?? '-';
      final waliKelasData = kelasData?['wali_kelas'] as Map<String, dynamic>?;
      final namaWaliKelas = waliKelasData?['nama'] as String?;
      final taData = ks['tahun_ajaran'] as Map<String, dynamic>?;
      final skm = (taData?['skm'] as num?)?.toInt() ?? 75;

      // 4. Cari nilai UTS / detnilai anak
      final detnilaiRows = await _db
          .from('detnilai')
          .select('nilai, semester, mapel:mapel_id(nama, kode)')
          .eq('kelas_siswa_id', ksId)
          .eq('semester', semester);

      final daftarNilai = <NilaiMapelWali>[];
      var totalNilai = 0.0;
      var jumlahTerisi = 0;

      for (final dn in detnilaiRows) {
        final n = dn['nilai'] as num?;
        final mapelObj = dn['mapel'] as Map<String, dynamic>?;
        final namaMapel = mapelObj?['nama'] as String? ?? 'Mapel';
        final kodeMapel = mapelObj?['kode'] as String?;

        daftarNilai.add(
          NilaiMapelWali(
            mapel: namaMapel,
            kode: kodeMapel,
            nilai: n,
            skm: skm,
            kategori: kodeMapel != null &&
                    (kodeMapel == 'QH' ||
                        kodeMapel == 'FQH' ||
                        kodeMapel == 'AA' ||
                        kodeMapel == 'SKI')
                ? 'Agama'
                : 'Umum',
            tanggalUpdate: 'UTS $semester',
          ),
        );

        if (n != null) {
          totalNilai += n.toDouble();
          jumlahTerisi++;
        }
      }

      final rataRata = jumlahTerisi > 0 ? totalNilai / jumlahTerisi : null;

      // 5. Catatan rapor & kehadiran jika ada
      final raporRow = await _db
          .from('rapor')
          .select('sakit, izin, alpa, catatan')
          .eq('kelas_siswa_id', ksId)
          .eq('semester', semester)
          .maybeSingle();

      final sakit = (raporRow?['sakit'] as num?)?.toInt() ?? 0;
      final izin = (raporRow?['izin'] as num?)?.toInt() ?? 0;
      final alpa = (raporRow?['alpa'] as num?)?.toInt() ?? 0;
      final catatan = raporRow?['catatan'] as String?;

      listAnak.add(
        AnakModel(
          id: siswaId,
          kelasSiswaId: ksId,
          nama: s['nama'] as String,
          nis: s['nis'] as String,
          nisn: s['nisn'] as String?,
          kelas: namaKelas,
          waliKelas: namaWaliKelas,
          rataRata: rataRata,
          sakit: sakit,
          izin: izin,
          alpa: alpa,
          catatanWali: catatan,
          daftarNilai: daftarNilai,
        ),
      );
    }

    return listAnak;
  }
}

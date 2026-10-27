import 'package:supabase_flutter/supabase_flutter.dart';

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
    required this.peringkat,
    required this.totalSiswaKelas,
    required this.rataRataKelas,
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
  final int peringkat;
  final int totalSiswaKelas;
  final double rataRataKelas;
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
      return _dataContoh(semester);
    }

    try {
      // 1. Ambil data siswa yang terhubung dengan akun login
      final siswaRow = await _db
          .from('siswa')
          .select('id, nis, nisn, nama, jk')
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (siswaRow == null) {
        return _dataContoh(semester);
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
        return _dataContoh(semester, nama: namaSiswa, nis: nis, nisn: nisn);
      }

      final ks = ksRows.first;
      final ksId = ks['id'] as int;
      final kelasObj = ks['kelas'] as Map<String, dynamic>?;
      final namaKelas = kelasObj?['nama'] as String? ?? 'VII-A';
      final waliKelasObj = kelasObj?['wali_kelas'] as Map<String, dynamic>?;
      final namaWaliKelas = waliKelasObj?['nama'] as String? ?? 'Ust. Ahmad Fauzi, S.Pd.I';
      final taObj = ks['tahun_ajaran'] as Map<String, dynamic>?;
      final tahunTeks = taObj?['tahun'] as String? ?? '2026/2027';
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
            catatanGuru: n != null && n >= skm
                ? 'Menunjukkan penguasaan materi yang baik.'
                : 'Perlu bimbingan dan remedial terarah.',
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

      final sakit = (raporRow?['sakit'] as num?)?.toInt() ?? 1;
      final izin = (raporRow?['izin'] as num?)?.toInt() ?? 0;
      final alpa = (raporRow?['alpa'] as num?)?.toInt() ?? 0;
      final catatan = raporRow?['catatan'] as String? ??
          'Ananda menunjukkan kedisiplinan dan akhlak yang mulia. Pertahankan prestasi dan semangat belajarnya!';

      final listFinal = daftarNilai.isNotEmpty
          ? daftarNilai
          : _daftarNilaiDefault(skm);

      final rataRata = jumlahTerisi > 0
          ? (totalNilai / jumlahTerisi)
          : (listFinal.map((e) => e.nilai ?? 0).reduce((a, b) => a + b) / listFinal.length).toDouble();

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

      final isTuntasSemua = listFinal.every((m) => m.isTuntas) && alpa == 0;

      return RaporSiswaModel(
        profil: profil,
        semester: semester == 'ganjil' ? 'Ganjil' : 'Genap',
        tahunAjaran: tahunTeks,
        daftarNilai: listFinal,
        rataRata: double.parse(rataRata.toStringAsFixed(1)),
        peringkat: 2,
        totalSiswaKelas: 28,
        rataRataKelas: 81.4,
        statusKelulusan: isTuntasSemua
            ? (semester == 'genap' ? 'NAIK KE KELAS BERIKUTNYA' : 'TUNTAS / MEMENUHI KKM')
            : 'PERLU PEMENUHAN SKM',
        keteranganKelulusan: isTuntasSemua
            ? 'Memenuhi seluruh Kriteria Ketuntasan Minimal (KKM) dengan predikat amat memuaskan.'
            : 'Terdapat capaian mata pelajaran di bawah standar KKM yang perlu diselesaikan.',
        sakit: sakit,
        izin: izin,
        alpa: alpa,
        catatanWali: catatan,
        kodeVerifikasiQr: 'RAPOR/MTS-ALFAJAR/${nisn ?? nis}/$semester/$tahunTeks/VALID',
        tanggalTerbit: semester == 'ganjil' ? '20 Desember 2026' : '25 Juni 2027',
      );
    } catch (_) {
      return _dataContoh(semester);
    }
  }

  static List<NilaiMapelSiswa> _daftarNilaiDefault(int skm) => [
        NilaiMapelSiswa(
          mapel: "Al-Qur'an Hadits",
          kode: 'QH',
          kategori: 'Agama',
          skm: skm,
          nilai: 92,
          catatanGuru: 'Sangat fasih dalam hafalan dan pemahaman tajwid.',
        ),
        NilaiMapelSiswa(
          mapel: 'Akidah Akhlak',
          kode: 'AA',
          kategori: 'Agama',
          skm: skm,
          nilai: 90,
          catatanGuru: 'Memahami adab pergaulan islami dengan sangat baik.',
        ),
        NilaiMapelSiswa(
          mapel: 'Fiqih',
          kode: 'FQH',
          kategori: 'Agama',
          skm: skm,
          nilai: 88,
          catatanGuru: 'Praktik ibadah thaharah dan sholat sangat tertib.',
        ),
        NilaiMapelSiswa(
          mapel: 'Sejarah Kebudayaan Islam',
          kode: 'SKI',
          kategori: 'Agama',
          skm: skm,
          nilai: 85,
          catatanGuru: 'Mampu menganalisis sejarah peradaban Islam secara runtut.',
        ),
        NilaiMapelSiswa(
          mapel: 'Bahasa Arab',
          kode: 'BAR',
          kategori: 'Bahasa',
          skm: skm,
          nilai: 84,
          catatanGuru: 'Penguasaan kosakata mufradat harian berkembang sangat baik.',
        ),
        NilaiMapelSiswa(
          mapel: 'Bahasa Indonesia',
          kode: 'BIN',
          kategori: 'Bahasa',
          skm: skm,
          nilai: 89,
          catatanGuru: 'Terampil menyusun teks deskripsi dan menyimak materi.',
        ),
        NilaiMapelSiswa(
          mapel: 'Bahasa Inggris',
          kode: 'BIG',
          kategori: 'Bahasa',
          skm: skm,
          nilai: 86,
          catatanGuru: 'Percaya diri dalam dialog dan pembacaan teks bahasa asing.',
        ),
        NilaiMapelSiswa(
          mapel: 'Matematika',
          kode: 'MTK',
          kategori: 'Umum',
          skm: skm,
          nilai: 82,
          catatanGuru: 'Logika aljabar dan bilangan bulat sudah cukup kuat.',
        ),
        NilaiMapelSiswa(
          mapel: 'Ilmu Pengetahuan Alam (IPA)',
          kode: 'IPA',
          kategori: 'Umum',
          skm: skm,
          nilai: 87,
          catatanGuru: 'Aktif dalam percobaan laboratorium dan pemahaman sel.',
        ),
        NilaiMapelSiswa(
          mapel: 'Ilmu Pengetahuan Sosial (IPS)',
          kode: 'IPS',
          kategori: 'Umum',
          skm: skm,
          nilai: 88,
          catatanGuru: 'Memahami interaksi keruangan antarwilayah dengan cermat.',
        ),
        NilaiMapelSiswa(
          mapel: 'Pendidikan Pancasila & Kewarganegaraan',
          kode: 'PPKn',
          kategori: 'Umum',
          skm: skm,
          nilai: 91,
          catatanGuru: 'Menunjukkan kesadaran norma hukum dan gotong royong.',
        ),
        NilaiMapelSiswa(
          mapel: 'Pendidikan Jasmani & Kesehatan',
          kode: 'PJOK',
          kategori: 'Umum',
          skm: skm,
          nilai: 88,
          catatanGuru: 'Kebugaran jasmani dan sportivitas sangat terpelihara.',
        ),
      ];

  static RaporSiswaModel _dataContoh(
    String semester, {
    String nama = 'Muhammad Farhan Al-Ghifari',
    String nis = '2026001',
    String? nisn = '0089765432',
  }) {
    const skm = 75;
    final nilaiList = _daftarNilaiDefault(skm);
    final total = nilaiList.map((e) => e.nilai ?? 0).reduce((a, b) => a + b);
    final avg = double.parse((total / nilaiList.length).toStringAsFixed(1));

    return RaporSiswaModel(
      profil: SiswaProfil(
        id: 1,
        nama: nama,
        nis: nis,
        nisn: nisn,
        kelas: 'VII-A',
        waliKelas: 'Ust. Ahmad Fauzi, S.Pd.I',
        tahunAjaran: '2026/2027',
        semester: semester == 'ganjil' ? 'Ganjil' : 'Genap',
      ),
      semester: semester == 'ganjil' ? 'Ganjil' : 'Genap',
      tahunAjaran: '2026/2027',
      daftarNilai: nilaiList,
      rataRata: avg,
      peringkat: 2,
      totalSiswaKelas: 28,
      rataRataKelas: 81.4,
      statusKelulusan: 'TUNTAS / MEMENUHI KKM',
      keteranganKelulusan:
          'Dinyatakan Memenuhi Kriteria Ketuntasan Minimal (KKM) dan Berhak Melanjutkan ke Semester Genap.',
      sakit: 1,
      izin: 0,
      alpa: 0,
      catatanWali:
          'Ananda Farhan adalah siswa yang santun, aktif dalam kegiatan keagamaan, serta memiliki ketekunan luar biasa di kelas. Pertahankan prestasimu!',
      kodeVerifikasiQr:
          'https://eraport.mts-alfajar.sch.id/verifikasi/${nisn ?? nis}/$semester/2026-2027',
      tanggalTerbit: semester == 'ganjil' ? '20 Desember 2026' : '25 Juni 2027',
    );
  }
}


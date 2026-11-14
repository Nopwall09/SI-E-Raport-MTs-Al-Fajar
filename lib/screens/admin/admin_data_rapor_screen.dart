import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/error/app_exception.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/storage/sqlite_service.dart';
import '../../core/widgets/error_view.dart';
import '../../features/admin/data/admin_repository.dart';
import '../../features/admin/presentation/admin_providers.dart';
import '../../features/admin/presentation/admin_widgets.dart';
import '../../features/wali_kelas/data/absensi_pdf_service.dart';
import '../../features/wali_kelas/presentation/wali_kelas_providers.dart';
import '../../models/data_rapor_model.dart';
import '../../widgets/media_picker_dialog.dart';
import '../../widgets/motion.dart';
import '../../widgets/qr_code_widget.dart';
import 'widgets/admin_menu_drawer.dart';

/// Kesiapan rapor per kelas dan semester, dihitung dari nilai yang sudah
/// diinput guru. Filter terakhir diingat (SharedPreferences), daftar bisa
/// disimpan ke SQLite agar tetap terbuka tanpa internet, dan tiap siswa bisa
/// diberi QR-Code serta bukti fisik (kamera/galeri, Supabase Storage).
class AdminDataRaporScreen extends ConsumerStatefulWidget {
  const AdminDataRaporScreen({super.key});

  @override
  ConsumerState<AdminDataRaporScreen> createState() =>
      _AdminDataRaporScreenState();
}

class _AdminDataRaporScreenState extends ConsumerState<AdminDataRaporScreen> {
  int? _kelasId;
  String? _kelasPref;
  String _semester = 'ganjil';
  bool _hanyaSiap = false;
  bool _prefDimuat = false;

  @override
  void initState() {
    super.initState();
    _muatPreferensi();
  }

  Future<void> _muatPreferensi() async {
    final p = await LocalStorageService().ambilPreferensiRapor();
    if (!mounted) return;
    setState(() {
      _kelasPref = p.kelas;
      _semester = p.semester;
      _hanyaSiap = p.hanyaSiap;
      _prefDimuat = true;
    });
  }

  void _simpanPreferensi(String? kelasNama) =>
      LocalStorageService().simpanPreferensiRapor(
        kelas: kelasNama,
        semester: _semester,
        hanyaSiap: _hanyaSiap,
      );

  static String _labelSemester(String s) => s == 'ganjil' ? 'Ganjil' : 'Genap';

  @override
  Widget build(BuildContext context) {
    final opsi = ref.watch(opsiKelasProvider).valueOrNull ?? const <Opsi>[];
    final kelas =
        opsi.where((o) => o.id == _kelasId).firstOrNull ??
        opsi.where((o) => o.label == _kelasPref).firstOrNull ??
        opsi.firstOrNull;
    _kelasId = kelas?.id;

    final kunci = kelas == null
        ? null
        : (kelasId: kelas.id, kelasNama: kelas.label, semester: _semester);
    final data = kunci == null ? null : ref.watch(adminRaporProvider(kunci));

    return Scaffold(
      drawer: const AdminMenuDrawer(currentRoute: '/admin/rapor'),
      appBar: AppBar(
        title: const Text('Data Rapor'),
        actions: [
          // Options menu: menu titik tiga di app bar.
          PopupMenuButton<String>(
            tooltip: 'Menu',
            onSelected: (v) {
              final daftar = data?.valueOrNull;
              if (v == 'muat' && kunci != null) {
                ref.invalidate(adminRaporProvider(kunci));
              } else if (v == 'offline' && daftar != null && kelas != null) {
                _simpanLuring(daftar, kelas.label);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'muat', child: Text('Muat ulang')),
              PopupMenuItem(
                value: 'offline',
                child: Text('Simpan untuk offline'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _filter(opsi, kelas),
            const Divider(height: 1),
            Expanded(
              child: kelas == null || !_prefDimuat
                  ? (ref.watch(opsiKelasProvider).hasError
                        ? const Center(
                            child: Text('Daftar kelas gagal dimuat.'),
                          )
                        : const ListSkeleton())
                  : data!.when(
                      loading: () => const ListSkeleton(),
                      error: (e, _) => _luring(e, kelas, kunci!),
                      data: (list) => _daftar(list, kelas, kunci!),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filter(List<Opsi> opsi, Opsi? kelas) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            key: ValueKey(kelas?.id),
            initialValue: kelas?.id,
            decoration: const InputDecoration(labelText: 'Kelas'),
            items: [
              for (final o in opsi)
                DropdownMenuItem(value: o.id, child: Text(o.label)),
            ],
            onChanged: (id) {
              if (id == null) return;
              setState(() => _kelasId = id);
              _simpanPreferensi(opsi.firstWhere((o) => o.id == id).label);
            },
          ),
          const SizedBox(height: 8),
          // Radio: satu semester aktif pada satu waktu.
          RadioGroup<String>(
            groupValue: _semester,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _semester = v);
              _simpanPreferensi(kelas?.label);
            },
            child: Row(
              children: [
                for (final s in const ['ganjil', 'genap']) ...[
                  Radio<String>(value: s),
                  Text('Semester ${_labelSemester(s)}'),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            title: const Text('Hanya yang siap cetak'),
            value: _hanyaSiap,
            onChanged: (v) {
              setState(() => _hanyaSiap = v ?? false);
              _simpanPreferensi(kelas?.label);
            },
          ),
        ],
      ),
    );
  }

  Widget _daftar(
    List<DataRaporModel> semua,
    Opsi kelas,
    ({int kelasId, String kelasNama, String semester}) kunci, {
    String? catatanLuring,
  }) {
    final list = [
      for (final r in semua)
        if (!_hanyaSiap || r.isSiap) r,
    ];
    return Column(
      children: [
        if (catatanLuring != null)
          Container(
            width: double.infinity,
            color: kBrandSoft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_outlined, size: 18, color: kBrand),
                const SizedBox(width: 8),
                Expanded(child: Text(catatanLuring)),
                TextButton(
                  onPressed: () => ref.invalidate(adminRaporProvider(kunci)),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          )
        else if (semua.isNotEmpty)
          _headerStatusAcc(semua, kelas, kunci),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(
                    semua.isEmpty
                        ? 'Kelas ini belum punya siswa.'
                        : 'Belum ada rapor yang siap.',
                    style: const TextStyle(color: kMuted),
                  ),
                )
              : RefreshIndicator(
                  color: kBrand,
                  onRefresh: () async {
                    ref.invalidate(adminRaporProvider(kunci));
                    try {
                      await ref.read(adminRaporProvider(kunci).future);
                    } catch (_) {}
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        FadeSlideIn(index: i, child: _kartu(list[i])),
                  ),
                ),
        ),
        if (catatanLuring == null)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: semua.isEmpty
                    ? null
                    : () => _simpanLuring(semua, kelas.label),
                icon: const Icon(Icons.cloud_download_outlined, size: 20),
                label: const Text('Simpan untuk dibuka offline'),
              ),
            ),
          ),
      ],
    );
  }

  /// Gagal memuat dari server: tampilkan salinan SQLite bila ada.
  Widget _luring(
    Object error,
    Opsi kelas,
    ({int kelasId, String kelasNama, String semester}) kunci,
  ) {
    final pesan = AppException.from(error).message;
    return FutureBuilder<List<Map<String, Object?>>>(
      future: SqliteOfflineService().bacaRapor(
        kelas: kelas.label,
        semester: _semester,
      ),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const ListSkeleton();
        }
        final baris = snap.data ?? const [];
        if (baris.isEmpty) {
          return Center(
            child: ErrorView(
              message: pesan,
              onRetry: () => ref.invalidate(adminRaporProvider(kunci)),
            ),
          );
        }
        final tersimpan = DateTime.tryParse(
          baris.first['tersimpan_pada'] as String,
        );
        return _daftar(
          [
            for (final r in baris)
              DataRaporModel(
                id: '${r['siswa_id']}',
                namaSiswa: r['nama_siswa'] as String,
                nisn: r['nisn'] as String,
                kelas: r['kelas'] as String,
                semester: r['semester'] as String,
                mapelSelesai: r['mapel_selesai'] as int,
                totalMapel: r['total_mapel'] as int,
              ),
          ],
          kelas,
          kunci,
          catatanLuring:
              'Tidak tersambung. Menampilkan salinan offline'
              '${tersimpan == null ? '' : ' (${_tanggal(tersimpan)})'}.',
        );
      },
    );
  }

  static String _tanggal(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}-${t.month.toString().padLeft(2, '0')}-${t.year}';

  Future<void> _simpanLuring(List<DataRaporModel> semua, String kelas) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SqliteOfflineService().simpanRapor(
        kelas: kelas,
        semester: _semester,
        baris: [
          for (final r in semua)
            {
              'siswa_id': int.parse(r.id),
              'semester': r.semester,
              'nama_siswa': r.namaSiswa,
              'nisn': r.nisn,
              'kelas': r.kelas,
              'mapel_selesai': r.mapelSelesai,
              'total_mapel': r.totalMapel,
            },
        ],
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${semua.length} siswa kelas $kelas disimpan untuk dibuka offline.',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan salinan offline.')),
      );
    }
  }

  Widget _headerStatusAcc(
    List<DataRaporModel> semua,
    Opsi kelas,
    ({int kelasId, String kelasNama, String semester}) kunci,
  ) {
    final isSemuaFinal = semua.isNotEmpty && semua.every((r) => r.isFinal);
    final isSemuaMenungguAcc =
        semua.isNotEmpty && semua.every((r) => r.isMenungguAcc);
    final siapCount = semua.where((r) => r.isSiap).length;

    Color bg;
    Color border;
    Color iconColor;
    IconData icon;
    String title;
    String subtitle;

    if (isSemuaFinal) {
      bg = const Color(0xFFECFDF5);
      border = const Color(0xFF10B981);
      iconColor = const Color(0xFF059669);
      icon = Icons.verified;
      title = 'Rapor Kelas Telah Di-ACC (Final)';
      subtitle = 'Nilai dan presensi telah disahkan resmi dan dikunci permanen.';
    } else if (isSemuaMenungguAcc) {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFF59E0B);
      iconColor = const Color(0xFFD97706);
      icon = Icons.hourglass_top_outlined;
      title = 'Menunggu ACC Admin / Kepala Madrasah';
      subtitle =
          'Wali kelas telah mengajukan verifikasi ($siapCount/${semua.length} siswa siap nilai).';
    } else {
      bg = Colors.white;
      border = kBorder;
      iconColor = siapCount == semua.length ? kBrand : const Color(0xFFD97706);
      icon = siapCount == semua.length
          ? Icons.check_circle_outline
          : Icons.info_outline;
      title = 'Status Rapor: Draft Pengisian';
      subtitle = '$siapCount dari ${semua.length} siswa siap nilai rapor.';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: kText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Cetak Rekap Presensi PDF
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(fontSize: 11.5),
                ),
                onPressed: () => _cetakAbsensiKelasAdmin(kelas, kunci),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 15),
                label: const Text('Cetak Rekap Presensi PDF'),
              ),

              // Tombol ACC & Finalisasi jika belum final
              if (!isSemuaFinal)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kBrand,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(fontSize: 11.5),
                  ),
                  onPressed: () => _konfirmasiFinalisasiAdmin(
                    kelas: kelas,
                    kunci: kunci,
                    belumLengkap: semua.length - siapCount,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 15),
                  label: Text(
                    isSemuaMenungguAcc ? 'ACC & Sahkan Rapor' : 'Finalisasi Rapor',
                  ),
                ),

              // Tombol Buka Kunci (Revisi) jika sudah final
              if (isSemuaFinal)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD97706),
                    side: const BorderSide(color: Color(0xFFD97706)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(fontSize: 11.5),
                  ),
                  onPressed: () => _konfirmasiBukaKunciAdmin(kelas, kunci),
                  icon: const Icon(Icons.lock_open_outlined, size: 15),
                  label: const Text('Buka Kunci (Revisi)'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cetakAbsensiKelasAdmin(
    Opsi kelas,
    ({int kelasId, String kelasNama, String semester}) kunci,
  ) async {
    try {
      final ta = await ref.read(tahunAjaranAktifProvider.future);
      final repo = ref.read(waliKelasRepositoryProvider);
      final siswaList = await repo.progres(
        kelasId: kelas.id,
        semester: kunci.semester,
      );

      await AbsensiPdfService.cetakAtauPratinjauPdf(
        siswa: siswaList,
        kelasNama: kelas.label,
        semester: kunci.semester,
        tahunAjaran: ta.tahun,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Gagal mencetak presensi: $e'),
        ),
      );
    }
  }

  Future<void> _konfirmasiFinalisasiAdmin({
    required Opsi kelas,
    required ({int kelasId, String kelasNama, String semester}) kunci,
    required int belumLengkap,
  }) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ACC & Finalisasi Kelas ${kelas.label}?'),
        content: Text(
          belumLengkap > 0
              ? 'Peringatan: Ada $belumLengkap siswa yang nilainya belum lengkap dari semua mapel.\n\nApakah Anda yakin ingin tetap mengesahkan (ACC) dan memfinalisasi rapor kelas ini?'
              : 'Setelah di-ACC dan difinalisasi, seluruh nilai & presensi akan dikunci permanen, serta notifikasi rapor siap akan dikirimkan ke siswa dan wali murid.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kBrand),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ACC & Finalisasi'),
          ),
        ],
      ),
    );

    if (setuju != true || !mounted) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.finalisasiRapor(
        kelasId: kelas.id,
        semester: kunci.semester,
      );
      // Memicu notifikasi FCM
      await repo.kirimNotifikasiFinal(
        kelasId: kelas.id,
        semester: kunci.semester,
      );
      ref.invalidate(adminRaporProvider(kunci));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: kBrand,
            content: Text(
              'Rapor kelas ${kelas.label} berhasil di-ACC dan difinalisasi.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Gagal memfinalisasi rapor: $e'),
          ),
        );
      }
    }
  }

  Future<void> _konfirmasiBukaKunciAdmin(
    Opsi kelas,
    ({int kelasId, String kelasNama, String semester}) kunci,
  ) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Buka Kunci Rapor Kelas ${kelas.label}?'),
        content: const Text(
          'Membuka kunci akan mengembalikan status rapor ke Draft sehingga guru pengampu dapat memperbaiki/merevisi nilai.\n\nLanjutkan pembukaan kunci?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Buka Kunci'),
          ),
        ],
      ),
    );

    if (setuju != true || !mounted) return;

    try {
      await ref.read(adminRepositoryProvider).bukaKunciRapor(
            kelasId: kelas.id,
            semester: kunci.semester,
          );
      ref.invalidate(adminRaporProvider(kunci));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: kBrand,
            content: Text(
              'Kunci rapor kelas ${kelas.label} berhasil dibuka untuk revisi.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Gagal membuka kunci rapor: $e'),
          ),
        );
      }
    }
  }

  Widget _kartu(DataRaporModel r) {
    return GestureDetector(
      // Context menu: tekan lama.
      onLongPressStart: (d) => _menuTekanLama(d.globalPosition, r),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadiusCard),
          onTap: () => _pratinjau(r),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.namaSiswa,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nilai ${r.mapelSelesai}/${r.totalMapel} mapel',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: r.isFinal
                        ? const Color(0xFFECFDF5)
                        : r.isMenungguAcc
                            ? const Color(0xFFFFFBEB)
                            : r.isSiap
                                ? kBrandSoft
                                : kField,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    r.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: r.isFinal
                          ? const Color(0xFF059669)
                          : r.isMenungguAcc
                              ? const Color(0xFFD97706)
                              : r.isSiap
                                  ? kBrand
                                  : kMuted,
                    ),
                  ),
                ),
                // Popup menu: tombol titik tiga.
                PopupMenuButton<String>(
                  tooltip: 'Aksi rapor ${r.namaSiswa}',
                  onSelected: (v) => _jalankan(v, r),
                  itemBuilder: (_) => _itemMenu(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _itemMenu() => const [
    PopupMenuItem(value: 'preview', child: Text('Pratinjau')),
    PopupMenuItem(value: 'qr', child: Text('QR-Code')),
    PopupMenuItem(value: 'unggah', child: Text('Unggah bukti fisik')),
    PopupMenuItem(value: 'lihat', child: Text('Lihat bukti fisik')),
  ];

  Future<void> _menuTekanLama(Offset p, DataRaporModel r) async {
    final v = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(p.dx, p.dy, p.dx + 1, p.dy + 1),
      items: _itemMenu(),
    );
    if (v != null) _jalankan(v, r);
  }

  void _jalankan(String aksi, DataRaporModel r) {
    switch (aksi) {
      case 'preview':
        _pratinjau(r);
      case 'qr':
        _qr(r);
      case 'unggah':
        _unggahBukti(r);
      case 'lihat':
        _lihatBukti(r);
    }
  }

  void _pratinjau(DataRaporModel r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(r.namaSiswa, style: Theme.of(ctx).textTheme.titleLarge),
              Text(
                'NISN ${r.nisn}, kelas ${r.kelas}, semester ${_labelSemester(r.semester)}',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              _baris(
                'Nilai terisi',
                '${r.mapelSelesai} dari ${r.totalMapel} mapel',
              ),
              _baris('Status', r.status),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _qr(r);
                },
                icon: const Icon(Icons.qr_code_2, size: 20),
                label: const Text('QR-Code'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _unggahBukti(r);
                },
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                label: const Text('Unggah bukti fisik'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _lihatBukti(r);
                },
                icon: const Icon(Icons.image_outlined, size: 20),
                label: const Text('Lihat bukti fisik'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _baris(String label, String nilai) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: kMuted)),
        Flexible(
          child: Text(
            nilai,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  /// QR berisi identitas rapor (nama, NISN, kelas, semester) sebagai teks
  /// biasa. Tidak ada server verifikasi, jadi QR ini bukan tanda keaslian.
  void _qr(DataRaporModel r) {
    tampilkanDialogQr(
      context,
      judul: 'QR-Code Rapor',
      nama: r.namaSiswa,
      info: [
        ('NISN', r.nisn),
        ('Kelas', r.kelas),
        ('Semester', _labelSemester(r.semester)),
      ],
      isiQr:
          'RAPOR MTs AL FAJAR KANDAT\n'
          'Nama: ${r.namaSiswa}\n'
          'NISN: ${r.nisn}\n'
          'Kelas: ${r.kelas}\n'
          'Semester: ${_labelSemester(r.semester)}',
    );
  }

  void _unggahBukti(DataRaporModel r) {
    MediaPickerDialog.show(
      context,
      title: 'Bukti fisik rapor',
      studentName: r.namaSiswa,
      onPicked: (file) async {
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        await simpan(
          context,
          () => ref
              .read(adminRepositoryProvider)
              .unggahBuktiRapor(
                siswaId: int.parse(r.id),
                semester: r.semester,
                bytes: bytes,
                mime: mimeGambar(file),
              ),
          'Bukti fisik ${r.namaSiswa} tersimpan.',
        );
      },
    );
  }

  Future<void> _lihatBukti(DataRaporModel r) async {
    final messenger = ScaffoldMessenger.of(context);
    String? url;
    try {
      url = await ref
          .read(adminRepositoryProvider)
          .urlBuktiRapor(siswaId: int.parse(r.id), semester: r.semester);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppException.from(e).message)),
      );
      return;
    }
    if (!mounted) return;
    if (url == null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Belum ada bukti fisik untuk ${r.namaSiswa}.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Bukti fisik ${r.namaSiswa}'),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(kRadiusControl),
          child: Image.network(
            url!,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, p) => p == null
                ? child
                : const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  ),
            errorBuilder: (_, _, _) =>
                const Text('Gambar tidak bisa ditampilkan.'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

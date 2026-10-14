import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/motion.dart';
import '../../features/admin/presentation/admin_providers.dart';
import '../../features/admin/presentation/admin_widgets.dart';
import '../../models/siswa_model.dart';

class AdminDataSiswaScreen extends ConsumerStatefulWidget {
  const AdminDataSiswaScreen({
    super.key,
  });

  @override
  ConsumerState<AdminDataSiswaScreen> createState() => _AdminDataSiswaScreenState();
}

class _AdminDataSiswaScreenState extends ConsumerState<AdminDataSiswaScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedKelas = 'Semua';

  List<String> _kelasList = const [];

  List<SiswaModel> _daftarSiswa = const [];

  List<SiswaModel> get _filteredSiswa {
    final query = _searchController.text.trim().toLowerCase();
    return _daftarSiswa.where((siswa) {
      final matchesQuery = query.isEmpty ||
          siswa.nama.toLowerCase().contains(query) ||
          siswa.nisn.toLowerCase().contains(query);
      final matchesKelas =
          _selectedKelas == 'Semua' || siswa.kelas == _selectedKelas;
      return matchesQuery && matchesKelas;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lista = ref.watch(adminSiswaProvider);
    _daftarSiswa = lista.valueOrNull ?? const [];
    _kelasList = [
      'Semua',
      ...?ref.watch(opsiKelasProvider).valueOrNull?.map((o) => o.label),
    ];
    const brandColor = kBrand;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Data Siswa',
          style: TextStyle(
            color: kText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: statusAsync(lista, () => ref.invalidate(adminSiswaProvider)) ??
          SafeArea(
        child: Column(
          children: [
            // Search Box & Filter Kelas
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Text Field: Cari nama/NISN (sesuai wireframe)
                  Container(
                    decoration: BoxDecoration(
                      color: kField,
                      borderRadius: BorderRadius.circular(kRadiusControl),
                      border: Border.all(color: kBorder),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari nama/NISN',
                        hintStyle: TextStyle(
                          color: kMuted,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Filter Chip Kelas
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _kelasList.map((kelas) {
                        final isSelected = _selectedKelas == kelas;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => setState(() => _selectedKelas = kelas),
                            borderRadius: BorderRadius.circular(999),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? brandColor
                                    : kField,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isSelected
                                      ? brandColor
                                      : kBorder,
                                ),
                              ),
                              child: Text(
                                kelas == 'Semua' ? 'Semua Kelas' : 'Kelas $kelas',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : kMuted,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Daftar Siswa
            Expanded(
              child: _filteredSiswa.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_outlined,
                              size: 48, color: kMuted),
                          const SizedBox(height: 8),
                          Text(
                            'Siswa tidak ditemukan',
                            style: TextStyle(
                              color: kMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: kBrand,
                      onRefresh: () async {
                        ref.invalidate(adminSiswaProvider);
                        try {
                          await ref.read(adminSiswaProvider.future);
                        } catch (_) {}
                      },
                      child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: _filteredSiswa.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final siswa = _filteredSiswa[index];
                        return FadeSlideIn(
                          index: index,
                          child: PressScale(child: _buildSiswaCard(siswa, brandColor)),
                        );
                      },
                    ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSiswaSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }

  Widget _buildSiswaCard(SiswaModel siswa, Color brandColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kBorder),
        boxShadow: kCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadiusCard),
          onTap: () => _showSiswaDetailSheet(context, siswa, brandColor),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: brandColor.withValues(alpha: 0.1),
                  child: Text(
                    siswa.nama.isNotEmpty ? siswa.nama[0] : 'S',
                    style: TextStyle(
                      color: brandColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        siswa.nama,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'NISN: ${siswa.nisn} · Kelas ${siswa.kelas}',
                        style: TextStyle(
                          fontSize: 12,
                          color: kMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: kMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSiswaDetailSheet(
      BuildContext context, SiswaModel siswa, Color brandColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detail Siswa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kText,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: brandColor.withValues(alpha: 0.12),
                child: Text(
                  siswa.nama[0],
                  style: TextStyle(
                    color: brandColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              title: Text(
                siswa.nama,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text('Status: ${siswa.status}'),
            ),
            const Divider(),
            _buildDetailRow('NISN', siswa.nisn),
            _buildDetailRow('Kelas', siswa.kelas),
            _buildDetailRow('Jenis Kelamin',
                siswa.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan'),
            _buildDetailRow(
                'Nama Orang Tua / Wali',
                siswa.namaWali.isNotEmpty
                    ? siswa.namaWali
                    : 'Belum terhubung'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusControl),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Membuka lembar nilai ${siswa.nama}...'),
                  ),
                );
              },
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('Lihat Rekap Nilai Siswa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: kMuted),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSiswaSheet(BuildContext context) async {
    final kelas = await ref.read(opsiKelasProvider.future);
    final wali = await ref.read(opsiWaliMuridProvider.future);
    if (!context.mounted) return;
    if (kelas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buat kelas dulu sebelum menambah siswa.')),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final nisCtrl = TextEditingController();
    final nisnCtrl = TextEditingController();
    int selectedKelas = kelas.first.id;
    int? selectedWali;
    String selectedJK = 'L';
    DateTime? tglLahir;

    InputDecoration dekor(String label, {String? hint}) => InputDecoration(
          labelText: label,
          hintText: hint,
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tambah Siswa Baru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration:
                    dekor('Nama Lengkap Siswa', hint: 'Contoh: Ahmad Fauzan'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nisCtrl,
                      keyboardType: TextInputType.number,
                      decoration: dekor('NIS'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: nisnCtrl,
                      keyboardType: TextInputType.number,
                      decoration: dekor('NISN (opsional)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedKelas,
                      decoration: dekor('Kelas'),
                      items: [
                        for (final k in kelas)
                          DropdownMenuItem(value: k.id, child: Text(k.label)),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedKelas = val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedJK,
                      decoration: dekor('Jenis Kelamin'),
                      items: const [
                        DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                        DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedJK = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final tgl = await showDatePicker(
                    context: ctx,
                    initialDate: tglLahir ?? DateTime(2012),
                    firstDate: DateTime(1990),
                    lastDate: DateTime.now(),
                  );
                  if (tgl != null) setModalState(() => tglLahir = tgl);
                },
                child: InputDecorator(
                  decoration: dekor('Tanggal Lahir'),
                  child: Text(
                    tglLahir == null
                        ? 'Pilih tanggal'
                        : '${tglLahir!.day.toString().padLeft(2, '0')}-'
                            '${tglLahir!.month.toString().padLeft(2, '0')}-'
                            '${tglLahir!.year}',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                initialValue: selectedWali,
                decoration: dekor('Orang Tua / Wali (opsional)'),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('Belum terhubung')),
                  for (final w in wali)
                    DropdownMenuItem<int?>(value: w.id, child: Text(w.label)),
                ],
                onChanged: (val) => setModalState(() => selectedWali = val),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadiusControl),
                  ),
                ),
                onPressed: () async {
                  final nama = nameCtrl.text.trim();
                  if (nama.isEmpty ||
                      nisCtrl.text.trim().isEmpty ||
                      tglLahir == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Nama, NIS, dan tanggal lahir wajib diisi.'),
                      ),
                    );
                    return;
                  }
                  final nisn = nisnCtrl.text.trim();
                  final ok = await simpan(
                    context,
                    () => ref.read(adminRepositoryProvider).tambahSiswa(
                          nama: nama,
                          nis: nisCtrl.text.trim(),
                          nisn: nisn.isEmpty ? null : nisn,
                          jk: selectedJK,
                          tglLahir: tglLahir!,
                          kelasId: selectedKelas,
                          waliMuridId: selectedWali,
                        ),
                    'Siswa $nama berhasil ditambahkan.',
                  );
                  if (!ok) return;
                  ref.invalidate(adminSiswaProvider);
                  ref.invalidate(adminKelasProvider);
                  ref.invalidate(adminStatistikProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text(
                  'Simpan Data Siswa',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/mapel_model.dart';
import 'widgets/admin_menu_drawer.dart';

class AdminMataPelajaranScreen extends ConsumerStatefulWidget {
  const AdminMataPelajaranScreen({super.key});

  @override
  ConsumerState<AdminMataPelajaranScreen> createState() =>
      _AdminMataPelajaranScreenState();
}

class _AdminMataPelajaranScreenState
    extends ConsumerState<AdminMataPelajaranScreen> {
  final List<String> _daftarNamaGuru = [
    'Ust. Zulkifli, S.Pd.I',
    'Ust. M. Rasyid, Lc',
    'Ust. Ahmad Fauzi, S.Pd.I',
    'Ibu Nur Azizah, S.Pd',
    'Ibu Siti Rahma, S.Si',
    'Bpk. Hendra Wijaya, M.Pd',
    'Ibu Ratna Dewi, S.Pd',
  ];

  final List<MapelModel> _daftarMapel = [
    const MapelModel(
      id: '1',
      kode: 'QH',
      nama: "Al-Qur'an Hadits",
      guruPengampu: 'Ust. Zulkifli, S.Pd.I',
      kategori: 'Agama',
    ),
    const MapelModel(
      id: '2',
      kode: 'AA',
      nama: 'Akidah Akhlak',
      guruPengampu: 'Ust. M. Rasyid, Lc',
      kategori: 'Agama',
    ),
    const MapelModel(
      id: '3',
      kode: 'FQ',
      nama: 'Fiqih',
      guruPengampu: 'Ust. M. Rasyid, Lc',
      kategori: 'Agama',
    ),
    const MapelModel(
      id: '4',
      kode: 'SKI',
      nama: 'Sejarah Kebudayaan Islam',
      guruPengampu: 'Ust. Ahmad Fauzi, S.Pd.I',
      kategori: 'Agama',
    ),
    const MapelModel(
      id: '5',
      kode: 'ARB',
      nama: 'Bahasa Arab',
      guruPengampu: 'Ust. Ahmad Fauzi, S.Pd.I',
      kategori: 'Bahasa',
    ),
    const MapelModel(
      id: '6',
      kode: 'MTK',
      nama: 'Matematika',
      guruPengampu: 'Ibu Nur Azizah, S.Pd',
      kategori: 'Umum',
    ),
    const MapelModel(
      id: '7',
      kode: 'IPA',
      nama: 'IPA Terpadu',
      guruPengampu: 'Ibu Siti Rahma, S.Si',
      kategori: 'Umum',
    ),
    const MapelModel(
      id: '8',
      kode: 'ENG',
      nama: 'Bahasa Inggris',
      guruPengampu: 'Bpk. Hendra Wijaya, M.Pd',
      kategori: 'Bahasa',
    ),
    const MapelModel(
      id: '9',
      kode: 'IND',
      nama: 'Bahasa Indonesia',
      guruPengampu: 'Ibu Ratna Dewi, S.Pd',
      kategori: 'Bahasa',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      drawer: const AdminMenuDrawer(currentRoute: '/admin/mapel'),
      appBar: AppBar(
        title: const Text(
          'Mata Pelajaran',
          style: TextStyle(
            color: kText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _daftarMapel.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = _daftarMapel[index];
            return _buildMapelCard(item);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE2E8F0),
        foregroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        elevation: 2,
        onPressed: () => _showAddMapelSheet(context),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  /// [FrameLayout (Stack)] & [ContextMenu (onLongPress)] & [PopupMenu (PopupMenuButton)]
  Widget _buildMapelCard(MapelModel item) {
    return GestureDetector(
      // [ContextMenu]: Membuka floating context menu saat user menekan lama pada kartu
      onLongPressStart: (details) =>
          _showFloatingContextMenu(context, details.globalPosition, item),
      child: Stack(
        // [FrameLayout]: Menggunakan Stack & Positioned untuk menyusun elemen overlay
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showMapelDetail(context, item),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.nama,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Guru pengampu: ${item.guruPengampu}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // [PopupMenu]: Tombol titik tiga dengan aksi cepat
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        tooltip: 'Pilihan Mapel',
                        onSelected: (val) {
                          if (val == 'detail') {
                            _showMapelDetail(context, item);
                          } else if (val == 'hapus') {
                            _konfirmasiHapusMapel(context, item);
                          } else if (val == 'edit') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Edit mapel ${item.nama}...'),
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'detail',
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 18),
                                SizedBox(width: 8),
                                Text('Lihat Detail'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Mapel'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'hapus',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Hapus',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // [FrameLayout Overlay / Positioned]
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(8),
                ),
                border: Border.all(color: Colors.grey.shade300, width: 0.8),
              ),
              child: Text(
                item.kode,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// [ContextMenu]: Muncul saat pengguna menekan lama (Long Press) pada item
  void _showFloatingContextMenu(
      BuildContext context, Offset position, MapelModel item) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          value: 'detail',
          child: Row(
            children: [
              const Icon(Icons.description_outlined, size: 18),
              const SizedBox(width: 8),
              Text('Detail: ${item.nama}'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'jadwal',
          child: Row(
            children: [
              Icon(Icons.schedule, size: 18),
              SizedBox(width: 8),
              Text('Atur Jadwal Pelajaran'),
            ],
          ),
        ),
      ],
    ).then((val) {
      if (val == 'detail') {
        _showMapelDetail(context, item);
      } else if (val == 'jadwal') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Atur jadwal untuk ${item.nama}')),
        );
      }
    });
  }

  void _showMapelDetail(BuildContext context, MapelModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.nama,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Kode Mata Pelajaran', item.kode),
            _buildDetailRow('Kategori', item.kategori),
            _buildDetailRow('Guru Pengampu', item.guruPengampu),
            _buildDetailRow('Standar Ketuntasan (SKM)', '75'),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: kBrand),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Membuka penugasan kelas mapel ${item.nama}...'),
                  ),
                );
              },
              icon: const Icon(Icons.assignment_outlined, size: 18),
              label: const Text('Kelola Penugasan Kelas'),
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
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  void _konfirmasiHapusMapel(BuildContext context, MapelModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Mata Pelajaran'),
        content: Text('Yakin ingin menghapus ${item.nama}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _daftarMapel.removeWhere((m) => m.id == item.id));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Mapel ${item.nama} telah dihapus.')),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  /// Form Tambah Mapel: Memuat [AutoCompleteTextView], [TimePickerDialog], & [RadioButton]
  void _showAddMapelSheet(BuildContext context) {
    final namaCtrl = TextEditingController();
    final kodeCtrl = TextEditingController();
    String selectedGuru = '';
    TimeOfDay selectedJam = const TimeOfDay(hour: 7, minute: 30);
    String selectedKategori = 'Agama';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tambah Mata Pelajaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: kodeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Kode Mapel',
                    hintText: 'Contoh: IPA, MTK, FQ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: namaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama Mata Pelajaran',
                    hintText: 'Contoh: Ilmu Pengetahuan Alam',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // [AutoCompleteTextView]: Auto-suggest nama guru pengampu saat diketik
                const Text(
                  'Guru Pengampu (Auto-Complete):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _daftarNamaGuru.where((String option) {
                      return option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    selectedGuru = selection;
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: 'Ketik nama guru pengampu...',
                        prefixIcon: const Icon(Icons.person_search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (val) => selectedGuru = val,
                    );
                  },
                ),

                const SizedBox(height: 14),

                // [TimePickerDialog]: Memilih jam mulai pelajaran
                InkWell(
                  onTap: () async {
                    // Panggilan TimePickerDialog resmi Flutter
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedJam,
                    );
                    if (picked != null) {
                      setModalState(() => selectedJam = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 20, color: kBrand),
                            const SizedBox(width: 8),
                            Text(
                              'Jam Pelajaran: ${selectedJam.format(context)}',
                              style: const TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Text(
                          'Pilih Jam',
                          style: TextStyle(
                              color: kBrand,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // [RadioButton]: Memilih Kategori Mapel secara eksklusif
                const Text(
                  'Kategori Mapel (RadioButton):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                RadioListTile<String>(
                  title: const Text('Pendidikan Agama Islam (Agama)'),
                  value: 'Agama',
                  groupValue: selectedKategori,
                  activeColor: kBrand,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedKategori = val);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Mata Pelajaran Umum'),
                  value: 'Umum',
                  groupValue: selectedKategori,
                  activeColor: kBrand,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedKategori = val);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Bahasa'),
                  value: 'Bahasa',
                  groupValue: selectedKategori,
                  activeColor: kBrand,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedKategori = val);
                    }
                  },
                ),

                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kBrand,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    if (namaCtrl.text.trim().isEmpty ||
                        kodeCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Kode dan Nama Mapel wajib diisi.')),
                      );
                      return;
                    }
                    setState(() {
                      _daftarMapel.insert(
                        0,
                        MapelModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          kode: kodeCtrl.text.trim().toUpperCase(),
                          nama: namaCtrl.text.trim(),
                          guruPengampu: selectedGuru.isNotEmpty
                              ? selectedGuru
                              : 'Belum ditentukan',
                          kategori: selectedKategori,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Mapel ${namaCtrl.text.trim()} berhasil ditambahkan.')),
                    );
                  },
                  child: const Text('Simpan Mata Pelajaran',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

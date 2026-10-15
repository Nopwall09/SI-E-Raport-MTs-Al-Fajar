import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/tahun_ajaran_model.dart';
import 'widgets/admin_menu_drawer.dart';

class AdminTahunAjaranScreen extends ConsumerStatefulWidget {
  const AdminTahunAjaranScreen({super.key});

  @override
  ConsumerState<AdminTahunAjaranScreen> createState() =>
      _AdminTahunAjaranScreenState();
}

class _AdminTahunAjaranScreenState
    extends ConsumerState<AdminTahunAjaranScreen> {
  final List<TahunAjaranModel> _daftarTahunAjaran = [
    const TahunAjaranModel(
      id: '1',
      tahun: '2026/2027',
      semester: 'Ganjil',
      isActive: true,
      skm: 75,
    ),
    const TahunAjaranModel(
      id: '2',
      tahun: '2025/2026',
      semester: 'Genap',
      isActive: false,
      skm: 75,
    ),
    const TahunAjaranModel(
      id: '3',
      tahun: '2025/2026',
      semester: 'Ganjil',
      isActive: false,
      skm: 75,
    ),
    const TahunAjaranModel(
      id: '4',
      tahun: '2024/2025',
      semester: 'Genap',
      isActive: false,
      skm: 75,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      drawer: const AdminMenuDrawer(currentRoute: '/admin/tahun-ajaran'),
      appBar: AppBar(
        title: const Text(
          'Tahun Ajaran',
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
          itemCount: _daftarTahunAjaran.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _daftarTahunAjaran[index];
            return _buildTahunAjaranCard(item);
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
        onPressed: () => _showAddTahunAjaranSheet(context),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  /// [FrameLayout (Stack)] & [PopupMenu (PopupMenuButton)] & [ContextMenu (onLongPress)]
  Widget _buildTahunAjaranCard(TahunAjaranModel item) {
    return GestureDetector(
      // [ContextMenu]: Floating context menu saat ditekan lama
      onLongPressStart: (details) =>
          _showTahunAjaranContextMenu(context, details.globalPosition, item),
      child: Stack(
        // [FrameLayout]: Tumpukan kartu dengan badge posisi khusus
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: item.isActive
                    ? const Color(0xFF86EFAC)
                    : Colors.grey.shade300,
                width: item.isActive ? 1.6 : 1.2,
              ),
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
                onTap: () => _showTahunAjaranDetail(context, item),
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
                              item.tahun,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Semester ${item.semester}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: const Text(
                            'Aktif',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),

                      // [PopupMenu]: Tombol titik tiga untuk aksi per tahun ajaran
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        tooltip: 'Pilihan Tahun Ajaran',
                        onSelected: (val) {
                          if (val == 'aktifkan') {
                            _setAsAktif(item);
                          } else if (val == 'detail') {
                            _showTahunAjaranDetail(context, item);
                          } else if (val == 'hapus') {
                            _hapusTahunAjaran(item);
                          }
                        },
                        itemBuilder: (context) => [
                          if (!item.isActive)
                            const PopupMenuItem(
                              value: 'aktifkan',
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 18, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Jadikan Aktif'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'detail',
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 18),
                                SizedBox(width: 8),
                                Text('Detail Tahun Ajaran'),
                              ],
                            ),
                          ),
                          if (!item.isActive)
                            const PopupMenuItem(
                              value: 'hapus',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Hapus Arsip',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (item.isActive)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 6,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// [ContextMenu]: Menu konteks melayang
  void _showTahunAjaranContextMenu(
      BuildContext context, Offset position, TahunAjaranModel item) {
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
          value: 'aktifkan',
          enabled: !item.isActive,
          child: Text(item.isActive
              ? 'Tahun Ajaran ini Sedang Aktif'
              : 'Aktifkan Tahun Ajaran ${item.tahun}'),
        ),
        const PopupMenuItem(
          value: 'detail',
          child: Text('Buka Lembar Detail SKM'),
        ),
      ],
    ).then((val) {
      if (val == 'aktifkan' && !item.isActive) {
        _setAsAktif(item);
      } else if (val == 'detail') {
        _showTahunAjaranDetail(context, item);
      }
    });
  }

  void _setAsAktif(TahunAjaranModel item) {
    setState(() {
      for (int i = 0; i < _daftarTahunAjaran.length; i++) {
        final curr = _daftarTahunAjaran[i];
        _daftarTahunAjaran[i] = TahunAjaranModel(
          id: curr.id,
          tahun: curr.tahun,
          semester: curr.semester,
          isActive: curr.id == item.id,
          skm: curr.skm,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Tahun ajaran ${item.tahun} (Semester ${item.semester}) sekarang AKTIF.'),
      ),
    );
  }

  void _hapusTahunAjaran(TahunAjaranModel item) {
    setState(() {
      _daftarTahunAjaran.removeWhere((ta) => ta.id == item.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tahun ajaran ${item.tahun} telah dihapus.')),
    );
  }

  void _showTahunAjaranDetail(BuildContext context, TahunAjaranModel item) {
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
                  'Tahun Ajaran ${item.tahun}',
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
            _buildDetailRow('Tahun Pelajaran', item.tahun),
            _buildDetailRow('Semester Aktif', 'Semester ${item.semester}'),
            _buildDetailRow('Standar Ketuntasan (SKM)', '${item.skm}'),
            _buildDetailRow(
                'Status', item.isActive ? 'Sedang Berjalan (Aktif)' : 'Arsip'),
            const SizedBox(height: 16),
            if (!item.isActive)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kBrand),
                onPressed: () {
                  _setAsAktif(item);
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Jadikan Tahun Ajaran Aktif'),
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

  /// Form Tambah Tahun Ajaran: Memuat [RadioButton] & [CheckBox]
  void _showAddTahunAjaranSheet(BuildContext context) {
    final tahunCtrl = TextEditingController();
    final skmCtrl = TextEditingController(text: '75');
    String selectedSemester = 'Ganjil';
    bool langsungAktifkan = false;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tambah Tahun Ajaran',
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
                controller: tahunCtrl,
                decoration: InputDecoration(
                  labelText: 'Tahun Ajaran',
                  hintText: 'Contoh: 2027/2028',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // [RadioButton]: Memilih Semester Ganjil atau Genap
              const Text(
                'Pilih Semester (RadioButton):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Ganjil', style: TextStyle(fontSize: 13)),
                      value: 'Ganjil',
                      groupValue: selectedSemester,
                      activeColor: kBrand,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedSemester = val);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Genap', style: TextStyle(fontSize: 13)),
                      value: 'Genap',
                      groupValue: selectedSemester,
                      activeColor: kBrand,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedSemester = val);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              TextField(
                controller: skmCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'SKM (Standar Ketuntasan)',
                  hintText: '75',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // [CheckBox]: Opsi mengaktifkan langsung
              CheckboxListTile(
                title: const Text(
                  'Langsung jadikan tahun ajaran aktif',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                value: langsungAktifkan,
                activeColor: kBrand,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) {
                  setModalState(() => langsungAktifkan = val ?? false);
                },
              ),

              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kBrand,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  if (tahunCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tahun ajaran wajib diisi.')),
                    );
                    return;
                  }
                  final newId =
                      DateTime.now().millisecondsSinceEpoch.toString();
                  setState(() {
                    if (langsungAktifkan) {
                      for (int i = 0; i < _daftarTahunAjaran.length; i++) {
                        final c = _daftarTahunAjaran[i];
                        _daftarTahunAjaran[i] = TahunAjaranModel(
                          id: c.id,
                          tahun: c.tahun,
                          semester: c.semester,
                          isActive: false,
                          skm: c.skm,
                        );
                      }
                    }
                    _daftarTahunAjaran.insert(
                      0,
                      TahunAjaranModel(
                        id: newId,
                        tahun: tahunCtrl.text.trim(),
                        semester: selectedSemester,
                        isActive: langsungAktifkan,
                        skm: int.tryParse(skmCtrl.text) ?? 75,
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Tahun ajaran ${tahunCtrl.text.trim()} berhasil ditambahkan.'),
                    ),
                  );
                },
                child: const Text('Simpan Tahun Ajaran',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

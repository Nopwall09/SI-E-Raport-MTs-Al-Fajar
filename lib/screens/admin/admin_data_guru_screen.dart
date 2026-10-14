import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/motion.dart';
import '../../features/admin/presentation/admin_providers.dart';
import '../../features/admin/presentation/admin_widgets.dart';
import '../../models/guru_model.dart';
import '../../models/user_model.dart';

class AdminDataGuruScreen extends ConsumerStatefulWidget {
  const AdminDataGuruScreen({
    super.key,
  });

  @override
  ConsumerState<AdminDataGuruScreen> createState() => _AdminDataGuruScreenState();
}

class _AdminDataGuruScreenState extends ConsumerState<AdminDataGuruScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<GuruModel> _daftarGuru = const [];

  List<GuruModel> get _filteredGuru {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _daftarGuru;
    return _daftarGuru.where((guru) {
      return guru.nama.toLowerCase().contains(query) ||
          guru.nip.toLowerCase().contains(query) ||
          guru.mapel.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lista = ref.watch(adminGuruProvider);
    _daftarGuru = lista.valueOrNull ?? const [];
    const brandColor = kBrand;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Data Guru',
          style: TextStyle(
            color: kText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: statusAsync(lista, () => ref.invalidate(adminGuruProvider)) ??
          SafeArea(
        child: Column(
          children: [
            // Search Input Container (Cari...)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: kField,
                  borderRadius: BorderRadius.circular(kRadiusControl),
                  border: Border.all(color: kBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari...',
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
            ),

            const Divider(height: 1),

            // Daftar Guru
            Expanded(
              child: _filteredGuru.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_outlined,
                              size: 48, color: kMuted),
                          const SizedBox(height: 8),
                          Text(
                            'Guru tidak ditemukan',
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
                        ref.invalidate(adminGuruProvider);
                        try {
                          await ref.read(adminGuruProvider.future);
                        } catch (_) {}
                      },
                      child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: _filteredGuru.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final guru = _filteredGuru[index];
                        return FadeSlideIn(
                          index: index,
                          child: PressScale(child: _buildGuruCard(guru, brandColor)),
                        );
                      },
                    ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGuruSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }

  Widget _buildGuruCard(GuruModel guru, Color brandColor) {
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
          onTap: () => _showGuruDetailSheet(context, guru, brandColor),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kBrand.withValues(alpha: 0.1),
                  child: Text(
                    guru.nama.isNotEmpty ? guru.nama[0] : 'G',
                    style: const TextStyle(
                      color: kBrand,
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
                        guru.nama,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'NIP ${guru.nip}\nMapel ${guru.mapel}',
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

  void _showGuruDetailSheet(
      BuildContext context, GuruModel guru, Color brandColor) {
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
                  'Detail Guru',
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
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: kBrand.withValues(alpha: 0.12),
                child: Text(
                  guru.nama[0],
                  style: const TextStyle(
                    color: kBrand,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              title: Text(
                guru.nama,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text('Guru Mapel: ${guru.mapel}'),
            ),
            const Divider(),
            _buildDetailRow('NIP', guru.nip),
            _buildDetailRow('Mata Pelajaran', guru.mapel),
            _buildDetailRow('Wali Kelas',
                guru.waliKelas != null ? 'Kelas ${guru.waliKelas}' : 'Bukan Wali Kelas'),
            _buildDetailRow('Email', guru.email),
            _buildDetailRow('Nomor Telepon', guru.telepon),
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
                    content: Text('Membuka jadwal mengajar ${guru.nama}...'),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: const Text('Lihat Jadwal Mengajar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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

  void _showAddGuruSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final nipCtrl = TextEditingController();
    final hpCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
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
                  'Tambah Guru Baru',
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
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap & Gelar',
                hintText: 'Contoh: Ust. Ahmad Fauzi, S.Pd.I',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nipCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'NIP / NUPTK',
                hintText: '18 digit nomor',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: hpCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'No. HP (opsional)',
                hintText: '08xxxxxxxxxx',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: userCtrl,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Username login',
                hintText: 'huruf kecil, mis. ahmad.fauzi',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password awal',
                hintText: 'minimal 8 karakter',
              ),
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
                if (nameCtrl.text.trim().isEmpty ||
                    userCtrl.text.trim().isEmpty ||
                    passCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama, username, dan password wajib diisi.'),
                    ),
                  );
                  return;
                }
                final nama = nameCtrl.text.trim();
                final ok = await simpan(
                  context,
                  () => ref.read(adminRepositoryProvider).buatAkun(
                        username: userCtrl.text.trim(),
                        password: passCtrl.text,
                        role: UserRole.guru,
                        nama: nama,
                        nip: nipCtrl.text,
                        noHp: hpCtrl.text,
                      ),
                  'Guru $nama berhasil ditambahkan.',
                );
                if (!ok) return;
                ref.invalidate(adminGuruProvider);
                ref.invalidate(adminPenggunaProvider);
                ref.invalidate(opsiGuruProvider);
                ref.invalidate(adminStatistikProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text(
                'Simpan Data Guru',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

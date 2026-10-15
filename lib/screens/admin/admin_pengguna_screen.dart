import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../widgets/motion.dart';
import '../../features/admin/presentation/admin_providers.dart';
import '../../features/admin/presentation/admin_widgets.dart';
import '../../models/user_model.dart';
import 'widgets/admin_menu_drawer.dart';

class AdminPenggunaScreen extends ConsumerStatefulWidget {
  const AdminPenggunaScreen({super.key});

  @override
  ConsumerState<AdminPenggunaScreen> createState() =>
      _AdminPenggunaScreenState();
}

class _AdminPenggunaScreenState extends ConsumerState<AdminPenggunaScreen> {
  final TextEditingController _searchController = TextEditingController();
  UserRole? _filterRole;

  List<UserModel> _users = const [];

  List<UserModel> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    return _users.where((user) {
      final matchesQuery =
          query.isEmpty ||
          user.nama.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
      final matchesRole = _filterRole == null || user.role == _filterRole;
      return matchesQuery && matchesRole;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lista = ref.watch(adminPenggunaProvider);
    _users = lista.valueOrNull ?? const [];
    const brandColor = kBrand;

    return Scaffold(
      drawer: const AdminMenuDrawer(currentRoute: '/admin/pengguna'),
      appBar: AppBar(
        title: const Text(
          'Pengguna',
          style: TextStyle(
            color: kText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          statusAsync(lista, () => ref.invalidate(adminPenggunaProvider)) ??
          SafeArea(
            child: Column(
              children: [
                // Search Bar & Filter Chips
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    children: [
                      // Search Input
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
                            hintText: 'Cari...',
                            hintStyle: TextStyle(color: kMuted, fontSize: 14),
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

                      // Role Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Semua', null, brandColor),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              'Admin',
                              UserRole.admin,
                              brandColor,
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip('Guru', UserRole.guru, brandColor),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              'Wali Murid',
                              UserRole.waliMurid,
                              brandColor,
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              'Siswa',
                              UserRole.siswa,
                              brandColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // User List
                Expanded(
                  child: _filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 48, color: kMuted),
                              const SizedBox(height: 8),
                              Text(
                                'Pengguna tidak ditemukan',
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
                            ref.invalidate(adminPenggunaProvider);
                            try {
                              await ref.read(adminPenggunaProvider.future);
                            } catch (_) {}
                          },
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                            itemCount: _filteredUsers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return FadeSlideIn(
                                index: index,
                                child: PressScale(child: _buildUserCard(user)),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }

  Widget _buildFilterChip(String label, UserRole? role, Color brandColor) {
    final isSelected = _filterRole == role;
    return InkWell(
      onTap: () => setState(() => _filterRole = role),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? brandColor : kField,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isSelected ? brandColor : kBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : kMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    Color badgeBg;
    Color badgeText;
    Color avatarBg;

    // Role dibedakan lewat label, bukan warna: satu aksen untuk seluruh app.
    badgeBg = kBrandSoft;
    badgeText = kBrand;
    avatarBg = kBrand;

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
          onTap: () => _showUserAksiSheet(user),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: avatarBg.withValues(alpha: 0.12),
                  child: Text(
                    user.nama.isNotEmpty ? user.nama[0] : 'U',
                    style: TextStyle(
                      color: avatarBg,
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
                        user.nama,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.aktif ? user.email : '${user.email} (nonaktif)',
                        style: TextStyle(fontSize: 12, color: kMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeText.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    user.role.label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: badgeText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUserAksiSheet(UserModel user) {
    final diriSendiri = ref.read(authControllerProvider).value?.id == user.id;
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
                Flexible(
                  child: Text(
                    user.nama,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Username: ${user.email}'),
            Text('Peran: ${user.role.label}'),
            Text('Status: ${user.aktif ? 'Aktif' : 'Nonaktif'}'),
            const SizedBox(height: 16),
            if (diriSendiri)
              Text(
                'Anda tidak bisa menonaktifkan akun yang sedang dipakai.',
                style: Theme.of(ctx).textTheme.bodySmall,
              )
            else
              FilledButton.icon(
                onPressed: () async {
                  final ok = await simpan(
                    context,
                    () => ref
                        .read(adminRepositoryProvider)
                        .setPenggunaAktif(user.id, !user.aktif),
                    user.aktif
                        ? 'Akun ${user.email} dinonaktifkan.'
                        : 'Akun ${user.email} diaktifkan.',
                  );
                  if (!ok) return;
                  ref.invalidate(adminPenggunaProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                icon: Icon(
                  user.aktif ? Icons.block : Icons.check_circle_outline,
                  size: 18,
                ),
                label: Text(user.aktif ? 'Nonaktifkan akun' : 'Aktifkan akun'),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddUserSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    UserRole selectedRole = UserRole.guru;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                    'Tambah Pengguna Baru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  hintText: 'Contoh: Ahmad Dahlan, S.Pd',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: userCtrl,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Username login',
                  hintText: 'huruf kecil, mis. ahmad.fauzi',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password awal',
                  hintText: 'minimal 8 karakter',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                initialValue: selectedRole,
                decoration: InputDecoration(labelText: 'Role'),
                items: UserRole.values.where((r) => r != UserRole.siswa).map((
                  role,
                ) {
                  return DropdownMenuItem(value: role, child: Text(role.label));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => selectedRole = val);
                  }
                },
              ),
              const SizedBox(height: 20),
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
                  final perluNama = selectedRole != UserRole.admin;
                  if (userCtrl.text.trim().isEmpty ||
                      passCtrl.text.isEmpty ||
                      (perluNama && nama.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Harap lengkapi semua data.'),
                      ),
                    );
                    return;
                  }
                  final ok = await simpan(
                    context,
                    () => ref
                        .read(adminRepositoryProvider)
                        .buatAkun(
                          username: userCtrl.text.trim(),
                          password: passCtrl.text,
                          role: selectedRole,
                          nama: nama,
                        ),
                    'Pengguna ${userCtrl.text.trim()} berhasil ditambahkan.',
                  );
                  if (!ok) return;
                  ref.invalidate(adminPenggunaProvider);
                  ref.invalidate(adminGuruProvider);
                  ref.invalidate(opsiGuruProvider);
                  ref.invalidate(opsiWaliMuridProvider);
                  ref.invalidate(adminStatistikProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text(
                  'Simpan Pengguna',
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

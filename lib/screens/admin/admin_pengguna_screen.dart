import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/admin/presentation/admin_providers.dart';
import '../../features/admin/presentation/admin_widgets.dart';
import '../../models/user_model.dart';

class AdminPenggunaScreen extends ConsumerStatefulWidget {
  const AdminPenggunaScreen({
    super.key,
  });

  @override
  ConsumerState<AdminPenggunaScreen> createState() => _AdminPenggunaScreenState();
}

class _AdminPenggunaScreenState extends ConsumerState<AdminPenggunaScreen> {
  final TextEditingController _searchController = TextEditingController();
  UserRole? _filterRole;

  List<UserModel> _users = const [];

  List<UserModel> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    return _users.where((user) {
      final matchesQuery = query.isEmpty ||
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
    const brandColor = Color(0xFF0D5C3A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 1,
        title: const Text(
          'Pengguna',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: statusAsync(lista, () => ref.invalidate(adminPenggunaProvider)) ??
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
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
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
                        _buildFilterChip('Admin', UserRole.admin, brandColor),
                        const SizedBox(width: 6),
                        _buildFilterChip('Guru', UserRole.guru, brandColor),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                            'Wali Murid', UserRole.waliMurid, brandColor),
                        const SizedBox(width: 6),
                        _buildFilterChip('Siswa', UserRole.siswa, brandColor),
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
                          Icon(Icons.search_off,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Pengguna tidak ditemukan',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredUsers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return _buildUserCard(user);
                      },
                    ),
            ),
          ],
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
        onPressed: () => _showAddUserSheet(context),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildFilterChip(String label, UserRole? role, Color brandColor) {
    final isSelected = _filterRole == role;
    return InkWell(
      onTap: () => setState(() => _filterRole = role),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? brandColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? brandColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    Color badgeBg;
    Color badgeText;
    Color avatarBg;

    switch (user.role) {
      case UserRole.admin:
        badgeBg = const Color(0xFFE0E7FF);
        badgeText = const Color(0xFF3730A3);
        avatarBg = const Color(0xFF4F46E5);
        break;
      case UserRole.guru:
        badgeBg = const Color(0xFFDCFCE7);
        badgeText = const Color(0xFF166534);
        avatarBg = const Color(0xFF16A34A);
        break;
      case UserRole.waliMurid:
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFF92400E);
        avatarBg = const Color(0xFFD97706);
        break;
      case UserRole.siswa:
        badgeBg = const Color(0xFFF1F5F9);
        badgeText = const Color(0xFF475569);
        avatarBg = const Color(0xFF64748B);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarBg.withOpacity(0.12),
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
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeText.withOpacity(0.3)),
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
                    'Tambah Pengguna Baru',
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
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  hintText: 'Contoh: Ahmad Dahlan, S.Pd',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: userCtrl,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Username login',
                  hintText: 'huruf kecil, mis. ahmad.fauzi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password awal',
                  hintText: 'minimal 8 karakter',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: UserRole.values.where((r) => r != UserRole.siswa).map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.label),
                  );
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
                  backgroundColor: const Color(0xFF0D5C3A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
                    () => ref.read(adminRepositoryProvider).buatAkun(
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

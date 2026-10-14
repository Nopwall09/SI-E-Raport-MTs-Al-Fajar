import 'package:flutter/material.dart';
import 'wali/wali_rapor_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_pengguna_screen.dart';
import 'admin/admin_data_siswa_screen.dart';
import 'admin/admin_data_guru_screen.dart';
import 'admin/admin_data_kelas_screen.dart';

enum AppViewMode {
  waliRapor,
  adminDashboard,
  adminDataSiswa,
  adminDataGuru,
  adminDataKelas,
  adminPengguna,
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AppViewMode _currentView = AppViewMode.waliRapor;

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF0D5C3A);

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Drawer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: brandColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'SI e-Raport',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'MTs Al-Fajar',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Wireframe 1
              _buildDrawerItem(
                icon: Icons.family_restroom,
                title: 'e-Rapor Orang Tua',
                subtitle: 'Wireframe: Wali',
                isSelected: _currentView == AppViewMode.waliRapor,
                onTap: () {
                  setState(() => _currentView = AppViewMode.waliRapor);
                  Navigator.pop(context);
                },
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Divider(height: 1),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'PANEL ADMIN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.0,
                  ),
                ),
              ),

              // Wireframe 2
              _buildDrawerItem(
                icon: Icons.dashboard_outlined,
                title: 'Dashboard Admin',
                subtitle: 'Wireframe: Admin',
                isSelected: _currentView == AppViewMode.adminDashboard,
                onTap: () {
                  setState(() => _currentView = AppViewMode.adminDashboard);
                  Navigator.pop(context);
                },
              ),

              // Wireframe: Data Siswa
              _buildDrawerItem(
                icon: Icons.badge_outlined,
                title: 'Data Siswa',
                subtitle: 'Wireframe: Admin - Data Siswa',
                isSelected: _currentView == AppViewMode.adminDataSiswa,
                onTap: () {
                  setState(() => _currentView = AppViewMode.adminDataSiswa);
                  Navigator.pop(context);
                },
              ),

              // Wireframe: Data Guru
              _buildDrawerItem(
                icon: Icons.person_search_outlined,
                title: 'Data Guru',
                subtitle: 'Wireframe: Admin - Data Guru',
                isSelected: _currentView == AppViewMode.adminDataGuru,
                onTap: () {
                  setState(() => _currentView = AppViewMode.adminDataGuru);
                  Navigator.pop(context);
                },
              ),

              // Wireframe: Data Kelas
              _buildDrawerItem(
                icon: Icons.meeting_room_outlined,
                title: 'Data Kelas',
                subtitle: 'Wireframe: Admin - Data Kelas',
                isSelected: _currentView == AppViewMode.adminDataKelas,
                onTap: () {
                  setState(() => _currentView = AppViewMode.adminDataKelas);
                  Navigator.pop(context);
                },
              ),

              // Wireframe 3
              _buildDrawerItem(
                icon: Icons.people_outline,
                title: 'Pengguna',
                subtitle: 'Wireframe: Admin - Pengguna',
                isSelected: _currentView == AppViewMode.adminPengguna,
                onTap: () {
                  setState(() => _currentView = AppViewMode.adminPengguna);
                  Navigator.pop(context);
                },
              ),

              const Spacer(),

              // Quick Switch Helper
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Simulasi Peran Wireframe',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pilih menu di atas untuk meninjau halaman sesuai wireframe yang diberikan.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildCurrentBody(),
    );
  }

  Widget _buildCurrentBody() {
    switch (_currentView) {
      case AppViewMode.waliRapor:
        return WaliRaporScreen(
          onLogout: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        );
      case AppViewMode.adminDashboard:
        return AdminDashboardScreen(
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        );
      case AppViewMode.adminDataSiswa:
        return AdminDataSiswaScreen(
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        );
      case AppViewMode.adminDataGuru:
        return AdminDataGuruScreen(
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        );
      case AppViewMode.adminDataKelas:
        return AdminDataKelasScreen(
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        );
      case AppViewMode.adminPengguna:
        return AdminPenggunaScreen(
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        );
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const brandColor = Color(0xFF0D5C3A);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? brandColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? brandColor : Colors.grey.shade700,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? brandColor : const Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade500,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.arrow_forward_ios, size: 13, color: brandColor)
          : null,
      onTap: onTap,
    );
  }
}

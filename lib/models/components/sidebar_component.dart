import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Tambahkan package intl di pubspec.yaml jika ingin format tanggal otomatis

// Sesuaikan import di bawah dengan path aslimu
// import 'package:identra_mobile_flutter/leave_request_sheet.dart';
// import 'package:identra_mobile_flutter/models/attendance_model.dart';
// import 'package:identra_mobile_flutter/qr_scanner.dart';
// import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static const Color cardBg = Color(0xFF1F222E);
  static const Color sidebarBg = Color(0xFF161821);
  static const Color primaryBlue = Color(0xFF4E6AF3);
  static const Color activeMenuBg = Color(0xFF262A40);

  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFF8E92A8);

  static const Color orangeBg = Color(0xFF3E2B25);
  static const Color orangeIcon = Color(0xFFFF9500);

  static const Color blueBg = Color(0xFF22314F);
  static const Color blueIcon = Color(0xFF4E6AF3);

  static const Color purpleBg = Color(0xFF2B2245);
  static const Color purpleIcon = Color(0xFF9747FF);

  static const Color redBg = Color(0xFF382229);
  static const Color redBadge = Color(0xFFFF3B30);
}

class SidebarOverlay extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String selectedItem;

  // Data Profil
  final String userName;
  final String jabatan;
  final String initials;
  final Color themeColor;

  const SidebarOverlay({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.selectedItem,
    required this.userName,
    required this.jabatan,
    required this.initials,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    String todayDate =
        DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(DateTime.now());

    return Stack(
      children: [
        if (isOpen)
          GestureDetector(
            onTap: onClose,
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: isOpen ? 0 : -320,
          top: 0,
          bottom: 0,
          child: Material(
            color: AppColors.sidebarBg,
            child: SizedBox(
              width: 300,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- PROFILE HEADER CARD ---
                    Container(
                      margin: const EdgeInsets.only(
                          top: 20, left: 16, right: 16, bottom: 12),
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2972FE), Color(0xFF649BFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2972FE).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // --- Image Banner sebagai Background yang pas ---
                            Positioned(
                              top: 0,
                              bottom: 0,
                              right: 0,
                              child: Image.asset(
                                'assets/images/sidebar_banner.png',
                                width:
                                    160, // Sesuaikan lebar agar tidak menutupi teks sebelah kiri
                                fit: BoxFit
                                    .cover, // Ini kuncinya agar gambar memenuhi tinggi kontainer
                                alignment: Alignment
                                    .centerRight, // Fokus ke sisi kanan gambar
                              ),
                            ),

                            // --- Layer Gradient Overlay (Opsional: biar teks lebih kebaca jika gambar terlalu terang) ---
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF2972FE),
                                      const Color(0xFF2972FE).withOpacity(
                                          0.0), // Fade ke transparan
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    stops: const [
                                      0.4,
                                      0.9
                                    ], // Atur di mana warna solid mulai hilang
                                  ),
                                ),
                              ),
                            ),

                            // --- Konten Profil (Teks & Avatar) ---
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.person,
                                        color: const Color(0xFF2972FE),
                                        size: 30),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          userName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          jabatan,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- STATUS & TANGGAL ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1CC974),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Online • $todayDate",
                            style: GoogleFonts.poppins(
                              color: AppColors.textGrey,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- MENU ITEMS ---
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _SidebarMenuItem(
                            icon: Icons.grid_view_rounded,
                            title: "Dashboard",
                            isActive: selectedItem == "Dashboard",
                            onTap: () {
                              onClose(); // Tutup sidebar dulu
                              Navigator.pushReplacementNamed(
                                  context, '/dashboard'); // Contoh Named Route
                            },
                          ),
                          _SidebarMenuItem(
                            icon: Icons.bar_chart_rounded,
                            title: "Stats Kehadiran",
                            isActive: selectedItem == "Stats Kehadiran",
                            onTap: () {
                              onClose(); // Tutup sidebar dulu
                              Navigator.pushReplacementNamed(context,
                                  '/stats-keseluruhan'); // Contoh Named Route
                            },
                          ),
                          _SidebarMenuItem(
                            icon: Icons.pie_chart_rounded,
                            title: "Stats Penilaian",
                            isActive: selectedItem == "Stats Penilaian",
                            onTap: () {
                              onClose(); // Tutup sidebar dulu
                              Navigator.pushReplacementNamed(context,
                                  '/stats-penilaian'); // Contoh Named Route
                            },
                          ),
                          _SidebarMenuItem(
                            icon: Icons.scatter_plot_sharp,
                            title: "Poin dan Reward",
                            isActive: selectedItem == "Poin dan Reward",
                            onTap: () {
                              onClose(); // Tutup sidebar dulu
                              Navigator.pushReplacementNamed(context,
                                  '/poin-dan-reward'); // Contoh Named Route
                            },
                          ),
                          _SidebarMenuItem(
                            icon: Icons.person_outline_rounded,
                            title: "Profil Saya",
                            isActive: selectedItem == "Profil Saya",
                            onTap: () => onClose(),
                          ),
                          _SidebarMenuItem(
                            icon: Icons.notifications_none_rounded,
                            title: "Notifikasi",
                            badgeCount: "20",
                            isActive: selectedItem == "Notifikasi",
                            onTap: () => onClose(),
                          ),
                          _SidebarMenuItem(
                            icon: Icons.settings_outlined,
                            title: "Pengaturan",
                            isActive: selectedItem == "Pengaturan",
                            onTap: () => onClose(),
                          ),
                        ],
                      ),
                    ),

                    // --- LOGOUT BUTTON ---
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Tambahkan logic logout
                        },
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white, size: 20),
                        label: Text(
                          "Keluar",
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          side: BorderSide(
                              color: AppColors.redBadge.withOpacity(0.5)),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SidebarMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final String? badgeCount;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.icon,
    required this.title,
    this.isActive = false,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final contentColor = isActive ? AppColors.primaryBlue : Colors.white70;
    final bgColor = isActive ? AppColors.activeMenuBg : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: contentColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: contentColor,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (badgeCount != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.redBadge,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeCount!,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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
}

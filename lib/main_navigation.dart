import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:identra_mobile_flutter/home.dart';
import 'package:identra_mobile_flutter/login_page.dart';
import 'package:identra_mobile_flutter/profile.dart';
import 'package:identra_mobile_flutter/qr_scanner.dart';
import 'package:identra_mobile_flutter/stats.dart';
import 'dart:ui';

class AppColors {
  static const Color cardBg = Color(0xFF1F222E);
  static const Color primaryBlue = Color(0xFF4E6AF3);
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFF8E92A8);

  static const Color orangeBg = Color(0xFF3E2B25);
  static const Color orangeIcon = Color(0xFFFF9500);
  static const Color blueBg = Color(0xFF22314F);
  static const Color blueIcon = Color(0xFF4E6AF3);
  static const Color purpleBg = Color(0xFF2B2245);
  static const Color purpleIcon = Color(0xFF9747FF);
  static const Color redBg = Color(0xFF382229);
  static const Color redIcon = Color(0xFFFF3B30);
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late PageController _pageController;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          // LAYER 1: Konten Utama
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _selectedIndex = index),
              children: [
                HomeScreen(key: _homeKey),
                Center(
                    child: Text("Halaman Izin",
                        style: TextStyle(color: Colors.white))),
                Center(
                    child: Text("Halaman Scan",
                        style: TextStyle(color: Colors.white))),
                StatsScreen(),
                ProfilePage(),
              ],
            ),
          ),

          // LAYER 2: Navigasi Melayang
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 100, // Ketinggian total container navbar
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // A. BODY NAVBAR (LIQUID GLASS + CURVE IN)
          ClipPath(
            clipper: NavPainter(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 75, // Tinggi batang navbar
                decoration: BoxDecoration(
                  color: const Color(0xFF1F222E).withOpacity(0.6),
                ),
              ),
            ),
          ),

          // B. BORDER MENGIKUTI CURVE
          CustomPaint(
            size: const Size(double.infinity, 75),
            painter: NavBorderPainter(),
          ),

          // C. ITEM MENU
          Container(
            height: 75,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, "Home"),
                _navItem(1, Icons.folder_rounded, "Izin"),
                const SizedBox(width: 70), // Ruang untuk Curve In
                _navItem(3, Icons.bar_chart_rounded, "Stats"),
                _navItem(4, Icons.person_rounded, "Profile"),
              ],
            ),
          ),

          // D. TOMBOL SCAN (Melayang sedikit di atas Curve In)
          Positioned(
            bottom: 25, // Posisi tombol agar proporsional dengan lengkungan
            child: GestureDetector(
              onTap: () async {
                // 1. Tambahkan async di sini
                // 2. Gunakan await untuk menunggu hasil dari halaman scanner
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRScannerPage(),
                  ),
                );

                // 3. Jika result adalah true (dikirim dari Navigator.pop(context, true) di dialog sukses)
                if (result == true) {
                  _homeKey.currentState?.handleRefresh();
                }
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        _pageController.jumpToPage(index);
        setState(() => _selectedIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: isActive ? Colors.white : AppColors.textGrey, size: 24),
          Text(label,
              style: GoogleFonts.poppins(
                  color: isActive ? Colors.white : AppColors.textGrey,
                  fontSize: 10)),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 3,
            width: isActive ? 18 : 0,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                if (isActive)
                  BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.6),
                      blurRadius: 6)
              ],
            ),
          )
        ],
      ),
    );
  }
}

// CLIPPER: Menggambar lengkungan ke DALAM (Concave)
class NavPainter extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double w = size.width;
    double h = size.height;
    double r = 25; // Corner radius

    path.moveTo(r, 0);

    // LENGKUNGAN KE DALAM (SMOOTH CURVE IN)
    // Titik awal masuk curve
    path.lineTo(w * 0.32, 0);
    // Bezier kurva ke bawah (ke dalam bodi)
    path.cubicTo(
      w * 0.40, 0, // Control point 1
      w * 0.42, 35, // Control point 2 (kedalaman curve)
      w * 0.50, 35, // Titik puncak terdalam
    );
    path.cubicTo(
      w * 0.58, 35, // Control point 3
      w * 0.60, 0, // Control point 4
      w * 0.68, 0, // Titik keluar curve
    );

    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);
    path.lineTo(w, h - r);
    path.quadraticBezierTo(w, h, w - r, h);
    path.lineTo(r, h);
    path.quadraticBezierTo(0, h, 0, h - r);
    path.lineTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class NavBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(NavPainter().getClip(size), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:identra_mobile_flutter/home.dart';
import 'package:identra_mobile_flutter/stats.dart';
import 'dart:ui';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class AppColors {
  // Warna Utama (Transparan karena kita pakai Background Image)
  static const Color cardBg = Color(0xFF1F222E);
  static const Color primaryBlue = Color(0xFF4E6AF3);
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFF8E92A8);

  // Warna Kategori Stats (Background Icon & Icon Color)
  static const Color orangeBg = Color(0xFF3E2B25);
  static const Color orangeIcon = Color(0xFFFF9500);

  static const Color blueBg = Color(0xFF22314F);
  static const Color blueIcon = Color(0xFF4E6AF3);

  static const Color purpleBg = Color(0xFF2B2245);
  static const Color purpleIcon = Color(0xFF9747FF);

  static const Color redBg = Color(0xFF382229);
  static const Color redIcon = Color(0xFFFF3B30);
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  // 1. Tambahkan PageController
  late PageController _pageController;

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

      // 2. ExtendBody agar body PageView memanjang sampai ke bawah layar (di belakang navbar)
      extendBody: true,

      // 3. ExtendBodyBehindAppBar jika kamu pakai AppBar di page lain
      extendBodyBehindAppBar: true,

      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [
          HomeScreen(),
          StatsScreen(),
          Center(
              child:
                  Text("Profile Page", style: TextStyle(color: Colors.white))),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          20, 5, 20, 25), // Padding bawah ditambah sedikit
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          // Sigma dinaikkan sedikit untuk efek frosted glass yang lebih premium
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 80, // Sedikit lebih ramping biar elegan
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(35),
              // Gunakan LinearGradient alih-alih warna solid agar efek kaca lebih realistis
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white
                      .withOpacity(0.15), // Pantulan cahaya di atas kiri
                  Colors.white
                      .withOpacity(0.05), // Lebih transparan di bawah kanan
                ],
              ),
              // Border dibuat sedikit lebih terang sebagai "edge highlight" kaca
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              // Shadow tipis untuk memberikan dimensi (depth)
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, "Home"),
                _navItem(1, Icons.bar_chart_rounded, "Stats"),
                _navItem(2, Icons.person_rounded, "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        // 3. Animasi saat tombol ditekan
        // Ganti bagian yang error tadi dengan ini:
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 500),
          curve:
              Curves.easeInOutQuart, // Ini kurva yang sangat halus untuk slide
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn, // Kurva animasi Google-style
        padding:
            EdgeInsets.symmetric(horizontal: isActive ? 20 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : AppColors.textGrey,
              size: 26,
            ),
            // Animasi Text Muncul (Fade & Slide)
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: isActive
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

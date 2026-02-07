import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const AbsensiApp());
}

// --- KONFIGURASI WARNA ---
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

class AbsensiApp extends StatelessWidget {
  const AbsensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Absensi App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black, // Fallback color
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = "Loading...";
  String _jabatanAktif = "Belum Ditugaskan";

  Color _getAvatarColor(String name) {
    final List<Color> colors = [
      Colors.amber,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
    ];

    // Logika sederhana: ambil warna berdasarkan panjang karakter nama
    // supaya warnanya tetap/konsisten untuk user tersebut.
    return colors[name.length % colors.length];
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "G";
    List<String> names = name.split(" ");
    String initials = "";

    // Ambil huruf pertama dari maksimal 2 kata pertama
    int numWords = names.length > 2 ? 2 : names.length;
    for (var i = 0; i < numWords; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0].toUpperCase();
      }
    }
    return initials;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    print("USER NAME: ${prefs.getString('user_name')}");
    print("JABATAN AKTIF: ${prefs.getString('jabatan_aktif')}");

    setState(() {
      _userName = prefs.getString('user_name') ?? "Guru";
      _jabatanAktif = prefs.getString('jabatan_aktif') ?? "Belum Ditugaskan";
    });
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = _getAvatarColor(_userName);
    return Scaffold(
      // Background Scaffold dibuat transparan agar Container di bawahnya terlihat
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // --- 1. SETTING BACKGROUND PAGE UTAMA (IMAGE) ---
        decoration: const BoxDecoration(
          image: DecorationImage(
            // Pastikan file 'bg_main.png' ada di assets
            image: AssetImage('assets/images/bg_main.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Bagian Scrollable (Header sampai Stats)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildHeader(themeColor),
                      const SizedBox(height: 28),

                      // Greeting Card Section
                      _buildGreetingCard(),
                      const SizedBox(height: 16),

                      // Attendance Status (Masuk/Pulang)
                      _buildAttendanceRow(),
                      const SizedBox(height: 28),

                      // Stats Section
                      const Text(
                        "Your Stats",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildStatsGrid(),

                      const SizedBox(height: 24),

                      // Leave Request Section
                      _buildLeaveRequestBanner(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET: HEADER ---
  Widget _buildHeader(Color themeColor) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeColor.withOpacity(0.15), // Sekarang dia kenal!
            border: Border.all(color: themeColor.withOpacity(0.5), width: 2),
          ),
          child: Center(
            child: Text(
              _getInitials(_userName),
              style: GoogleFonts.poppins(
                color: themeColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ), // <
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _userName,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffffffff)),
            ),
            Text(
              _jabatanAktif.isNotEmpty ? _jabatanAktif : "Belum Ditugaskan",
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Notification Button
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg.withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: AppColors.primaryBlue),
            onPressed: () {},
          ),
        )
      ],
    );
  }

  // --- WIDGET: GREETING CARD (BG IMAGE) ---
  Widget _buildGreetingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      // Setting Background Card pakai Gambar
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/images/bg_greeting.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Text Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Halo, Selamat Pagi!",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                "19 Jan 2025",
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.8)),
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Bagus, anda tepat waktu.",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET: JAM MASUK / PULANG ---
  Widget _buildAttendanceRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBg
            .withOpacity(0.6), // Semi transparan agar bg page terlihat dikit
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Bagian Masuk
          Expanded(
            child: Column(
              children: [
                const Text("MASUK",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A2B), // Hijau Gelap
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text("06.28",
                      style: TextStyle(
                          color: Color(0xFF4CD964),
                          fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          // Divider Vertical
          Container(height: 40, width: 1, color: Colors.white10),
          // Bagian Pulang
          Expanded(
            child: Column(
              children: [
                const Text("PULANG",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C), // Abu Gelap
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text("16.00",
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: STATS GRID ---
  Widget _buildStatsGrid() {
    // Helper function untuk membuat 1 kotak stat
    Widget statItem(
        String title, String count, Color baseColor, IconData icon) {
      return Container(
        decoration: BoxDecoration(
          // Card menggunakan warna kategori dengan opacity rendah (0.1 - 0.2)
          color: baseColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: baseColor.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Wrapper Icon dengan warna solid
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: baseColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]),
              // Icon dibuat warna putih sesuai request
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(count,
                      style: TextStyle(
                        fontSize: 11,
                        // Warna teks sedikit mengikuti warna base agar harmonis
                        color: Colors.white.withOpacity(0.7),
                      )),
                ],
              ),
            )
          ],
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.1,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        // Kita cukup masukkan warna utamanya saja (Icon Color), logic opacity ada di atas
        statItem("Terlambat", "0 Hari", AppColors.orangeIcon,
            Icons.access_time_filled),
        statItem("Izin", "2 Hari", AppColors.blueIcon, Icons.description),
        statItem(
            "Sakit", "0 Hari", AppColors.purpleIcon, Icons.medical_services),
        statItem("Tanpa Ket", "0 Hari", AppColors.redIcon, Icons.cancel),
      ],
    );
  }

  // --- WIDGET: LEAVE REQUEST ---
  Widget _buildLeaveRequestBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22), // Warna dasar gelap
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.3)), // Border Biru tipis
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Leave Request",
              style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            "Berhalangan hadir? Ajukan izin dengan klik disini lalu lengkapi alasan dan tanggal ketidakhadiran Anda.",
            style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

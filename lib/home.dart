import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:identra_mobile_flutter/models/attendance_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  String _guruId = "";
  String _jamMasuk = "--:--";
  String _jamPulang = "--:--";
  bool _isLoading = false;

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);

    // Menjalankan kedua fungsi secara bersamaan
    await Future.wait([
      _loadUserData(),
      fetchAttendanceToday(),
    ]);

    // Beri sedikit delay agar user sempat melihat state loading (opsional)
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

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
    _initData();
  }

  Future<void> _initData() async {
    await _loadUserData();
    await fetchAttendanceToday();
  }

  AttendanceModel? _todayAttendance;

  Future<void> _loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // --- TAMBAHKAN LOG INI ---
    print("JABATAN_DARI_PREFS: ${prefs.getString('jabatan_aktif')}");

    setState(() {
      _userName = prefs.getString('user_name') ?? "Guru";

      // Perbaikan logika di sini
      String? storedJabatan = prefs.getString('jabatan_aktif');
      _jabatanAktif = (storedJabatan != null && storedJabatan.isNotEmpty)
          ? storedJabatan
          : "Guru Tetap";

      _guruId = prefs.getString('guru_id') ?? "";
      _jamMasuk = prefs.getString('jam_masuk') ?? "--:--";
      _jamPulang = prefs.getString('jam_pulang') ?? "--:--";
    });
  }

  Future<void> fetchAttendanceToday() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    final String? guruId = prefs.getString('guru_id');

    if (token == null || guruId == null) return;

    try {
      // SESUAIKAN: Path parameter /{guru_id} bukan ?guru_id=
      final String url =
          "https://spinningly-proscientific-renay.ngrok-free.dev/api/attendance/today/$guruId";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          // WAJIB: Agar Ngrok tidak mengirim halaman "Browser Warning"
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print("DEBUG: Fetching to $url");
      print("DEBUG: Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];

          setState(() {
            // Ambil jam_masuk dan jam_pulang dari JSON
            _jamMasuk = data['jam_masuk'] ?? "--:--";
            _jamPulang = data['jam_pulang'] ?? "--:--";
          });
        }
      } else {
        print("DEBUG: Server Error ${response.statusCode}");
      }
    } catch (e) {
      print("DEBUG: Connection Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = _getAvatarColor(_userName);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_main.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          // --- BUNGKUS DENGAN REFRESH INDICATOR ---
          child: RefreshIndicator(
            onRefresh: _handleRefresh, // Fungsi yang dipanggil saat ditarik
            color: Colors.blue, // Warna spinner
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    // physics wajib AlwaysScrollable agar bisa di-refresh meski konten pendek
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(themeColor),
                        const SizedBox(height: 28),

                        // Greeting Card vs Skeleton
                        _isLoading
                            ? _buildFlatSkeleton(
                                width: double.infinity, height: 160, radius: 24)
                            : _buildGreetingCard(),

                        const SizedBox(height: 16),

                        // Attendance Row vs Skeleton
                        _isLoading
                            ? _buildFlatSkeleton(
                                width: double.infinity, height: 100, radius: 20)
                            : _buildAttendanceRow(),

                        const SizedBox(height: 28),
                        _isLoading
                            ? _buildFlatSkeleton(
                                width: 150,
                                height: 20,
                                radius: 4) // Skeleton untuk judul teks
                            : const Text(
                                "Weekly Stats",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .white // Pastikan warna teks terlihat di dark mode
                                    ),
                              ),
                        const SizedBox(height: 16),

                        // Stats Grid vs Skeleton
                        _isLoading
                            ? _buildStatsGridSkeleton() // Buat helper khusus grid skeleton jika perlu
                            : _buildStatsGrid(),

                        const SizedBox(height: 24),
                        _buildLeaveRequestBanner(),
                      ],
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
    // Ambil waktu saat ini
    final now = DateTime.now();
    final hour = now.hour;

    // 1. Logika Salam (Greeting)
    String greeting = "Selamat Malam";
    if (hour >= 5 && hour < 11) {
      greeting = "Selamat Pagi";
    } else if (hour >= 11 && hour < 15) {
      greeting = "Selamat Siang";
    } else if (hour >= 15 && hour < 18) {
      greeting = "Selamat Sore";
    }

    // 2. Logika Tanggal Manual (Tanpa package intl)
    List months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    String formattedDate = "${now.day} ${months[now.month - 1]} ${now.year}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/images/bg_greeting.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Halo, $greeting!", // Salam Dinamis
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white // Pastikan warna kontras dengan BG
                ),
          ),
          const SizedBox(height: 4),
          Text(
            formattedDate, // Tanggal Dinamis
            style:
                TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Bagus, anda tepat waktu.",
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatSkeleton(
      {required double width, required double height, double radius = 16}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08), // Warna flat abu-abu transparan
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildStatsGridSkeleton() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.1,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: List.generate(
          4, (index) => _buildFlatSkeleton(width: double.infinity, height: 80)),
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
                    // Logika warna: jika belum absen, pakai abu-abu, jika sudah pakai hijau
                    color: _jamMasuk == "--:--"
                        ? Colors.white10
                        : const Color(0xFF1E3A2B),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _jamMasuk, // Variabel dinamis
                    style: TextStyle(
                        color: _jamMasuk == "--:--"
                            ? Colors.grey
                            : const Color(0xFF4CD964),
                        fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
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
                    color: _jamPulang == "--:--"
                        ? Colors.white10
                        : const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _jamPulang, // Variabel dinamis
                    style: TextStyle(
                        color: _jamPulang == "--:--"
                            ? Colors.grey
                            : Colors.blueAccent,
                        fontWeight: FontWeight.bold),
                  ),
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

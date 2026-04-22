import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:identra_mobile_flutter/face_auth_page.dart';
import 'package:identra_mobile_flutter/leave_request_sheet.dart';
import 'package:identra_mobile_flutter/models/attendance_model.dart';
import 'package:identra_mobile_flutter/models/components/sidebar_component.dart';
import 'package:identra_mobile_flutter/models/point_model.dart';
import 'package:identra_mobile_flutter/qr_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AbsensiApp());
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()
      ..color = AppColors.primaryBlue.withOpacity(0.3)
      ..strokeWidth = 2;

    // Ambil titik tengah secara horizontal
    double centerX = size.width / 2;

    while (startY < size.height) {
      // Gambar garis tepat di sumbu X tengah
      canvas.drawLine(
          Offset(centerX, startY), Offset(centerX, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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
  State<HomeScreen> createState() => HomeScreenState();
}

List<dynamic> attendedSchedules = [];

class HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<dynamic> _vouchers = [];
  // Statistik Mingguan
  String _statusAbsensi = "Hadir"; // Defaultnya Hadir
  bool hasAppliedToday = false; // Default: belum mengajukan
  String leaveMessage =
      "Ajukan izin dengan cepat melalui form digital di sini.";
  String _userName = "Loading...";
  String _jabatanAktif = "Belum Ditugaskan";
  String _guruId = "";
  String _jamMasuk = "--:--";
  String _jamPulang = "--:--";
  bool _isLoading = false;
  bool _isSidebarOpen = false;
  bool _isMainCheckedIn = false;
  final String baseUrl =
      "https://spinningly-proscientific-renay.ngrok-free.dev/api";

  int userPoints = 0;
  String currentRank = "Guru Muda";

  String? token;

  List<dynamic> _schedules = [];

  // Update fungsi _showLeaveRequestForm di HomeScreen
  void _showLeaveRequestForm(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const LeaveRequestSheet(),
    );

    if (result == true) {
      // 1. Simpan tanggal hari ini ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String todayStr =
          DateTime.now().toString().substring(0, 10); // Format: 2024-05-20
      await prefs.setString('last_submit_date', todayStr);

      // 2. Update UI seketika
      setState(() {
        hasAppliedToday = true;
      });

      // 3. Tarik data terbaru (opsional)
      fetchAttendanceToday();
    }
  }

  Future<void> _fetchVouchers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    // Sesuaikan URL ini dengan endpoint API Inventory/Voucher kamu
    final url = Uri.parse(
        'https://spinningly-proscientific-renay.ngrok-free.dev/api/my-tokens');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() {
          // Mengambil array dari key 'data' sesuai struktur JSON yang kamu kirim tadi
          _vouchers = responseData['data'] ?? [];
        });
        print("Voucher dimuat: ${_vouchers.length} item");
      } else {
        print("Gagal ambil voucher: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetch voucher: $e");
    }
  }

  

  Future<void> fetchSchedules() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    final String? guruId = prefs.getString('guru_id');

    if (guruId == null || guruId.isEmpty) {
      print("DEBUG: Guru ID kosong, gagal fetch schedule.");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            "https://spinningly-proscientific-renay.ngrok-free.dev/api/schedules/today/$guruId"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Connection': 'Keep-Alive', // Tambahkan ini untuk menjaga koneksi
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(
          const Duration(seconds: 10)); // Tambahkan timeout agar tidak hang

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _schedules = data['data'] ?? [];
          });
        }
      } else {
        print("DEBUG: Server Error ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetch schedule: $e");
      // Jika error, coba panggil lagi sekali (Recursive call) setelah 1 detik
      // Future.delayed(const Duration(seconds: 1), () => fetchSchedules());
    }
  }

  Future<void> handleRefresh() async {
    setState(() => _isLoading = true);

    // Menjalankan kedua fungsi secara bersamaan
    await Future.wait([
      _loadUserData(),
      fetchAttendanceToday(),
      fetchSchedules(),
      _fetchUserPoints(),
      _fetchVouchers()
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
    print("Daftar Voucher: $_vouchers");
  }

  Future<void> _fetchUserPoints() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/profile/summary"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // DEBUG: Cek di console apakah datanya benar-benar masuk
        print("API Response: ${response.body}");

        if (mounted) {
          setState(() {
            // Gunakan casting 'as int' atau parsing untuk keamanan
            userPoints = responseData['data']['current_points'] ?? 0;
            currentRank = responseData['data']['rank_name'] ?? 'Guru';
          });
        }
      } else {
        print("API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await _loadUserData(); // Pastikan token sudah terisi di sini

    if (token != null) {
      // Cek apakah token ada
      await Future.wait([
        fetchAttendanceToday(),
        fetchSchedules(),
        _fetchUserPoints(), // Harus ada di sini!
      ]);
      _fetchVouchers();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  AttendanceModel? _todayAttendance;

  Future<void> _loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    String? storedGuruId = prefs.getString('guru_id');
    // --- TAMBAHKAN BARIS INI ---
    String? storedToken = prefs.getString('auth_token');
    print("DEBUG: Loading Guru ID: $storedGuruId");
    print("DEBUG: Loading Token: $storedToken"); // Cek apakah ini muncul di log
    // ---------------------------

    setState(() {
      _userName = prefs.getString('user_name') ?? "Guru";
      _jabatanAktif = prefs.getString('jabatan_aktif') ?? "Belum Ditugaskan";
      _guruId = storedGuruId ?? "";

      // --- UPDATE STATE TOKEN ---
      token = storedToken;
      // ---------------------------

      _jamMasuk = prefs.getString('jam_masuk') ?? "--:--";
      _jamPulang = prefs.getString('jam_pulang') ?? "--:--";

      String todayStr = DateTime.now().toString().substring(0, 10);
      String? lastSubmitDate = prefs.getString('last_submit_date');
      hasAppliedToday = (lastSubmitDate == todayStr);
    });

    if (_guruId.isEmpty) {
      print("WARNING: Guru ID tidak ditemukan di storage!");
    }

    // Log tambahan untuk memastikan token siap dipakai
    if (token == null) {
      print(
          "WARNING: Token tidak ditemukan! Pastikan saat Login, token disimpan ke prefs dengan key 'token'");
    }
  }

  Future<void> fetchAttendanceToday() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    final String? guruId = prefs.getString('guru_id');

    if (token == null || guruId == null) return;

    try {
      final String url =
          "https://spinningly-proscientific-renay.ngrok-free.dev/api/attendance/today/$guruId";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          setState(() {
            // --- LOGIKA UTAMA DI SINI ---
            // Jika data tidak null, berarti guru SUDAH absen masuk hari ini
            _isMainCheckedIn = responseData['data'] != null;

            if (_isMainCheckedIn) {
              final data = responseData['data'];
              _jamMasuk = data['jam_masuk'] ?? "--:--";
              _jamPulang = data['jam_pulang'] ?? "--:--";
              _statusAbsensi = data['status'] ?? "Hadir";

              // Mengisi data statistik jika ada

              if (_statusAbsensi.toLowerCase() != "hadir") {
                hasAppliedToday = true;
              }
            } else {
              // Jika data null (Belum absen), pastikan status kembali ke default
              _jamMasuk = "--:--";
              _jamPulang = "--:--";
              _statusAbsensi = "Belum Absen";
            }
          });
        }
      } else {
        print("DEBUG: Server Error ${response.statusCode}");
      }
    } catch (e) {
      print("DEBUG: Connection Error: $e");
    }
  }

  Future<void> fetchWeeklyStats() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    final String? guruId = prefs.getString('guru_id');

    if (token == null || guruId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            "https://spinningly-proscientific-renay.ngrok-free.dev/api/attendance/stats/$guruId"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );
    } catch (e) {
      print("Error fetch stats: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = _getAvatarColor(_userName);

    // Bungkus Scaffold dengan Stack agar Sidebar bisa muncul di atasnya
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          key: _scaffoldKey,
          // endDrawer dihapus karena kita pakai SidebarOverlay di bawah
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
              child: RefreshIndicator(
                onRefresh: handleRefresh,
                color: Colors.blue,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.fromLTRB(18.0, 18.0, 18.0, 90.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pastikan di dalam _buildHeader, tombol menu memanggil
                            // setState(() => _isSidebarOpen = true);
                            _buildHeader(themeColor),
                            const SizedBox(height: 28),

                            // Greeting Card
                            _isLoading
                                ? _buildFlatSkeleton(
                                    width: double.infinity,
                                    height: 160,
                                    radius: 24)
                                : _buildGreetingCard(),

                            const SizedBox(height: 16),

                            // Attendance Row
                            _isLoading
                                ? _buildFlatSkeleton(
                                    width: double.infinity,
                                    height: 100,
                                    radius: 20)
                                : _buildAttendanceRow(),

                            const SizedBox(height: 28),

                            // Judul Seksi Jadwal
                            _isLoading
                                ? _buildFlatSkeleton(
                                    width: 150, height: 20, radius: 4)
                                : const Text(
                                    "Today Schedule",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                            const SizedBox(height: 16),

                            // --- PENGGANTI WEEKLY STATS ---
                            _isLoading
                                ? _buildStatsGridSkeleton()
                                : _buildScheduleTimeline(),

                            const SizedBox(height: 24),

                            // Banner Pengajuan Izin
                            _buildLeaveRequestBanner(),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // --- SIDEBAR OVERLAY NYA DI SINI ---
        SidebarOverlay(
          isOpen: _isSidebarOpen, // Buat variabel ini di State kamu
          onClose: () {
            setState(() {
              _isSidebarOpen = false;
            });
          },
          selectedItem: "Dashboard", // Menu yang sedang aktif
          userName: _userName,
          jabatan:
              _jabatanAktif.isNotEmpty ? _jabatanAktif : "Belum Ditugaskan",
          initials: _getInitials(_userName),
          themeColor: themeColor,
        ),
      ],
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
        // Menu Sidebar Button (Pengganti Notif)
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg.withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10),
          ),
          child: IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.primaryBlue),
            onPressed: () {
              // --- GANTI BAGIAN INI ---
              setState(() {
                _isSidebarOpen = true;
              });
              // ------------------------
            },
          ),
        )
      ],
    );
  }

  // --- WIDGET: GREETING CARD (SAAS PROFESSIONAL & GAMIFIED) ---
  // --- WIDGET: POINTS & PROGRESS CARD (MINIMALIST SAAS) ---
  Widget _buildGreetingCard() {
    // --- BAGIAN DINAMIS ---
    // Pastikan variabel userPoints dan currentRank sudah didefinisikan di state
    int targetPoints = 1000;
    int pointsNeeded = (targetPoints - userPoints).clamp(0, targetPoints);
    double progress = (userPoints / targetPoints).clamp(0.0, 1.0);
    String nextLevelName = "Guru Teladan";

    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E2235),
            Color(0xFF111424),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111424).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // --- VISUAL HOOK (KANAN) ---
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue.withOpacity(0.15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      blurRadius: 50,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              right: -90,
              bottom: -10,
              top: 0,
              child: Opacity(
                opacity: 0.6,
                child: Image.asset(
                  'assets/images/bg_greeting.png',
                  width: 210,
                ),
              ),
            ),

            // --- BADGE (KANAN ATAS) ---
            // Menggunakan warna Cyan lembut yang elegan di atas background gelap
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color.fromARGB(255, 255, 159, 24)
                        .withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        color: Color.fromARGB(255, 255, 159, 24), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      currentRank.toUpperCase(),
                      style: const TextStyle(
                        color: Color.fromARGB(255, 255, 159, 24),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- KONTEN TEKS & PROGRESS (KIRI) ---
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TOTAL POIN ANDA",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        userPoints.toString(), // DATA DINAMIS
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "PTS",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // --- PROGRESS LEVELING ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded,
                              color: AppColors.primaryBlue, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            "$pointsNeeded poin lagi menuju ", // DATA DINAMIS
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            nextLevelName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            width: MediaQuery.of(context).size.width * 0.7,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          // Menggunakan AnimatedContainer agar perpindahan bar poin terasa halus
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            height: 6,
                            width: (MediaQuery.of(context).size.width * 0.7) *
                                progress,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryBlue,
                                  Color.fromARGB(255, 48, 69, 174)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withOpacity(0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGET: KOTAK METRIK GLASSMORPHISM ---
  Widget _buildMetricBox({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildAttendanceRow() {
    // 1. Tentukan apakah sedang dalam mode Izin/Sakit
    bool isIzin = _statusAbsensi.toLowerCase() == "izin";
    bool isSakit = _statusAbsensi.toLowerCase() == "sakit";
    bool isSpecialStatus = isIzin || isSakit;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: isSpecialStatus
          ? _buildSpecialStatusUI(isSakit) // Tampilan jika Izin/Sakit
          : _buildNormalAttendanceUI(), // Tampilan normal Masuk/Pulang
    );
  }

  Widget _buildSpecialStatusUI(bool isSakit) {
    Color statusColor = isSakit ? AppColors.purpleIcon : AppColors.blueIcon;
    // Kita buat gradient background yang sangat halus
    Color bgGradient = isSakit ? AppColors.purpleBg : AppColors.blueBg;

    return Container(
      width: double.infinity,
      child: Row(
        children: [
          // 1. Ikon dengan Background Bulat & Glow
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border:
                  Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
              // boxShadow: [
              //   BoxShadow(
              //     color: statusColor.withOpacity(0.2),
              //     blurRadius: 12,
              //     spreadRadius: 1,
              //   )
              // ],
            ),
            child: Icon(
              isSakit
                  ? Icons.medical_services_rounded
                  : Icons.assignment_turned_in_rounded,
              color: statusColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),

          // 2. Teks Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      isSakit ? "SAKIT" : "IZIN",
                      style: GoogleFonts.poppins(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge "Approved" kecil
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "APPROVED",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "Status absensi Anda hari ini adalah ${isSakit ? 'Sakit' : 'Izin'}.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // 3. Dekorasi kecil di pojok kanan (opsional)
          Icon(
            Icons.verified_user_rounded,
            color: Colors.white.withOpacity(0.05),
            size: 40,
          )
        ],
      ),
    );
  }

  // --- WIDGET: JAM MASUK / PULANG ---
  Widget _buildNormalAttendanceUI() {
    return Row(
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
                          : const Color.fromARGB(255, 126, 126, 126),
                      fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: AppColors.primaryBlue.withOpacity(0.5),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Tidak Ada Jadwal",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Hari ini adalah waktu istirahat Anda.",
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTimeline() {
    if (_schedules.isEmpty) {
      return _buildEmptyState();
    }

    // --- 1. LOGIKA PENYISIPAN ISTIRAHAT DINAMIS ---
    List<dynamic> combinedSchedules = List.from(_schedules);
    bool hasBreak = combinedSchedules.any((item) => item['is_break'] == true);

    if (!hasBreak) {
      int insertIndex = combinedSchedules.indexWhere((item) {
        String startTime = item['start_time']?.toString() ?? "00:00:00";
        return startTime.compareTo("12:00:00") >= 0;
      });

      if (insertIndex == -1) insertIndex = combinedSchedules.length;

      combinedSchedules.insert(insertIndex, {
        'subject_name': 'ISTIRAHAT',
        'start_time': '12:00:00',
        'end_time': '13:00:00',
        'classroom_name': 'Kantin / Area Bebas',
        'is_break': true,
        'is_attended': false, // Istirahat tidak perlu absen
      });
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: combinedSchedules.length,
      itemBuilder: (context, index) {
        final item = combinedSchedules[index];

        print(
            "DEBUG: Pelajaran ${item['subject_name']} statusnya: ${item['is_attended']}");
        bool isLast = index == combinedSchedules.length - 1;
        bool isBreak = item['is_break'] == true;
        bool isAttended = item['is_attended'] == true;
        print("DEBUG: Isi lengkap item: ${item.toString()}");

        // Ambil jam dengan aman (menghindari RangeError substring)
        String rawStart = item['start_time']?.toString() ?? "00:00";
        String rawEnd = item['end_time']?.toString() ?? "00:00";
        String start = rawStart.split(':').take(2).join(':');
        String end = rawEnd.split(':').take(2).join(':');

        // Logika status aktif (pastikan format padLeft agar 09:00 bukan 9:00)
        final now = DateTime.now();
        final currentTime =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

        // Cek apakah sekarang berada di dalam rentang waktu pelajaran
        // Logika status aktif (Jam cocok DAN sudah absen masuk utama)
        bool isTimeMatch = currentTime.compareTo(start) >= 0 &&
            currentTime.compareTo(end) <= 0;

// Card AKTIF jika: (Waktunya pas DAN sudah absen sekolah) ATAU (Ini adalah jam istirahat)
        bool isActive =
            isBreak ? isTimeMatch : (isTimeMatch && _isMainCheckedIn);

        // Warna utama berdasarkan status
        Color activeColor =
            isBreak ? Colors.orangeAccent : AppColors.primaryBlue;
        if (isAttended) activeColor = Colors.greenAccent;

        return IntrinsicHeight(
          child: Row(
            children: [
              // --- Timeline Indicator ---
              SizedBox(
                width: 30,
                child: Column(
                  children: [
                    Expanded(
                      child: index == 0
                          ? const SizedBox()
                          : CustomPaint(
                              size: Size.infinite,
                              painter: DashedLinePainter(),
                            ),
                    ),
                    // Titik (Dot) - Berubah Hijau jika sudah absen
                    Container(
                      width: isActive ? 14 : 12,
                      height: isActive ? 14 : 12,
                      decoration: BoxDecoration(
                        color: isAttended
                            ? Colors.greenAccent
                            : (isActive
                                ? activeColor
                                : AppColors.primaryBlue.withOpacity(0.3)),
                        shape: BoxShape.circle,
                        boxShadow: isActive || isAttended
                            ? [
                                BoxShadow(
                                  color: (isAttended
                                          ? Colors.greenAccent
                                          : activeColor)
                                      .withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                    ),
                    Expanded(
                      child: isLast
                          ? const SizedBox()
                          : CustomPaint(
                              size: Size.infinite,
                              painter: DashedLinePainter(),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // --- Schedule Card ---
              // --- Schedule Card ---
              Expanded(
                child: MouseRegion(
                  // Opsional: Agar kursor berubah jadi pointer di web/desktop
                  cursor: (isActive && !isAttended && !isBreak)
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: GestureDetector(
                    onTap: () {
                      if (isBreak) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Selamat beristirahat! ☕")));
                      } else if (isAttended) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                "Anda sudah melakukan presensi di kelas ini.")));
                      } else if (isTimeMatch && !_isMainCheckedIn) {
                        // --- TAMBAHKAN KONDISI INI ---
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.orange,
                            content: Text(
                                "Silakan lakukan Absen Masuk sekolah terlebih dahulu!"),
                          ),
                        );
                      } else if (isActive) {
                        // Navigasi ke Scanner
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const QRScannerPage()),
                        ).then((result) {
                          if (result == true) {
                            // _fetchSchedules();
                          }
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Sesi presensi belum dimulai.")));
                      }
                    },
                    child: AnimatedContainer(
                      // Gunakan AnimatedContainer agar transisi border lebih halus
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isBreak
                            ? Colors.orangeAccent.withOpacity(0.05)
                            : (isAttended
                                ? Colors.greenAccent.withOpacity(0.02)
                                : (isActive
                                    ? AppColors.cardBg
                                    : AppColors.cardBg)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          // Cari bagian ini di dalam Column timeline indicator
                          color: isAttended
                              ? Colors.greenAccent
                              : (isActive
                                  ? activeColor
                                  : AppColors.primaryBlue.withOpacity(
                                      0.1)), // Pudar jika !isActive
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isActive && !isAttended
                                ? activeColor.withOpacity(0.2)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // ... (Icon Background dekoratif tetap sama)
                          Positioned(
                            right: -10,
                            bottom: -10,
                            child: Icon(
                              isAttended
                                  ? Icons.check_circle_rounded
                                  : (isBreak
                                      ? Icons.coffee_rounded
                                      : Icons.school_rounded),
                              size: 80,
                              color: isAttended
                                  ? Colors.greenAccent.withOpacity(0.05)
                                  : (isActive
                                      ? activeColor.withOpacity(0.1)
                                      : Colors.white.withOpacity(0.03)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTimeColumn(
                                    start, end, isBreak, activeColor),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isBreak
                                                ? Icons.restaurant_rounded
                                                : Icons.menu_book_rounded,
                                            size: 16,
                                            color: activeColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item['subject_name'] ??
                                                  "Mata Pelajaran",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: isBreak
                                                    ? Colors.orangeAccent
                                                    : Colors.white,
                                                height: 1.2,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Info Lokasi
                                      Row(
                                        children: [
                                          Icon(
                                            isBreak
                                                ? Icons.rocket_launch_sharp
                                                : Icons.meeting_room_rounded,
                                            size: 14,
                                            color: AppColors.textGrey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isBreak
                                                ? "Selamat Beristirahat"
                                                : "Kelas ${item['classroom_name']}",
                                            style: const TextStyle(
                                              color: AppColors.textGrey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),

                                      // --- LOGIKA LABEL STATUS ---
                                      if (!isBreak) ...[
                                        const SizedBox(height: 12),
                                        if (isAttended)
                                          _buildStatusLabel(
                                              "Absensi Selesai",
                                              Colors.greenAccent,
                                              Icons.verified_rounded)
                                        else if (isActive)
                                          _buildStatusLabel(
                                              "Klik untuk Presensi", // Diubah agar user tahu bisa diklik
                                              Colors.amberAccent,
                                              Icons.qr_code_scanner_rounded),
                                      ],
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// Fungsi Helper untuk Label agar kode UI di atas tetap bersih
  Widget _buildStatusLabel(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

// Helper widget untuk kolom waktu agar kode lebih bersih
  Widget _buildTimeColumn(String start, String end, bool isBreak, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(start,
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 14, color: color)),
          const SizedBox(height: 2),
          Text("SD",
              style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.5))),
          const SizedBox(height: 2),
          Text(end,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestBanner() {
    // Tentukan warna dan konten berdasarkan status hasAppliedToday
    final Color cardColor = hasAppliedToday
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFF1E293B);
    final String title =
        hasAppliedToday ? "Pengajuan Terkirim" : "Berhalangan Hadir?";
    final String subtitle = hasAppliedToday
        ? "Anda sudah melakukan pengajuan izin untuk hari ini."
        : "Ajukan izin dengan cepat melalui form digital di sini.";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: hasAppliedToday
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF1E293B), const Color(0xFF0F172A)],
              ),
        color: hasAppliedToday
            ? const Color(0xFF161B22)
            : null, // Warna redup jika sudah submit
        border: hasAppliedToday ? Border.all(color: Colors.white12) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // JIKA SUDAH APPLY, TAP DINONAKTIFKAN (null)
          onTap: hasAppliedToday ? null : () => _showLeaveRequestForm(context),
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: hasAppliedToday
                      ? Colors.white.withOpacity(0.02)
                      : AppColors.primaryBlue.withOpacity(0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: hasAppliedToday
                                  ? Colors.green.withOpacity(0.1)
                                  : AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              hasAppliedToday ? "SUBMITTED" : "LEAVE REQUEST",
                              style: TextStyle(
                                color: hasAppliedToday
                                    ? Colors.green
                                    : AppColors.primaryBlue,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white
                                  .withOpacity(hasAppliedToday ? 0.3 : 0.6),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Ikon berubah jadi Checkmark jika sudah submit
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasAppliedToday
                            ? Colors.white10
                            : AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasAppliedToday
                            ? Icons.check_circle_outline_rounded
                            : Icons.arrow_forward_rounded,
                        color: hasAppliedToday ? Colors.green : Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

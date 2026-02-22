import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:identra_mobile_flutter/leave_request_sheet.dart';
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
  // Statistik Mingguan
  int _countTerlambat = 0;
  int _countIzin = 0;
  int _countSakit = 0;
  int _countAlfa = 0;
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

    setState(() {
      _userName = prefs.getString('user_name') ?? "Guru";

      String? storedJabatan = prefs.getString('jabatan_aktif');
      _jabatanAktif = (storedJabatan != null && storedJabatan.isNotEmpty)
          ? storedJabatan
          : "Guru Tetap";

      _guruId = prefs.getString('guru_id') ?? "";
      _jamMasuk = prefs.getString('jam_masuk') ?? "--:--";
      _jamPulang = prefs.getString('jam_pulang') ?? "--:--";

      // --- TAMBAHKAN LOGIKA INI ---
      // Cek apakah hari ini guru sudah pernah submit izin
      String todayStr =
          DateTime.now().toString().substring(0, 10); // Hasil: "2024-05-22"
      String? lastSubmitDate = prefs.getString('last_submit_date');

      if (lastSubmitDate == todayStr) {
        hasAppliedToday = true;
      } else {
        // Jika sudah ganti hari, reset statusnya jadi false lagi
        hasAppliedToday = false;
      }
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

        // Di dalam fetchAttendanceToday, setelah decode JSON:
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          if (responseData['success'] == true && responseData['data'] != null) {
            final data = responseData['data'];
            final stats =
                responseData['stats']; // <--- Asumsi API punya field 'stats'

            setState(() {
              _jamMasuk = data['jam_masuk'] ?? "--:--";
              _jamPulang = data['jam_pulang'] ?? "--:--";
              _statusAbsensi = data['status'] ?? "Hadir";

              // MENGISI DATA STATISTIK DARI API
              // Sesuaikan nama field ('terlambat_count', dll) dengan response dari backend-mu
              _countTerlambat = data['terlambat_count'] ?? 0;
              _countIzin = data['izin_count'] ?? 0;
              _countSakit = data['sakit_count'] ?? 0;
              _countAlfa = data['alfa_count'] ?? 0;

              // Logika banner
              if (_statusAbsensi.toLowerCase() != "hadir") {
                hasAppliedToday = true;
              }
            });
          }
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            // Sesuaikan dengan key yang dikirim oleh backend-mu
            _countTerlambat = data['data']['terlambat'] ?? 0;
            _countIzin = data['data']['izin'] ?? 0;
            _countSakit = data['data']['sakit'] ?? 0;
            _countAlfa = data['data']['alfa'] ?? 0;
          });
        }
      }
    } catch (e) {
      print("Error fetch stats: $e");
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

  // --- WIDGET: STATS GRID ---
  Widget _buildStatsGrid() {
    Widget statItem(
        String title, String count, Color baseColor, IconData icon) {
      return Container(
        decoration: BoxDecoration(
          color: baseColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: baseColor.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
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
                ],
              ),
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
                  Text(
                    "$count Hari", // Tampilkan angka dari state
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
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
        statItem("Terlambat", _countTerlambat.toString(), AppColors.orangeIcon,
            Icons.access_time_filled),
        statItem("Izin", _countIzin.toString(), AppColors.blueIcon,
            Icons.description),
        statItem("Sakit", _countSakit.toString(), AppColors.purpleIcon,
            Icons.medical_services),
        statItem("Tanpa Ket", _countAlfa.toString(), AppColors.redIcon,
            Icons.cancel),
      ],
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

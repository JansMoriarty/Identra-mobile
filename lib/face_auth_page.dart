import 'dart:io';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:identra_mobile_flutter/services/voucher_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:identra_mobile_flutter/services/face_service.dart'; // Sesuaikan path-nya
import 'dart:math' as math;

class FaceAuthPage extends StatefulWidget {
  final String statusType;

  final int? userTokenId; // Tambahkan ini
  final bool useWfhMode; // Tambahkan ini

  // Nilai default 'hadir', bisa jadi 'pulang' jika di-oper dari navigasi
  const FaceAuthPage({
    Key? key,
    required this.statusType,
    this.userTokenId,
    this.useWfhMode = false, // Default false jika absen normal
  }) : super(key: key);

  @override
  State<FaceAuthPage> createState() => _FaceAuthPageState();
}

class _FaceAuthPageState extends State<FaceAuthPage> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;

  Map<String, dynamic>? _selectedToken;
  TimeOfDay _jamMasukTarget =
      const TimeOfDay(hour: 7, minute: 0); // Default jika API gagal
  bool _isLoadingRules = true;

  int _currentStep = 0;
  String _statusMsg = "Posisikan wajah di dalam lingkaran";
  String _jamMasukDariApi = "07:00:00"; // Default awal

  Future<void> _loadAttendanceSettings() async {
    print("DEBUG: Fungsi _loadAttendanceSettings DIMULAI");

    final url = Uri.parse(
        'https://spinningly-proscientific-renay.ngrok-free.dev/api/attendance/settings');

    try {
      print("DEBUG: Mencoba HTTP GET ke: $url");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
      ).timeout(const Duration(
          seconds: 10)); // Tambahkan timeout biar gak nunggu selamanya

      print("DEBUG: Koneksi Berhasil, Status Code: ${response.statusCode}");
      print("DEBUG: Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _jamMasukDariApi = data['jam_masuk'] ?? "07:00:00";
        });
        print("DEBUG: Variabel diperbarui ke: $_jamMasukDariApi");
      }
    } catch (e) {
      print("DEBUG: ERROR TERJADI -> $e");
    }
  }

  final List<String> _stepTitles = [
    "Deteksi Wajah",
    "Pemindaian Wajah",
    "Mencari Lokasi GPS",
    "Selesai"
  ];

  // --- TEMA WARNA SESUAI SCREENSHOT ---
  final Color _bgColor = const Color(0xFF111424);
  final Color _cardColor = const Color(0xFF1C2031);
  final Color _accentBlue = const Color(0xFF4F63F2);
  final Color _textWhite = Colors.white;
  final Color _textGray = const Color(0xFFA0A5B9);

  @override
  void initState() {
    super.initState();
    print("--- APLIKASI DIMULAI ---");

    // Jalankan fungsi fetch secara terpisah agar tidak mengganggu kamera
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendanceSettings();
    });

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCam =
        cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);

    _cameraController =
        CameraController(frontCam, ResolutionPreset.medium, enableAudio: false);

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
        _startAuthProcess(widget.statusType);
      }
    } catch (e) {
      _showSnackBar("Gagal membuka kamera: $e", Colors.redAccent);
    }
  }

  // LOGIKA UTAMA ALUR PROSES
  void _startAuthProcess(String statusType) async {
    if (_isProcessing ||
        !mounted ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) return;

    _isProcessing = true;
    setState(() {
      _currentStep = 0;
      _statusMsg = "Mendeteksi bentuk wajah...";
    });

    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      XFile file = await _cameraController!.takePicture();

      setState(() {
        _currentStep = 1;
        _statusMsg = "Memproses kecocokan wajah...";
      });
      final embedding = await FaceService().getEmbedding(File(file.path));

      if (embedding != null) {
        setState(() {
          _currentStep = 2;
          _statusMsg = "Wajah Terdeteksi! Mengecek Lokasi...";
        });

        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
        } catch (e) {
          print("⚠️ GPS Timeout, lokasi terakhir...");
          position = await Geolocator.getLastKnownPosition();
        }

        if (position != null) {
          _showConfirmationModal(
              embedding, position.latitude, position.longitude, statusType);
        } else {
          _showSnackBar("Gagal mendapatkan lokasi. Pastikan GPS aktif!",
              Colors.redAccent);
          _isProcessing = false;
          _resetProcess(statusType);
        }
      } else {
        setState(() => _statusMsg = "Wajah tidak jelas, mencoba lagi...");
        await Future.delayed(const Duration(seconds: 1));
        _isProcessing = false;
        _startAuthProcess(statusType);
      }

      final tempFile = File(file.path);
      if (await tempFile.exists()) await tempFile.delete();
    } catch (e) {
      print("❌ Error di AuthProcess: $e");
      _isProcessing = false;
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _startAuthProcess(statusType);
    }
  }

  Future<void> _fetchAttendanceRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Sesuaikan URL dengan endpoint yang mengembalikan data point_rules
      final response = await http.get(
        Uri.parse(
            'https://spinningly-proscientific-renay.ngrok-free.dev/api/attendance/settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String timeStr = data['data']['condition_time'];
        List<String> parts = timeStr.split(':');

        setState(() {
          _jamMasukTarget =
              TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          _isLoadingRules = false;
        });
      }
    } catch (e) {
      print("Gagal ambil rules: $e");
      setState(() => _isLoadingRules = false);
    }
  }

  Future<Map<String, dynamic>?> _pickTokenDialog() async {
    // 1. Ambil data token dari API (Sesuaikan endpoint kamu)
    // Contoh: http://localhost:8000/api/user-tokens/available

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Pilih Voucher Kompensasi",
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<List<dynamic>>(
              future: _fetchMyAvailableTokens(), // Fungsi ambil data dari API
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty)
                  return Text("Anda tidak memiliki voucher.");

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var token = snapshot.data![index];
                    return ListTile(
                      leading:
                          Icon(Icons.confirmation_number, color: Colors.orange),
                      title: Text(token['item']['item_name']),
                      subtitle:
                          Text("Power: ${token['item']['value_power']} Menit"),
                      onTap: () => Navigator.pop(
                          context, token), // Kirim data token kembali
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

// Fungsi dummy/tambahan untuk ambil data token
  Future<List<dynamic>> _fetchMyAvailableTokens() async {
    // Ganti dengan logic http.get kamu yang mengambil daftar voucher user
    // Untuk sementara, pastikan endpoint ini ada di Laravel
    return [];
  }

  // MODAL KONFIRMASI ABSEN
  void _showConfirmationModal(
      List<double> embedding, double lat, double lng, String statusType) {
    final now = DateTime.now();

    List<String> timeParts = _jamMasukDariApi.split(':'); // Ambil dari State
    int targetHour = int.parse(timeParts[0]);
    int targetMinute = int.parse(timeParts[1]);

    // Sisanya sudah benar...
    final batasMasuk =
        DateTime(now.year, now.month, now.day, targetHour, targetMinute);
    final selisihMenit = now.difference(batasMasuk).inMinutes;

    // Modal telat muncul jika statusnya 'hadir' dan sudah lewat jam masuk
    bool isLate = statusType == 'hadir' && selisihMenit > 0;
    // Ambil warna tema dari class kamu
    final Color cardColor = const Color(0xFF1C2031);
    final Color accentBlue = const Color(0xFF4F63F2);
    final Color textWhite = Colors.white;
    final Color textGray = const Color(0xFFA0A5B9);

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent, // Transparan agar bisa custom border radius
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.only(
                  left: 24, right: 24, top: 12, bottom: 32),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- DRAG HANDLE ---
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- HEADER ---
                  Icon(
                    statusType == 'hadir'
                        ? Icons.login_rounded
                        : Icons.logout_rounded,
                    color: accentBlue,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Konfirmasi Absensi",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: textWhite,
                    ),
                  ),
                  Text(
                    "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- WIDGET TELAT & VOUCHER ---
                  if (isLate) ...[
                    // WIDGET PERINGATAN TELAT
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.warning_amber_rounded,
                                color: Colors.orange, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Terlambat $selisihMenit Menit",
                                  style: GoogleFonts.poppins(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Poin akan dipotong otomatis kecuali menggunakan voucher.",
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: textGray),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // TOMBOL PILIH VOUCHER (Custom Card Button)
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      // Cari bagian ini di dalam _showConfirmationModal
                      onTap: () async {
                        // Pindah ke halaman VoucherSelectionPage dan bawa data keterlambatan
                        var token = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VoucherSelectionPage(
                              latenessMinutes: selisihMenit,
                              statusType: statusType,
                            ),
                          ),
                        );

                        if (token != null) {
                          setModalState(() {
                            _selectedToken = token;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedToken == null
                              ? Colors.transparent
                              : accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedToken == null
                                ? Colors.white.withOpacity(0.1)
                                : accentBlue,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_activity_outlined,
                              color: _selectedToken == null
                                  ? textGray
                                  : accentBlue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedToken == null
                                        ? "Gunakan Voucher"
                                        : "Voucher Terpasang",
                                    style: GoogleFonts.poppins(
                                      color: _selectedToken == null
                                          ? textWhite
                                          : accentBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_selectedToken != null)
                                    Text(
                                      _selectedToken!['item']['item_name'],
                                      style: GoogleFonts.poppins(
                                        color: textGray,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: _selectedToken == null
                                  ? textGray
                                  : accentBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // --- TOMBOL KIRIM UTAMA ---
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // 1. Tutup modal/bottom sheet
                        Navigator.pop(context);

                        // 2. Panggil fungsi verify hanya dengan data wajib
                        // Kita hapus 'userTokenId' dan 'useWfhMode'
                        // Di dalam onPressed ElevatedButton modal konfirmasi
                        _sendToVerify(
                          embedding,
                          lat,
                          lng,
                          widget.statusType,
                          // GANTI BAGIAN INI:
                          // Jangan pakai widget.userTokenId, tapi pakai _selectedToken
                          userTokenId: _selectedToken != null
                              ? _selectedToken!['id']
                              : null,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Absen Sekarang",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _resetProcess(String statusType) async {
    setState(() => _currentStep = 0);
    await Future.delayed(const Duration(seconds: 1));
    _startAuthProcess(statusType);
  }

  // KIRIM DATA KE SERVER
  // KIRIM DATA KE SERVER
  Future<void> _sendToVerify(
    List<double> embedding,
    double lat,
    double lng,
    String status, {
    int? userTokenId, // Parameter voucher tetap opsional
  }) async {
    setState(() {
      _statusMsg = "Mengirim data verifikasi...";
      _isProcessing = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? authToken = prefs.getString('auth_token');
      final String? guruId = prefs.getString('guru_id');

      final url = Uri.parse(
          'https://spinningly-proscientific-renay.ngrok-free.dev/api/attendance/verify-face');

      // Susun body request secara bersih
      final Map<String, dynamic> bodyData = {
        'guru_id': guruId,
        'latitude': lat,
        'longitude': lng,
        'status': status,
        'captured_embedding': embedding, // WAJIB dikirim untuk Face Matching
      };

      // Tambahkan user_token_id HANYA jika ada (untuk Late Waver)
      if (userTokenId != null && userTokenId != 0) {
        bodyData['user_token_id'] = userTokenId;
      }

      print("DEBUG PAYLOAD: ${jsonEncode(bodyData)}");

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode(bodyData),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSnackBar("✅ ${data['message']}", const Color(0xFF4CAF50));
        if (mounted) Navigator.pop(context, true);
      } else {
        String pesan = data['message'] ?? "Gagal verifikasi";
        _showSnackBar("❌ $pesan", Colors.redAccent);
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      _showSnackBar("⚠️ Masalah koneksi: $e", Colors.redAccent);
      setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameraController == null) {
      return Scaffold(
          backgroundColor: _bgColor,
          body: Center(child: CircularProgressIndicator(color: _accentBlue)));
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Layer 1: Kamera
          ClipRect(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize!.height,
                  height: _cameraController!.value.previewSize!.width,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            ),
          ),

          // Layer 2: Overlay Gelap Tema Navy
          _buildOverlayMask(size),

          // Layer 3: Tombol Back (Dibungkus lingkaran agak gelap agar terlihat)
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: _bgColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Layer 4: History / Progress Panel
          _buildStepProgressPanel(),
        ],
      ),
    );
  }

  Widget _buildOverlayMask(Size size) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        _bgColor.withOpacity(0.85), // Warna Navy dominan dari tema aplikasi
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Align(
            alignment: const Alignment(0.0, -0.3),
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET UI: History/Progress Tracker Panel
  Widget _buildStepProgressPanel() {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Status Proses",
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold, color: _textWhite),
            ),
            const SizedBox(height: 16),
            // Build list steps secara dinamis
            ...List.generate(_stepTitles.length, (index) {
              return _buildStepItem(index, _stepTitles[index]);
            }),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _statusMsg,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _accentBlue),
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    );
  }

  // WIDGET UI: Item individual dalam list progress
  Widget _buildStepItem(int index, String title) {
    bool isCompleted = _currentStep > index;
    bool isActive = _currentStep == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Ikon indikator
          SizedBox(
            width: 24,
            height: 24,
            child: isCompleted
                ? const Icon(Icons.check_circle,
                    color: Color(0xFF4CAF50), size: 24)
                : isActive
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: _accentBlue),
                      )
                    : Icon(Icons.radio_button_unchecked,
                        color: Colors.white.withOpacity(0.2), size: 24),
          ),
          const SizedBox(width: 16),
          // Teks Judul
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isCompleted
                  ? _textWhite
                  : isActive
                      ? _accentBlue
                      : _textGray,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}

// ============================================================================
// HALAMAN PILIH VOUCHER (UI SESUAI SCREENSHOT)
// ============================================================================

class VoucherSelectionPage extends StatefulWidget {
  final int latenessMinutes;
  final String statusType;

  const VoucherSelectionPage({
    super.key,
    required this.latenessMinutes,
    required this.statusType,
  });

  @override
  State<VoucherSelectionPage> createState() => _VoucherSelectionPageState();
}

class _VoucherSelectionPageState extends State<VoucherSelectionPage> {
  final Color _bgColor = const Color(0xFF111424);

  late Future<List<dynamic>> _tokensFuture;

  @override
  void initState() {
    super.initState();
    _tokensFuture = VoucherService().getMyTokens();
  }

  // FUNGSI DUMMY API: Ganti dengan HTTP GET ke Laravel kamu
  Future<List<dynamic>> _fetchTokens() async {
    // Contoh response dari API
    return [
      {
        "id": 1,
        "item": {
          "item_name": "Token Bebas Terlambat",
          "description":
              "Gunakan token ini untuk memutihkan keterlambatan maksimal 15 menit.",
          "value_power": 15,
          "type": "LATE" // Anggap ada field penanda tipe
        }
      },
      {
        "id": 2,
        "item": {
          "item_name": "Work From Home",
          "description":
              "Gunakan token ini untuk memutihkan keterlambatan maksimal 1 hari.",
          "value_power": 1440, // Misal 1 hari = 1440 menit
          "type": "WFH"
        }
      }
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Pilih Voucher",
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _tokensFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text("Tidak ada voucher tersedia",
                    style: GoogleFonts.poppins(color: Colors.white)),
              );
            }

            /// 🔥 FILTER TOKEN AVAILABLE SAJA
            final tokens = snapshot.data!
                .where((t) => t['status'] == 'AVAILABLE')
                .toList();

            if (tokens.isEmpty) {
              return Center(
                child: Text("Tidak ada voucher yang bisa digunakan",
                    style: GoogleFonts.poppins(color: Colors.white)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: tokens.length,
              itemBuilder: (context, index) {
                final token = tokens[index];
                final item = token['item'];

                String title = item['item_name'] ?? "";
                int power = item['value_power'] ?? 0;

                /// 🔥 DETEKSI TYPE (PAKE item_type dari backend)
                String type = item['item_type'] ?? '';

                bool isWfh = type == 'WFH_PASS';

                /// 🔥 VALIDASI
                bool isEligible = true;
                String disableReason = "";

                if (isWfh && widget.statusType == 'hadir') {
                  isEligible = false;
                  disableReason = "WFH tidak bisa digunakan untuk absen wajah.";
                } else if (!isWfh && power < widget.latenessMinutes) {
                  isEligible = false;
                  disableReason =
                      "Power tidak cukup (${power} < ${widget.latenessMinutes})";
                }

                /// 🔥 VISUAL
                Color cardColor =
                    isWfh ? const Color(0xFF0F9D58) : const Color(0xFF4F63F2);

                IconData iconData = isWfh
                    ? Icons.home_work_rounded
                    : Icons.history_toggle_off_rounded;

                String badgeText = isWfh ? "+1 Hari" : "+$power Menit";

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () {
                      if (isEligible) {
                        Navigator.pop(context, token);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(disableReason),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    child: Opacity(
                      opacity: isEligible ? 1 : 0.4,
                      child: ClipPath(
                        clipper: TicketClipper(),
                        child: Container(
                          color: cardColor,
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                /// ICON
                                SizedBox(
                                  width: 80,
                                  child: Center(
                                    child: Icon(iconData,
                                        color: Colors.white, size: 40),
                                  ),
                                ),

                                /// DASHED LINE
                                CustomPaint(
                                  size: const Size(1, double.infinity),
                                  painter: DashedLinePainter(),
                                ),

                                /// CONTENT
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        Text(
                                          item['description'] ?? "-",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        /// BADGE POWER
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.25),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            badgeText,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ));
  }
}

// ============================================================================
// WIDGET KUSTOM: PEMOTONG BENTUK TIKET (TICKET CLIPPER)
// ============================================================================
class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const double radius = 16.0;

    // Potongan setengah lingkaran ada di sisi kanan (posisi vertikal tengah)
    final double holeY = size.height * 0.5;

    path.lineTo(0.0, 0.0); // Mulai dari Kiri Atas
    path.lineTo(size.width, 0.0); // Tarik ke Kanan Atas

    // Tarik ke bawah menuju area potongan lubang (Kanan)
    path.lineTo(size.width, holeY - radius);
    path.arcToPoint(
      Offset(size.width, holeY + radius),
      radius: const Radius.circular(radius),
      clockwise: false, // Potong ke dalam
    );

    path.lineTo(size.width, size.height); // Ke Kanan Bawah
    path.lineTo(0.0, size.height); // Ke Kiri Bawah
    path.close(); // Tutup path kembali ke Kiri Atas

    return path;
  }

  @override
  bool // shouldReclip
      shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ============================================================================
// WIDGET KUSTOM: GARIS PUTUS-PUTUS VERTIKAL
// ============================================================================
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 5, startY = 0;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.5;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

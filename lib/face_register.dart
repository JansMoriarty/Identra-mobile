import 'dart:io';
import 'package:camera/camera.dart';
import 'dart:convert'; // Untuk jsonEncode
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:identra_mobile_flutter/services/face_service.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class FaceRegisterPage extends StatefulWidget {
  const FaceRegisterPage({super.key});

  @override
  State<FaceRegisterPage> createState() => _FaceRegisterPageState();
}

class _FaceRegisterPageState extends State<FaceRegisterPage> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;
  double _registrationProgress = 0.0;
  List<List<double>> _capturedEmbeddings = [];
  String _statusMsg = "Posisikan wajah di dalam lingkaran";
  bool _isSaving = false;
  String? _token;
  String? _userId; // Tambahkan variabel untuk menampung ID Guru

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadUserData();
    ;
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Ambil sesuai dengan key yang disimpan di LoginPage
      _token =
          prefs.getString('auth_token'); // Tadi di login simpan 'auth_token'
      _userId = prefs
          .getString('user_id'); // Tadi di login simpan 'user_id' (angka 2)
    });
  }

  // 2. Perbaikan Fungsi Kirim (Gunakan data dinamis)
  Future<void> _sendToServer(List<double> embedding) async {
    // Pastikan kita ambil GURU_ID (UUID), bukan USER_ID (Angka)
    final prefs = await SharedPreferences.getInstance();
    final String? guruUuid = prefs.getString('guru_id'); // Ambil UUID

    if (_token == null || guruUuid == null) {
      _showSnackBar("❌ Sesi habis atau ID tidak ditemukan", Colors.red);
      return;
    }

    final url = Uri.parse(
        'https://spinningly-proscientific-renay.ngrok-free.dev/api/attendance/store-face');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'guru_id': guruUuid, // Kirim UUID (misal: 1ddb21...)
          'face_descriptor':
              embedding, // HARUS 'face_descriptor' sesuai Laravel
          // Status dihapus karena tidak diminta di controller registerFace
        }),
      );

      print("DEBUG REGISTER: Status ${response.statusCode}");
      print("DEBUG REGISTER: Body ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("✅ Profil wajah berhasil disimpan!", Colors.green);
        if (mounted) {
          Navigator.of(context).pop(); // Tutup Dialog
          Navigator.of(context).pop(); // Kembali ke Dashboard
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackBar(
            "❌ Gagal: ${errorData['message'] ?? 'Error'}", Colors.red);
      }
    } catch (e) {
      _showSnackBar("❌ Koneksi Gagal: $e", Colors.red);
    }
  }

  // 3. Perbaikan Dialog agar memanggil fungsi simpan & ada loading
  void _showSuccessDialog(List<double> embedding) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        // Agar loading bisa update di dalam dialog
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1D26),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Registrasi Selesai",
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Data wajah Anda telah dihitung rata-rata untuk akurasi maksimal.",
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
                if (_isSaving) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: Colors.blueAccent),
                ]
              ],
            ),
            actions: [
              if (!_isSaving)
                TextButton(
                  onPressed: () async {
                    setDialogState(
                        () => _isSaving = true); // Aktifkan loading di dialog
                    await _sendToServer(embedding);
                    if (mounted) setDialogState(() => _isSaving = false);
                  },
                  child: Text("SIMPAN KE SERVER",
                      style: GoogleFonts.poppins(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold)),
                )
            ],
          );
        },
      ),
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCam = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);

    _cameraController = CameraController(
      frontCam,
      ResolutionPreset.high, // Gunakan resolusi tinggi agar akurat
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
        _startAutoRegistration();
      }
    } catch (e) {
      debugPrint("Kamera error: $e");
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _startAutoRegistration() async {
    if (_registrationProgress >= 1.0 || _isProcessing || !mounted) return;

    _isProcessing = true;

    try {
      XFile file = await _cameraController!.takePicture();
      File imageFile = File(file.path);

      List<double>? embedding = await FaceService().getEmbedding(imageFile);

      if (embedding != null) {
        _capturedEmbeddings.add(embedding);
        if (mounted) {
          setState(() {
            _registrationProgress = _capturedEmbeddings.length / 10;
            _statusMsg = "Merekam... ${(_registrationProgress * 100).toInt()}%";
          });
        }
        await imageFile.delete();
      } else {
        if (mounted) setState(() => _statusMsg = "Wajah tidak terdeteksi!");
      }
    } catch (e) {
      debugPrint("Scan error: $e");
    }

    _isProcessing = false;

    if (_registrationProgress < 1.0) {
      Future.delayed(const Duration(milliseconds: 400), _startAutoRegistration);
    } else {
      _finishRegistration();
    }
  }

  void _finishRegistration() {
    if (mounted) {
      setState(() => _statusMsg = "Menghitung rata-rata wajah...");
      List<double> finalEmbedding =
          _calculateAverageEmbedding(_capturedEmbeddings);
      _showSuccessDialog(finalEmbedding);
    }
  }

  List<double> _calculateAverageEmbedding(List<List<double>> embeddings) {
    int len = embeddings[0].length;
    List<double> avg = List.filled(len, 0.0);

    for (var e in embeddings) {
      for (int i = 0; i < len; i++) {
        avg[i] += e[i];
      }
    }
    return avg.map((val) => val / embeddings.length).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameraController == null) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()));
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // FIX: Camera Preview Anti-Stretch & Anti-Mirror
          ClipRect(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  // Preview size biasanya terbalik antara width & height di mobile
                  width: _cameraController!.value.previewSize!.height,
                  height: _cameraController!.value.previewSize!.width,
                  child: Transform(
                    alignment: Alignment.center,
                    transform:
                        Matrix4.rotationY(math.pi), // Mematikan efek mirror
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            ),
          ),

          // Layer 2: Overlay Mask (Gelap di luar lingkaran)
          _buildOverlayMask(size),

          // Layer 3: UI Elements (Progress & Text)
          _buildUI(size),
        ],
      ),
    );
  }

  Widget _buildOverlayMask(Size size) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.2),
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
            alignment: Alignment.center,
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

  Widget _buildUI(Size size) {
    return Positioned(
      bottom: 80,
      left: 40,
      right: 40,
      child: Column(
        children: [
          Text(
            _statusMsg,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _registrationProgress,
              backgroundColor: Colors.white12,
              color: _registrationProgress > 0.7
                  ? Colors.greenAccent
                  : Colors.blueAccent,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${(_registrationProgress * 100).toInt()}% Selesai",
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
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

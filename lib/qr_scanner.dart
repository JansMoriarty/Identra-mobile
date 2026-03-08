import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:identra_mobile_flutter/services/api_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Pastikan sudah import ini
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final MobileScannerController controller = MobileScannerController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isProcessing = false;

  void _playBeep() async {
    await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
  }

  void _processSelection(String qrData) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    _playBeep();

    // Validasi format QR dari Laravel kamu
    if (qrData.startsWith("CLS-")) {
      setState(() => _isProcessing = true);

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 100);
      }

      controller.stop();
      _showSuccessSheet(qrData); // Kirim full data (CLS-EIXNKKP4GE)
    } else {
      // Kita panggil snackbar error (cek point 3 di bawah)
      _showErrorSnackBar("QR Code tidak valid!");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showFinalSuccess(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // User tidak bisa klik luar untuk tutup
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Animasi atau Static yang estetik
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Absensi Berhasil!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(221, 255, 255, 255),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Tutup Dialog
                      Navigator.pop(context, true);
                    },
                    child: const Text(
                      "Selesai",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessSheet(String classId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFF1F222E).withOpacity(0.85),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(40)),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle Bar
                Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 30),

                // Icon Animasi Sukses
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4E6AF3).withOpacity(0.2)),
                  child: const Icon(Icons.school_rounded,
                      color: Color(0xFF4E6AF3), size: 50),
                ),
                const SizedBox(height: 20),

                Text("Siap untuk Absen?",
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Kamu akan melakukan absensi untuk kelas:",
                    style: GoogleFonts.poppins(
                        color: Colors.white60, fontSize: 14)),

                // ID Kelas dari QR Laravel
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 15),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(15)),
                  child: Text(classId,
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF4E6AF3),
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ),

                const SizedBox(height: 20),

                // Tombol Konfirmasi
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Tampilkan loading dialog sederhana
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF4E6AF3))),
                      );

                      // Panggil API
                      final result = await ApiService().submitAbsensi(classId);

                      Navigator.pop(context); // Tutup Loading
                      Navigator.pop(context); // Tutup Bottom Sheet

                      if (result['success']) {
                        _showFinalSuccess(result['message']);
                      } else {
                        _showErrorSnackBar(result['message']);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E6AF3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text("Konfirmasi Kehadiran",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Batal",
                      style: GoogleFonts.poppins(color: Colors.white38)),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      controller.start(); // Hidupkan kamera lagi kalau batal
      setState(() => _isProcessing = false);
    });
  }

  Widget _buildGlassConfirmSheet(String data) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFF1F222E).withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: const Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFF4E6AF3), size: 60),
            const SizedBox(height: 15),
            Text("Konfirmasi Kehadiran",
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Kamu terdeteksi di kelas:",
                style:
                    GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
            Text(data.replaceAll("IDENTRA-", ""),
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 30),

            // Tombol Absen
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4E6AF3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // Tambahkan logic simpan ke database di sini
                },
                child: const Text("Absen Sekarang",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double scanAreaSize = 260.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. KAMERA AKTIF
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                // Ambil teks dari barcode
                final String? code = barcode.rawValue;

                if (code != null) {
                  debugPrint('Barcode found! $code');

                  // Panggil fungsi proses dengan variabel 'code' yang sudah ada isinya
                  _playBeep();
                  _processSelection(code);
                }
              }
            },
          ),

          // 2. OVERLAY GELAP (LUBANG TENGAH)
          _buildScannerOverlay(context, scanAreaSize),

          // 3. FRAME CORNERS (⌈ ⌉ Style)
          _buildCornerFrame(scanAreaSize),

          // 4. ANIMASI GARIS LASER
          _buildScanLine(scanAreaSize),

          // 5. TOMBOL KONTROL ATAS
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircularButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                Text(
                  "Scan QR Code",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildCircularButton(
                  icon: Icons.flash_on_rounded,
                  onTap: () => controller.toggleTorch(),
                ),
              ],
            ),
          ),

          // 6. INSTRUKSI BAWAH
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      "Posisikan QR Code di dalam kotak",
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerFrame(double size) {
    return Center(
      child: Container(
        width: size,
        height: size,
        child: CustomPaint(
          painter: ScannerFramePainter(),
        ),
      ),
    );
  }

  Widget _buildScanLine(double size) {
    return Center(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (size * _animationController.value) - (size / 2)),
            child: Container(
              width: size - 40,
              height: 2,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4E6AF3).withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
                gradient: const LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0xFF4E6AF3),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context, double size) {
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
              height: size,
              width: size,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30), // Lubang lebih smooth
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

// Custom Painter untuk membuat frame sudut ⌈ ⌉
class ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4E6AF3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    double cornerSize = 30;

    // Top Left ⌈
    path.moveTo(0, cornerSize);
    path.lineTo(0, 0);
    path.lineTo(cornerSize, 0);

    // Top Right ⌉
    path.moveTo(size.width - cornerSize, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, cornerSize);

    // Bottom Right ⌋
    path.moveTo(size.width, size.height - cornerSize);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - cornerSize, size.height);

    // Bottom Left ⌊
    path.moveTo(cornerSize, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height - cornerSize);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

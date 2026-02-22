import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk orientasi
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ===== CONFIG =====
class ApiConfig {
  static const String baseUrl =
      "https://spinningly-proscientific-renay.ngrok-free.dev";
  static String faceEndpoint = "$baseUrl/api/attendance/store-face";
}

final secureStorage = FlutterSecureStorage();

class SmartFaceScanner extends StatefulWidget {
  const SmartFaceScanner({super.key});

  @override
  State<SmartFaceScanner> createState() => _SmartFaceScannerState();
}

class _SmartFaceScannerState extends State<SmartFaceScanner>
    with SingleTickerProviderStateMixin {
  // Camera & AI
  CameraController? _controller;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  // State Flags
  bool _isCameraInitialized = false;
  bool _isProcessing = false; // Mencegah bottleneck deteksi
  bool _isFaceDetected = false; // Status wajah ditemukan
  bool _isUploading = false;
  CameraDescription? _cameraDescription;

  // Animation
  late AnimationController _animController;
  late Animation<double> _scanAnimation;
  late SharedPreferences _prefs;

  DateTime? _lastDetectionTime;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _initializeCamera();

    // Setup Animasi Garis Scanning
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    // Cari kamera depan
    _cameraDescription = cameras.firstWhere(
      (element) => element.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      _cameraDescription!,
      ResolutionPreset.low, // Pakai LOW dulu untuk memastikan deteksi jalan
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420, // WAJIB untuk Android
    );

    await _controller!.initialize();

    if (!mounted) return;

    // Mulai Stream Gambar untuk Deteksi Wajah
    _controller!.startImageStream(_processCameraImage);

    setState(() => _isCameraInitialized = true);
  }

  // ===== LOGIKA DETEKSI WAJAH =====
  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _isUploading) return;

    final now = DateTime.now();
    if (_lastDetectionTime != null &&
        now.difference(_lastDetectionTime!).inMilliseconds < 400) {
      return;
    }
    _lastDetectionTime = now;

    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        debugPrint("DEBUG: InputImage gagal dikonversi");
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      // INI PENTING: Untuk memastikan alat deteksinya hidup atau tidak
      debugPrint("DEBUG: Wajah ditemukan = ${faces.length}");

      if (faces.isNotEmpty) {
        if (!_isFaceDetected) setState(() => _isFaceDetected = true);
      } else {
        if (_isFaceDetected) setState(() => _isFaceDetected = false);
      }
    } catch (e) {
      debugPrint("DEBUG: Error deteksi ML Kit: $e");
    } finally {
      _isProcessing = false;
    }
  }

  // Uint8List _concatenatePlanes(List<Plane> planes) {
  //   final WriteBuffer allBytes = WriteBuffer();
  //   for (final Plane plane in planes) {
  //     allBytes.putUint8List(plane.bytes);
  //   }
  //   return allBytes.done().buffer.asUint8List();
  // }

  // ===== AMBIL FOTO & UPLOAD =====
  Future<void> _captureAndUpload() async {
    if (!_isFaceDetected) {
      _showSnackBar("Wajah tidak terdeteksi! Arahkan wajah ke kamera.",
          isError: true);
      return;
    }

    // Stop stream agar tidak crash saat capture
    await _controller!.stopImageStream();
    setState(() => _isUploading = true);

    try {
      final XFile image = await _controller!.takePicture();
      await _sendToBackend(image.path);
    } catch (e) {
      _showSnackBar("Gagal mengambil foto: $e", isError: true);
      // Restart stream jika gagal
      _controller!.startImageStream(_processCameraImage);
      setState(() => _isUploading = false);
    }
  }

  Future<void> _sendToBackend(String path) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? guruId = prefs.getString("guru_id");
      final String? token =
          prefs.getString("auth_token"); // Ambil token di sini

      if (guruId == null || token == null) {
        throw Exception("Sesi login tidak valid. Silakan login ulang.");
      }

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        followRedirects:
            false, // Kita set false agar kita tahu kalau ada error 302 lagi
        validateStatus: (status) => status! < 500,
      ));

      FormData formData = FormData.fromMap({
        "guru_id": guruId,
        "image": await MultipartFile.fromFile(path, filename: "face_scan.jpg"),
      });

      final response = await dio.post(
        ApiConfig.faceEndpoint,
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token', // WAJIB ADA
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      debugPrint(
          "DEBUG: Response Server (${response.statusCode}): ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("Data Wajah Berhasil Disimpan!");
        if (mounted) Navigator.pop(context);
      } else if (response.statusCode == 302) {
        _showSnackBar("Error 302: Endpoint redirect. Cek route Laravel kamu!",
            isError: true);
      } else {
        _showSnackBar(
            "Gagal: ${response.data['message'] ?? response.statusCode}",
            isError: true);
      }
    } catch (e) {
      debugPrint("DEBUG: Error Upload: $e");
      _showSnackBar("Upload Gagal: $e", isError: true);

      // Aktifkan kembali kamera jika gagal
      _controller!.startImageStream(_processCameraImage);
      setState(() => _isUploading = false);
    }
  }

  // ===== KONVERSI TEKNIS (Wajib untuk ML Kit) =====
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameraDescription;
    if (camera == null) return null;

    // 1. Logika Rotasi (Tetap seperti sebelumnya)
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation != null) {
        if (camera.lensDirection == CameraLensDirection.front) {
          rotationCompensation =
              (sensorOrientation + rotationCompensation) % 360;
        } else {
          rotationCompensation =
              (sensorOrientation - rotationCompensation + 360) % 360;
        }
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      }
    }
    rotation ??= InputImageRotation.rotation270deg;

    // 2. Gunakan cara yang benar untuk mengambil bytes
    // Kita ambil bytes dari plane pertama saja (Y plane) tapi format NV21
    // ATAU kirim semua bytes tapi dengan perhitungan yang pas.
    // Untuk Infinix, cara paling aman adalah mengirim semua plane secara FLAT:
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // 3. Metadata yang Sangat Spesifik
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat
            .nv21, // Gunakan NV21 untuk bytes gabungan di Android
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  // Map orientasi perangkat
  static final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    _faceDetector.close();
    _controller?.dispose();
    super.dispose();
  }

  // ===== UI BUILDER =====
  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()));
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    // Warna tema berdasarkan status deteksi
    final Color statusColor = _isFaceDetected
        ? const Color(0xFF00D1FF)
        : Colors.redAccent.withOpacity(0.8);
    final String statusText =
        _isFaceDetected ? "WAJAH TERDETEKSI" : "POSISIKAN WAJAH";

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview (Full Screen)
          CameraPreview(_controller!),

          // 2. Dark Overlay (Focus Area)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.8), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(
                    decoration: const BoxDecoration(
                        color: Colors.black,
                        backgroundBlendMode: BlendMode.dstOut)),
                Center(
                  child: Container(
                    height: 320,
                    width: 320,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ),
          ),

          // 3. Scanner UI Elements
          Center(
            child: SizedBox(
              height: 320,
              width: 320,
              child: Stack(
                children: [
                  // Corner Frame (Custom Painter)
                  CustomPaint(
                    painter: ScannerFramePainter(color: statusColor),
                    child: Container(),
                  ),

                  // Scanning Line Animation
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      if (_isUploading)
                        return const SizedBox(); // Hilangkan garis saat upload
                      return Positioned(
                        top: 320 * _scanAnimation.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                  color: statusColor,
                                  blurRadius: 10,
                                  spreadRadius: 1)
                            ],
                            color: statusColor,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 4. Status Text & Indicators
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isFaceDetected
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: statusColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: GoogleFonts.robotoMono(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 5. Action Button
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isUploading ? null : _captureAndUpload,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isUploading
                        ? Colors.white
                        : (_isFaceDetected
                            ? statusColor.withOpacity(0.2)
                            : Colors.transparent),
                    border: Border.all(
                        color: _isUploading
                            ? Colors.transparent
                            : (_isFaceDetected ? statusColor : Colors.grey),
                        width: 4),
                    boxShadow: _isFaceDetected
                        ? [
                            BoxShadow(
                                color: statusColor.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2)
                          ]
                        : [],
                  ),
                  child: Center(
                    child: _isUploading
                        ? const CircularProgressIndicator(strokeWidth: 3)
                        : Icon(
                            Icons.camera,
                            size: 32,
                            color: _isFaceDetected ? Colors.white : Colors.grey,
                          ),
                  ),
                ),
              ),
            ),
          ),

          // 6. Close Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== CUSTOM PAINTER UNTUK FRAME =====
class ScannerFramePainter extends CustomPainter {
  final Color color;
  ScannerFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double length = 40;

    // Kiri Atas
    canvas.drawPath(
        Path()
          ..moveTo(0, length)
          ..lineTo(0, 0)
          ..lineTo(length, 0),
        paint);
    // Kanan Atas
    canvas.drawPath(
        Path()
          ..moveTo(size.width - length, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, length),
        paint);
    // Kiri Bawah
    canvas.drawPath(
        Path()
          ..moveTo(0, size.height - length)
          ..lineTo(0, size.height)
          ..lineTo(length, size.height),
        paint);
    // Kanan Bawah
    canvas.drawPath(
        Path()
          ..moveTo(size.width - length, size.height)
          ..lineTo(size.width, size.height)
          ..lineTo(size.width, size.height - length),
        paint);
  }

  @override
  bool shouldRepaint(covariant ScannerFramePainter oldDelegate) =>
      oldDelegate.color != color;
}

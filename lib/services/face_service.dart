import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FaceService {
  static final FaceService _instance = FaceService._internal();
  factory FaceService() => _instance;
  FaceService._internal();

  Interpreter? _interpreter;
  late FaceDetector _faceDetector;

  Future<void> init() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
        ),
      );
      debugPrint("✅ ML Engine & Model Berhasil Dimuat");
    } catch (e) {
      debugPrint("❌ Gagal memuat engine: $e");
    }
  }

  Future<List<double>?> getEmbedding(File imageFile) async {
    if (_interpreter == null) return null;

    try {
      if (!await imageFile.exists()) return null;

      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) return null;

      Face face = faces.first;
      final bytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) return null;

      originalImage = img.bakeOrientation(originalImage);

      // Safe Cropping
      int x = face.boundingBox.left.toInt();
      int y = face.boundingBox.top.toInt();
      int w = face.boundingBox.width.toInt();
      int h = face.boundingBox.height.toInt();

      img.Image faceCrop = img.copyCrop(
        originalImage,
        x: x.clamp(0, originalImage.width),
        y: y.clamp(0, originalImage.height),
        width: w.clamp(0, originalImage.width - x.clamp(0, originalImage.width)),
        height: h.clamp(0, originalImage.height - y.clamp(0, originalImage.height)),
      );

      img.Image resizedFace = img.copyResize(faceCrop, width: 112, height: 112);

      // --- PERBAIKAN DIMENSI TENSOR ---
      // Kita buat List 4D [1, 112, 112, 3]
      var input = _imageToList(resizedFace);
      
      // Output placeholder [1, 192]
      var output = List.filled(1 * 192, 0.0).reshape([1, 192]);

      // Jalankan model
      _interpreter!.run(input, output);
      
      return List<double>.from(output[0]);
    } catch (e) {
      debugPrint("❌ Error processing face: $e");
      return null;
    }
  }

  // Fungsi helper baru untuk membuat format 4D yang diterima TFLite
  List<dynamic> _imageToList(img.Image image) {
    // Bentuk: [1, 112, 112, 3]
    var input = List.generate(
      1,
      (_) => List.generate(
        112,
        (y) => List.generate(
          112,
          (x) {
            final pixel = image.getPixel(x, y);
            return [
              (pixel.r - 128) / 128.0,
              (pixel.g - 128) / 128.0,
              (pixel.b - 128) / 128.0,
            ];
          },
        ),
      ),
    );
    return input;
  }

  void dispose() {
    _interpreter?.close();
    _faceDetector.close();
  }
}
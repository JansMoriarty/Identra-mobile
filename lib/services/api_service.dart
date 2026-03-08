import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Tambahkan ini

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://spinningly-proscientific-renay.ngrok-free.dev/api', 
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<Map<String, dynamic>> submitAbsensi(String classCode) async {
    try {
      // AMBIL TOKEN ASLI DARI STORAGE
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await _dio.post(
        '/class-attendance/scan', 
        data: {
          'class_code': classCode,
          // user_id tidak perlu dikirim jika Laravel mengambil via $request->user()->id
        },
        options: Options(headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', // GUNAKAN TOKEN ASLI DI SINI
        }),
      );

      return {
        'success': true,
        'message': response.data['message'],
        'data': response.data['data']
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? "Terjadi kesalahan pada server",
      };
    }
  }
}
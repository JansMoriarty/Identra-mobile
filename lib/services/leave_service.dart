import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LeaveService {
  // Ganti dengan URL API Laravel kamu
  static const String baseUrl =
      "https://spinningly-proscientific-renay.ngrok-free.dev/api";

  Future<bool> submitLeaveRequest({
    required String jenis,
    required String tanggalMulai,
    required String tanggalSelesai,
    required String alasan,
    File? image,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // --- SESUAIKAN DI SINI ---
      final String? token = prefs.getString('auth_token');
      final String? guruId = prefs.getString('guru_id');

      print("DEBUG: Token yang diambil: $token");
      print("DEBUG: Guru ID yang diambil: $guruId");

      if (token == null) {
        print("ERROR: Token null, user harus login ulang.");
        return false;
      }

      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/leave-request'));

      // Header wajib pakai Bearer $token
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning':
            'true', // Tambahkan ini agar ngrok tidak blokir request
      });

      // Form Data (String)
      request.fields['guru_id'] = guruId ?? '';
      request.fields['jenis'] = jenis; // sakit, izin, cuti
      request.fields['tanggal_mulai'] = tanggalMulai;
      request.fields['tanggal_selesai'] = tanggalSelesai;
      request.fields['alasan'] = alasan;

      // Lampiran Gambar (Jika ada)
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'lampiran_foto', // Harus sama dengan nama kolom di request Laravel
            image.path,
          ),
        );
      }
      // Di dalam file leave_service.dart
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 422) {
        // Ambil pesan error dari Laravel
        final data = jsonDecode(response.body);
        throw data['message'] ?? "Terjadi kesalahan validasi";
      } else {
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VoucherService {
  final String baseUrl =
      "https://spinningly-proscientific-renay.ngrok-free.dev/api"; // Sesuaikan URL

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getString('auth_token'); // Sesuai dengan key yang kita perbaiki tadi
  }

  // Ambil Katalog Voucher (Marketplace)
  Future<List<dynamic>> getVouchers() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/marketplace/vouchers"),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception("Gagal memuat katalog voucher");
    }
  }

  // Tambahkan ini di paling bawah class VoucherService
  Future<Map<String, dynamic>> getProfile() async {
    final token = await _getToken();
    try {
      final response = await http.get(
        // Sesuaikan dengan route di Laravel kamu tadi:
        Uri.parse("$baseUrl/profile/summary"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
          "Status Profile: ${response.statusCode}"); // Untuk mastiin di console

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Pastikan 'data' adalah key tempat points & rank berada
        return data['data'] ?? {};
      } else {
        print("Gagal ambil profile: ${response.body}");
        return {};
      }
    } catch (e) {
      print("Error Catch Profile: $e");
      return {};
    }
  }

  // Proses Tukar Poin (Redeem)
  Future<Map<String, dynamic>> redeemVoucher(int itemId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/marketplace/redeem"),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'item_id': itemId}),
    );

    print("Redeem Status: ${response.statusCode}");
    print("Redeem Body: ${response.body}"); // Cek error message di sini!

    return json.decode(response.body);
  }

  // Ambil Inventori Milik Saya (My Tokens)
  Future<List<dynamic>> getMyTokens() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/my-tokens"),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception("Gagal memuat inventori");
    }
  }

  Future<List<dynamic>> getMutationHistory() async {
    final token = await _getToken();

    try {
      final response = await http.get(
        // Sesuaikan URL endpoint ini dengan yang ada di api.php Laravel kamu
        Uri.parse("$baseUrl/point-history"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']; // Mengambil array history dari key 'data'
      } else {
        print("API Error History: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Exception History: $e");
      return [];
    }
  }
}

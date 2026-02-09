import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:identra_mobile_flutter/home.dart';
import 'package:identra_mobile_flutter/main_navigation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // --- TARUH DI SINI ---
  @override
  void initState() {
    super.initState();
    _checkExistingToken();
  }

  Future<void> _checkExistingToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }

  Future<void> _saveSession(String token, Map userData) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('auth_token', token);

    // Ambil data dari Map userData
    final String guruId = userData['guru_id']?.toString() ?? "";
    final String name = userData['nama'] ?? userData['name'] ?? "Guru";

    // --- TAMBAHKAN BARIS INI ---
    // Sesuaikan key 'jabatan' dengan nama field yang dikirim API kamu
    final String jabatan =
        userData['jabatan'] ?? userData['jabatan_aktif'] ?? "Guru";

    await prefs.setString('guru_id', guruId);
    await prefs.setString('user_name', name);
    await prefs.setString('jabatan_aktif', jabatan); // Simpan ke storage

    // Set default jam
    await prefs.setString('jam_masuk', "--:--");
    await prefs.setString('jam_pulang', "--:--");

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Email dan Password tidak boleh kosong", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final String apiUrl =
        "https://spinningly-proscientific-renay.ngrok-free.dev/api/guru/login";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final responseData = jsonDecode(response.body);
      print("JSON FULL DARI SERVER: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        // ✅ AMAN: Ambil data & token secara dinamis
        var dataPart = responseData['data'];
        String token = dataPart['token'] ?? "";

        var userData;
        // Cek apakah user ada di dalam 'user' atau langsung di 'data'
        if (dataPart['user'] != null) {
          userData = dataPart['user'];
        } else if (dataPart is List && dataPart.isNotEmpty) {
          userData = dataPart[0]; // Jika response berupa list seperti contohmu
        } else {
          userData = dataPart;
        }

        if (userData != null) {
          String teacherName = userData['nama'] ?? userData['name'] ?? "Guru";
          _showSuccess("Selamat datang, $teacherName!");

          await _saveSession(token, userData);
        } else {
          _showSnackBar("Data user tidak ditemukan", Colors.orange);
        }
      } else {
        _showSnackBar(
            responseData['message'] ?? "Login Gagal", Colors.redAccent);
      }
    } catch (e) {
      debugPrint("Login Error: $e");
      if (!mounted) return;
      _showSnackBar("Gagal terhubung ke server. Periksa koneksi.", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.greenAccent[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -50,
            child:
                _buildBackgroundGlow(const Color(0xFF4E6AF3).withOpacity(0.2)),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child:
                _buildBackgroundGlow(const Color(0xFF9747FF).withOpacity(0.15)),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4E6AF3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF4E6AF3).withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.fingerprint,
                          size: 40, color: Color(0xFF4E6AF3)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "IDENTRA",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Secure Attendance System",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF8E92A8),
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Card Login
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            controller: _emailController,
                            label: "Email Address",
                            icon: Icons.alternate_email_rounded,
                            hint: "name@company.com",
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: "Password",
                            icon: Icons.lock_open_rounded,
                            hint: "••••••••",
                            isPassword: true,
                            obscureText: !_isPasswordVisible,
                            onSuffixIconTap: () {
                              setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible);
                            },
                          ),
                          const SizedBox(height: 48),
                          GestureDetector(
                            onTap: _isLoading ? null : _handleLogin,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 55,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4E6AF3),
                                    Color(0xFF6B84FF)
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4E6AF3)
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        "SIGN IN",
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "Don't have an account? Contact Admin",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF5D6175),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ADDED HELPER WIDGETS ---

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBackgroundGlow(Color color) {
    return Container(
      height: 300,
      width: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onSuffixIconTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFFBDC2D8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
          cursorColor: const Color(0xFF4E6AF3),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF5D6175), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF4E6AF3), size: 22),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: const Color(0xFF5D6175),
                      size: 20,
                    ),
                    onPressed: onSuffixIconTap,
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFF4E6AF3), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

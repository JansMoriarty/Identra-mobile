import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pindahkan AppColors ke paling atas (di luar class) agar bisa diakses global di file ini
class AppColors {
  static const Color cardBg = Color(0xFF1F222E);
  static const Color primaryBlue = Color(0xFF4E6AF3);
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFF8E92A8);
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = "Guru";
  String _jabatanAktif = "Guru Tetap";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "Guru";
      _jabatanAktif = prefs.getString('jabatan_aktif') ?? "Guru Tetap";
    });
  }

  String _getInitials(String name) {
    List<String> names = name.split(" ");
    String initials = "";
    int numWords = names.length > 2 ? 2 : names.length;
    for (var i = 0; i < numWords; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0].toUpperCase();
      }
    }
    return initials.isEmpty ? "G" : initials;
  }

  Color _getAvatarColor(String name) {
    final List<Color> colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal
    ];
    return colors[name.length % colors.length];
  }

  Future<void> _handleLogout() async {
    // 1. Munculkan dialog konfirmasi (Opsional tapi sangat disarankan untuk UX)
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            title: const Text("Keluar", style: TextStyle(color: Colors.white)),
            content: const Text("Apakah Anda yakin ingin keluar?",
                style: TextStyle(color: AppColors.textGrey)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Ya, Keluar",
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // 2. Hapus data sesi (pilih clear() untuk semua atau remove() untuk kunci tertentu)
      await prefs.clear();

      // 3. Cek apakah widget masih "mounted" sebelum menggunakan context
      if (!mounted) return;

      // 4. Arahkan ke Login dan hapus semua history stack navigasi
      // Pastikan di main.dart kamu sudah mendaftarkan route '/login'
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (Route<dynamic> route) => false,
      );
    }
  }

  // PINDAHKAN ATAU PASTIKAN FUNGSI INI DI DALAM _ProfilePageState
  Widget _buildMenuTile(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryBlue),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: () {
          // Tambahkan aksi di sini nanti
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = _getAvatarColor(_userName);

    return Scaffold(
      // Menggunakan Scaffold background hitam agar transparan container terlihat bagus
      backgroundColor: Colors.black,
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
          child: Column(
            children: [
              const SizedBox(height: 60),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeColor.withOpacity(0.15),
                    border: Border.all(
                        color: themeColor.withOpacity(0.5), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(_userName),
                      style: GoogleFonts.poppins(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _jabatanAktif,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildMenuTile(Icons.person_outline, "Edit Profile"),
                      _buildMenuTile(Icons.lock_outline, "Ganti Password"),
                      _buildMenuTile(Icons.help_outline, "Pusat Bantuan"),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: ElevatedButton(
                          onPressed: _handleLogout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                            foregroundColor: Colors.redAccent,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                  color: Colors.redAccent, width: 1),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded),
                              SizedBox(width: 12),
                              Text("Keluar Aplikasi",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

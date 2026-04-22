import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:identra_mobile_flutter/voucher_page.dart';
import 'package:intl/date_symbol_data_local.dart'; 
// 1. Import FaceService kamu
import 'package:identra_mobile_flutter/services/face_service.dart'; 

import 'package:identra_mobile_flutter/face_auth_page.dart';
import 'package:identra_mobile_flutter/stats.dart';
import 'package:identra_mobile_flutter/face_register.dart';
import 'package:identra_mobile_flutter/home.dart';
import 'package:identra_mobile_flutter/main_navigation.dart';
import 'package:identra_mobile_flutter/login_page.dart';
import 'package:identra_mobile_flutter/performance_page.dart';

void main() async {
  // Wajib ada untuk operasi async sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Model AI (Wajib)
  // Ini agar file .tflite dimuat ke memori
  await FaceService().init();

  // Inisialisasi format tanggal Indonesia
  await initializeDateFormatting('id_ID', null);

  // Sembunyikan Navigasi & Status Bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Kunci layar ke Portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      // initialRoute sebaiknya ke Login atau Main, 
      // tapi kalau mau langsung tes FaceAuthPage sementara tidak apa-apa
      initialRoute: '/', 
      routes: {
        '/': (context) => const LoginPage(),
        '/login': (context) => const LoginPage(),
        '/main': (context) => const MainNavigation(),
        '/register-face': (context) => const FaceRegisterPage(),
        '/stats-penilaian': (context) => const PerformancePage(),
        '/stats-keseluruhan': (context) => const StatsScreen(),
        '/poin-dan-reward': (context) => const VoucherPage(),
        
      },
    );
  }
}
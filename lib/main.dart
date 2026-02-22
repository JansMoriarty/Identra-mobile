import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:identra_mobile_flutter/face_scanner_view.dart';
import 'package:identra_mobile_flutter/login_page.dart';
import 'package:identra_mobile_flutter/main_navigation.dart';

void main() {
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
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      // Gunakan initialRoute saja
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/login': (context) => const LoginPage(),
        '/main': (context) => const MainNavigation(),
        '/face-scanner': (context) => const SmartFaceScanner(),
      },
      // Properti 'home' dihapus karena sudah diwakili oleh '/' di routes
    );
  }
}
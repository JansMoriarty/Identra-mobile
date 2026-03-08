import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:identra_mobile_flutter/main_navigation.dart';
import 'package:identra_mobile_flutter/login_page.dart';

void main() async {
  // Inisialisasi binding untuk SystemChrome
  WidgetsFlutterBinding.ensureInitialized();

  // Sembunyikan Navigasi & Status Bar (Full Screen)
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
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      initialRoute: '/', // Ganti ke '/' jika ingin mulai dari Login
      routes: {
        '/': (context) => const LoginPage(),
        '/login': (context) => const LoginPage(),
        '/main': (context) => const MainNavigation(),
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RateItApp());
}

class RateItApp extends StatelessWidget {
  const RateItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RateIt 🎬',
      theme: ThemeData(
        useMaterial3: true,

        // 🎨 โทนสีหลัก: เหลืองทอง + ดำ
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD600),
          brightness: Brightness.dark,
        ),

        // 🖤 พื้นหลัง
        scaffoldBackgroundColor: const Color(0xFF0E0E0E),
        cardColor: const Color(0xFF1A1A1A),

        // ✍️ ฟอนต์
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),

        // ⭐ ไอคอนทั่วแอป
        iconTheme: const IconThemeData(
          color: Color(0xFFFFD600),
        ),

        // 📽️ AppBar - ดำ + เหลือง
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: const Color(0xFFFFD600),
          centerTitle: true,
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.6),
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD600),
          ),
          iconTheme: const IconThemeData(color: Color(0xFFFFD600)),
        ),

        // 🎬 BottomNavigationBar
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0E0E0E),
          selectedItemColor: Color(0xFFFFD600),
          unselectedItemColor: Colors.white54,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        ),

        // 🔘 ปุ่ม Action
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD600),
            foregroundColor: Colors.black,
            elevation: 6,
            shadowColor: Colors.yellow.withOpacity(0.5),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        // 🪩 Chip / Badge
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFFFD600).withOpacity(0.15),
          labelStyle: const TextStyle(color: Colors.white),
          selectedColor: const Color(0xFFFFD600),
          secondaryLabelStyle: const TextStyle(color: Colors.black),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      // ✅ เริ่มต้นที่หน้า Login
      home: const LoginPage(),
    );
  }
}

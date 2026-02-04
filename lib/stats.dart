import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color cardBg = Color(0xFF1F222E);
  static const Color primaryBlue = Color(0xFF4E6AF3);
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFF8E92A8);

  static const Color orangeBg = Color(0xFF3E2B25);
  static const Color orangeIcon = Color(0xFFFF9500);

  static const Color blueBg = Color(0xFF22314F);
  static const Color blueIcon = Color(0xFF4E6AF3);

  static const Color purpleBg = Color(0xFF2B2245);
  static const Color purpleIcon = Color(0xFF9747FF);

  static const Color redBg = Color(0xFF382229);
  static const Color redIcon = Color(0xFFFF3B30);
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StateStatsScreenState();
}

class _StateStatsScreenState extends State<StatsScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  final DateTime _focusedDay = DateTime.now();

  // Data Dummy
  final List<DateTime> _tepatWaktuDays = [
    DateTime(2026, 2, 2),
    DateTime(2026, 2, 3),
    DateTime(2026, 2, 4),
    DateTime(2026, 2, 9),
  ];
  final List<DateTime> _terlambatDays = [DateTime(2026, 2, 5)];
  final List<DateTime> _sakitDays = [
    DateTime(2026, 2, 6),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_main.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            // Memungkinkan seluruh halaman scroll vertikal
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCalendarCard(),
                const SizedBox(height: 32),
                _buildStatsHeader(),
                const SizedBox(height: 16),
                _buildStatsGrid(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F222E).withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.sunday, // Sun Mon Tue...
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              // 1. Kecilin margin header agar lebih mepet ke atas
              headerMargin: const EdgeInsets.only(bottom: 12),
              headerPadding: EdgeInsets.zero, // Nolkan padding default

              titleTextStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16, // 2. Font dikecilkan dari 18 ke 15
                color: Colors.white,
              ),

              // 3. Kecilin ukuran icon chevron agar seimbang dengan teks
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 20, // Ukuran dikecilkan
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 20, // Ukuran dikecilkan
              ),

              // Mengatur padding icon agar tidak terlalu lebar
              leftChevronMargin: EdgeInsets.zero,
              rightChevronMargin: EdgeInsets.zero,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
              weekendStyle: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              isTodayHighlighted: false, // Matikan agar tidak "melayang"
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildCustomDayTile(day,
                    isToday: isSameDay(day, DateTime.now()));
              },
              prioritizedBuilder: (context, day, focusedDay) {
                // Handle Sabtu dan Minggu
                if (day.weekday == DateTime.sunday ||
                    day.weekday == DateTime.saturday) {
                  return _buildCustomDayTile(day,
                      isWeekend: true, isToday: isSameDay(day, DateTime.now()));
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildCalendarLegend(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCustomDayTile(DateTime day,
      {bool isWeekend = false, bool isToday = false}) {
    Color? bgColor;
    bool hasConnection = false;

    if (_tepatWaktuDays.any((d) => isSameDay(d, day))) {
      bgColor = const Color(0xFF00C853);
      // Logika koneksi: jika hari besok juga "Tepat Waktu" dan bukan hari Sabtu (pindah baris)
      if (_tepatWaktuDays
              .any((d) => isSameDay(d, day.add(const Duration(days: 1)))) &&
          day.weekday != DateTime.saturday) {
        hasConnection = true;
      }
    } else if (_terlambatDays.any((d) => isSameDay(d, day))) {
      bgColor = const Color(0xFFFF9500);
    } else if (_sakitDays.any((d) => isSameDay(d, day))) {
      bgColor = const Color(0xFF9747FF);
    } else if (isToday) {
      bgColor = const Color(0xFF4E6AF3);
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // --- KONEKTOR GARIS (Sesuai Gambar) ---
        if (hasConnection)
          Positioned(
            // Geser mulai dari tengah lingkaran saat ini
            left: 17, 
            child: Container(
              width: 35, // Menjangkau ke tile berikutnya
              height: 3,  // Garis dibuat tipis (ramping) seperti di gambar
              // Warna solid tanpa opacity agar terlihat tegas menyambung
              color: bgColor, 
            ),
          ),
          
        // --- LINGKARAN TANGGAL ---
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: bgColor ?? Colors.transparent,
            shape: BoxShape.circle,
            // Opsional: tambah sedikit border jika ingin lebih tegas seperti di gambar
            border: bgColor != null ? Border.all(color: bgColor, width: 0.5) : null,
          ),
          child: Center(
            child: Text(
              '${day.day}'.padLeft(2, '0'),
              style: GoogleFonts.poppins(
                color: bgColor != null
                    ? Colors.white
                    : (isWeekend ? Colors.redAccent : Colors.white),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 18,
      children: [
        _legendItem(const Color(0xFF00C853), "Tepat Waktu"),
        _legendItem(const Color(0xFF4E6AF3), "Izin"),
        _legendItem(const Color(0xFF9747FF), "Sakit"),
        _legendItem(const Color(0xFFFF3B30), "Alpha"),
        _legendItem(const Color(0xFFFF9500), "Terlambat"),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildStatsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Your Stats",
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color.fromARGB(0, 31, 34, 46),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: const Row(
            children: [
              Text("Bulan ini",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildStatsGrid() {
    Widget statItem(
        String title, String count, Color baseColor, IconData icon) {
      return Container(
        decoration: BoxDecoration(
          color: baseColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: baseColor.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: baseColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white)),
                  Text(count,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.white70)),
                ],
              ),
            )
          ],
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // Grid tidak scroll sendiri
      crossAxisCount: 2,
      childAspectRatio: 2.1,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        statItem("Terlambat", "0 Hari", AppColors.orangeIcon,
            Icons.access_time_filled),
        statItem("Izin", "2 Hari", AppColors.blueIcon, Icons.description),
        statItem(
            "Sakit", "0 Hari", AppColors.purpleIcon, Icons.medical_services),
        statItem("Tanpa Ket", "0 Hari", AppColors.redIcon, Icons.cancel),
      ],
    );
  }
}

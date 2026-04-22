import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static const Color cardBg = Color(0xFF1F222E);
  static const Color primaryBlue = Color(0xFF4E6AF3);
  static const Color textGrey = Color(0xFF8E92A8);

  static const Color orangeIcon = Color(0xFFFF9500);
  static const Color blueIcon = Color(0xFF4E6AF3);
  static const Color purpleIcon = Color(0xFF9747FF);
  static const Color redIcon = Color(0xFFFF3B30);
  static const Color greenIcon = Color(0xFF00C853);
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  String? token;

  Map<String, dynamic> _summary = {
    'hadir': 0,
    'telat': 0,
    'izin': 0,
    'sakit': 0,
    'alpha': 0
  };
  Map<DateTime, String> _events = {};

  String _selectedPeriod = "Bulan Ini";
  final List<String> _periods = ["Bulan Ini", "Bulan Lalu", "3 Bulan Terakhir"];

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    if (mounted) {
      setState(() => token = savedToken);
      if (token != null) {
        _fetchStats();
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchStats() async {
    if (token == null) return;
    setState(() => _isLoading = true);

    DateTime start = DateTime(_focusedDay.year, _focusedDay.month, 1);
    DateTime end = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    if (_selectedPeriod == "Bulan Lalu") {
      start = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      end = DateTime(_focusedDay.year, _focusedDay.month, 0);
    }

    final String startStr = DateFormat('yyyy-MM-dd').format(start);
    final String endStr = DateFormat('yyyy-MM-dd').format(end);

    try {
      final response = await http.get(
        Uri.parse(
            "https://spinningly-proscientific-renay.ngrok-free.dev/api/attendance/stats?start=$startStr&end=$endStr"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> fullResponse = json.decode(response.body);
        final List calendar = fullResponse['calendar'] ?? [];
        Map<DateTime, String> newEvents = {};

        for (var item in calendar) {
          if (item != null && item['date'] != null) {
            DateTime date = DateTime.parse(item['date']);
            newEvents[DateTime(date.year, date.month, date.day)] =
                (item['status'] ?? 'hadir').toString().toLowerCase();
          }
        }

        final summaryData = fullResponse['summary'] ?? {};
        if (mounted) {
          setState(() {
            _summary = {
              'hadir': summaryData['hadir'] ?? 0,
              'telat': summaryData['telat'] ?? 0,
              'izin': summaryData['izin'] ?? 0,
              'sakit': summaryData['sakit'] ?? 0,
              'alpha': summaryData['alpha'] ?? 0,
            };
            _events = newEvents;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A), // Background lebih deep
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_main.png'),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryBlue))
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 1. Header Ringkasan (Paling Atas)
                    SliverToBoxAdapter(child: _buildHeaderSection()),

                    // 2. Kartu Kalender
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(child: _buildCalendarCard()),
                    ),

                    // 3. Header Detail & Filter
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      sliver: SliverToBoxAdapter(child: _buildStatsHeader()),
                    ),

                    // 4. Grid Detail Status
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverToBoxAdapter(child: _buildStatsGrid()),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    final int hadir = (_summary['hadir'] ?? 0).toInt();
    final int telat = (_summary['telat'] ?? 0).toInt();
    final int izin = (_summary['izin'] ?? 0).toInt();
    final int sakit = (_summary['sakit'] ?? 0).toInt();
    final int alpha = (_summary['alpha'] ?? 0).toInt();

    final int totalHadir = hadir + telat;
    final int totalDays = totalHadir + izin + sakit + alpha;

    final double percentage =
        totalDays == 0 ? 0 : (totalHadir / totalDays) * 100;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Statistik Presensi",
                  style:
                      GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
              Text("Ringkasan",
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Text("${percentage.toStringAsFixed(1)}%",
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                const SizedBox(width: 8),
                const Icon(Icons.auto_graph_rounded,
                    color: AppColors.primaryBlue, size: 20),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            rowHeight: 52,
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
                _fetchStats();
              });
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white),
              leftChevronIcon: _buildChevron(Icons.chevron_left),
              rightChevronIcon: _buildChevron(Icons.chevron_right),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle:
                  GoogleFonts.poppins(color: AppColors.textGrey, fontSize: 11),
              weekendStyle:
                  GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11),
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              isTodayHighlighted: false,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) =>
                  _buildCustomDayTile(day),
              prioritizedBuilder: (context, day, focusedDay) {
                if (day.weekday == DateTime.sunday ||
                    day.weekday == DateTime.saturday) {
                  return _buildCustomDayTile(day, isWeekend: true);
                }
                return null;
              },
            ),
          ),
          const Divider(color: Colors.white10, height: 32),
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  Widget _buildCustomDayTile(DateTime day, {bool isWeekend = false}) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final status = _events[normalizedDay];
    bool isToday = isSameDay(day, DateTime.now());
    Color? color;
    switch (status) {
      case 'hadir':
        color = AppColors.greenIcon;
        break;
      case 'telat':
        color = AppColors.orangeIcon;
        break;
      case 'sakit':
        color = AppColors.purpleIcon;
        break;
      case 'izin':
        color = AppColors.blueIcon;
        break;
      case 'alpha':
        color = AppColors.redIcon;
        break;
    }

    bool hasNext = status != null &&
        day.weekday != DateTime.saturday &&
        _events[normalizedDay.add(const Duration(days: 1))] == status;
    bool hasPrev = status != null &&
        day.weekday != DateTime.monday &&
        _events[normalizedDay.subtract(const Duration(days: 1))] == status;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (hasPrev && color != null)
          Positioned(left: -20, right: 19, child: _connectionLine(color)),
        if (hasNext && color != null)
          Positioned(left: 19, right: -20, child: _connectionLine(color)),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: color ??
                (isToday
                    ? AppColors.primaryBlue.withOpacity(0.2)
                    : Colors.transparent),
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  color ?? (isToday ? AppColors.primaryBlue : Colors.white10),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text('${day.day}',
                style: GoogleFonts.poppins(
                  color: isWeekend && color == null
                      ? Colors.redAccent
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                )),
          ),
        ),
      ],
    );
  }

  Widget _connectionLine(Color color) => Container(
        height: 2.5,
        decoration: BoxDecoration(color: color, boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)
        ]),
      );

  Widget _buildChevron(IconData icon) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white, size: 20),
      );

  Widget _buildStatsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Detail Status",
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        _buildDropdown(),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        // Pakai warna gradasi gelap agar dropdown terlihat "dalam" (inset)
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          borderRadius: BorderRadius.circular(20),
          dropdownColor: const Color(0xFF1A1D26), // Lebih gelap dari cardBg
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white54, size: 18),
          style: GoogleFonts.poppins(
              fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
          items: _periods
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) {
            setState(() {
              _selectedPeriod = v!;
              _fetchStats();
            });
          },
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2, // Lebih ramping
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _statItem("Terlambat", (_summary['telat'] ?? 0).toInt(),
            AppColors.orangeIcon, Icons.timer_rounded),
        _statItem("Izin", (_summary['izin'] ?? 0).toInt(), AppColors.blueIcon,
            Icons.mail_outline_rounded),
        _statItem("Sakit", (_summary['sakit'] ?? 0).toInt(),
            AppColors.purpleIcon, Icons.medication_rounded),
        _statItem("Alpha", (_summary['alpha'] ?? 0).toInt(), AppColors.redIcon,
            Icons.not_interested_rounded),
      ],
    );
  }

  Widget _statItem(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        // Background kartu: Campuran warna kategori (5%) + Hitam tipis
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.25), // Border lebih terlihat warnanya
          width: 1.2,
        ),
        // Tambahkan sedikit bayangan warna (glow) agar tidak flat
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        children: [
          // Lingkaran kecil di belakang icon agar lebih rapi
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$count",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _legendItem(AppColors.greenIcon, "Hadir"),
        _legendItem(AppColors.orangeIcon, "Telat"),
        _legendItem(AppColors.blueIcon, "Izin"),
        _legendItem(AppColors.purpleIcon, "Sakit"),
        _legendItem(AppColors.redIcon, "Alpha"),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white60)),
      ],
    );
  }
}

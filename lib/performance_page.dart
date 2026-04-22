import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/performance_model.dart'; // Pastikan file model sudah ada
import 'package:shared_preferences/shared_preferences.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  // PERBAIKAN: Menghilangkan 'late' untuk menghindari LateInitializationError saat Hot Reload
  Future<AssessmentResponse>? _futureData;
  int selectedHistoryIndex = -1;

  @override
  void initState() {
    super.initState();
    // Inisialisasi future saat pertama kali aplikasi dijalankan
    _futureData = fetchData();
  }

  Future<AssessmentResponse> fetchData() async {
    try {
      // 1. Ambil token dari SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      // 2. Cek apakah token ada
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.get(
        Uri.parse(
            'https://spinningly-proscientific-renay.ngrok-free.dev/api/my-performance'),
        headers: {
          // 3. Masukkan token ke Header Authorization
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning':
              'true', // Tambahkan ini jika pakai Ngrok gratisan
        },
      );

      print("DEBUG PERFORMANCE: Status Code ${response.statusCode}");

      if (response.statusCode == 200) {
        return AssessmentResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Sesi telah berakhir. Silakan login ulang.');
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Performance Error: $e");
      throw Exception('Gagal memuat data: $e');
    }
  }

  String _getAkreditasi(String avgScoreStr) {
    double score = double.tryParse(avgScoreStr) ?? 0;
    if (score >= 4.0) return 'Akreditasi A';
    if (score >= 3.0) return 'Akreditasi B';
    return 'Akreditasi C';
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF131722);
    const cardColor = Color(0xFF1D2333);
    const primaryBlue = Color(0xFF4B61FF);
    const textSecondary = Color(0xFFA0A5B5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Performance Stats",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: FutureBuilder<AssessmentResponse>(
        future: _futureData,
        builder: (context, snapshot) {
          // State Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: primaryBlue));
          }

          // State Error
          else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            );
          }

          // State Data Berhasil Dimuat
          else if (snapshot.hasData) {
            final apiData = snapshot.data!;

            String displayScore;
            String displayPeriod;

            if (selectedHistoryIndex == -1) {
              displayScore = apiData.current.avg.toString();
              displayPeriod = "Periode Terbaru";
            } else {
              displayScore =
                  apiData.history[selectedHistoryIndex].score.toString();
              displayPeriod = apiData.history[selectedHistoryIndex].period;
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(cardColor, displayScore, apiData.profile),
                    const SizedBox(height: 24),
                    _buildBarChartCard(
                        primaryBlue, apiData.current.radar, displayPeriod),
                    const SizedBox(height: 30),
                    _buildSectionHeader(primaryBlue),
                    const SizedBox(height: 20),
                    _buildTimeline(
                        cardColor, primaryBlue, textSecondary, apiData.history),
                  ],
                ),
              ),
            );
          }

          return const Center(
              child: Text("Data tidak tersedia",
                  style: TextStyle(color: Colors.white)));
        },
      ),
    );
  }

  // --- Widget Components (UI di bawah ini tetap sama persis) ---

  Widget _buildSectionHeader(Color primaryBlue) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
              color: primaryBlue, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        const Text("Assessment History",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ],
    );
  }

  Widget _buildProfileCard(
      Color cardColor, String currentAvg, Profile profile) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardColor.withOpacity(0.8), cardColor.withOpacity(0.4)],
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4B61FF).withOpacity(0.1)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color.fromARGB(48, 75, 96, 255), width: 2),
                    color: const Color.fromARGB(173, 35, 43, 66),
                  ),
                  alignment: Alignment.center,
                  child: Text(profile.initial,
                      style: const TextStyle(
                          color: Color.fromARGB(255, 46, 86, 244),
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(profile.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildBadge("Guru PPLG", const Color(0xFF0D2D26),
                              const Color(0xFF1EB972)),
                          const SizedBox(width: 8),
                          _buildBadge(
                              _getAkreditasi(currentAvg),
                              const Color(0xFF4B61FF).withOpacity(0.2),
                              const Color(0xFF4B61FF)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(
              color: textCol, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildBarChartCard(
      Color primaryBlue, List<RadarData> scores, String period) {
    return Container(
      width: double.infinity,
      height: 280, // Sedikit lebih tinggi untuk kenyamanan visual
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue,
            primaryBlue
                .withBlue(255)
                .withOpacity(0.8), // Efek gradasi warna biru
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Analisis Kompetensi",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    period,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              // Tambahkan Icon Chart agar lebih hidup
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: scores.map<Widget>((item) {
                double scoreValue = item.score.toDouble();
                // Animasi bar yang lebih smooth
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Angka skor dengan container bulat kecil
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        scoreValue.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Bar dengan gradasi putih ke transparan
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Background bar (Shadow bar)
                        Container(
                          width: 20,
                          height: 114,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        // Active Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutBack, // Efek membal saat naik
                          width: 14,
                          height: 110 * (scoreValue / 5.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.white, Colors.white70],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              // BoxShadow(
                              //   color: Colors.white.withOpacity(0.4),
                              //   blurRadius: 8,
                              // )
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Label subjek
                    Text(
                      item.subject.length > 4
                          ? item.subject.substring(0, 4).toUpperCase()
                          : item.subject.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Color cardColor, Color primaryBlue, Color textSecondary,
      List<History> history) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        bool isSelected = selectedHistoryIndex == index;
        bool isLast = index == history.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        margin: const EdgeInsets.only(top: 24),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isSelected ? primaryBlue : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryBlue, width: 2.5),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: CustomPaint(
                            painter: DashedLinePainter(color: primaryBlue)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedHistoryIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cardColor.withOpacity(0.8)
                          : cardColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: isSelected
                              ? primaryBlue.withOpacity(0.4)
                              : Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(history[index].period,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF1EB972).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(history[index].score.toString(),
                                  style: const TextStyle(
                                      color: Color(0xFF1EB972),
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(history[index].feedback,
                            style: TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                                height: 1.5)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 14,
                                color: textSecondary.withOpacity(0.6)),
                            const SizedBox(width: 6),
                            Text(
                                "${history[index].evaluator}  •  ${history[index].date}",
                                style: TextStyle(
                                    color: textSecondary.withOpacity(0.6),
                                    fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Painter tetap sama
class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 4, startY = 8;
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1.5;
    while (startY < size.height - 8) {
      canvas.drawLine(Offset(size.width / 2, startY),
          Offset(size.width / 2, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

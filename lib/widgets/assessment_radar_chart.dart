import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AssessmentRadarChart extends StatelessWidget {
  final List<dynamic> data;

  const AssessmentRadarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: RadarChart(
        swapAnimationDuration: const Duration(milliseconds: 500), // Animasi saat data berubah
        swapAnimationCurve: Curves.easeInOutCubic,
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: Colors.white.withOpacity(0.2),
              borderColor: Colors.cyanAccent,
              entryRadius: 3,
              dataEntries: data
                  .map((e) => RadarEntry(value: e['score'].toDouble()))
                  .toList(),
              borderWidth: 2,
            ),
          ],
          radarShape: RadarShape.circle,
          tickCount: 5,
          getTitle: (index, angle) {
            return RadarChartTitle(
              text: data[index]['subject'],
              angle: angle,
            );
          },
          titleTextStyle: const TextStyle(color: Colors.white70, fontSize: 10),
          tickBorderData: const BorderSide(color: Colors.white10, width: 0.5),
          gridBorderData: const BorderSide(color: Colors.white24, width: 0.5),
        ),
      ),
    );
  }
}
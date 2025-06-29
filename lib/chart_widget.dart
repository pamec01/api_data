import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

class CryptoChartWidget extends StatelessWidget {
  final List<FlSpot> priceSpots;
  final List<String> timeLabels;
  final ScreenshotController screenshotController;

  const CryptoChartWidget({
    super.key,
    required this.priceSpots,
    required this.timeLabels,
    required this.screenshotController,
  });

  @override
  Widget build(BuildContext context) {
    if (priceSpots.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Screenshot(
      controller: screenshotController,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final index = touchedSpot.x.toInt();
                  final date = (index >= 0 && index < timeLabels.length)
                      ? timeLabels[index]
                      : '';
                  final value = NumberFormat.currency(
                    locale: 'en_US',
                    symbol: '\$',
                    decimalDigits: 0,
                  ).format(touchedSpot.y);

                  return LineTooltipItem(
                    '$date – $value',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (priceSpots.length / 6).floorToDouble(),
                getTitlesWidget: (value, _) {
                  int index = value.toInt();
                  if (index >= 0 && index < timeLabels.length) {
                    return Text(timeLabels[index], style: const TextStyle(fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, _) => Text(
                  NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0).format(value),
                  style: const TextStyle(fontSize: 11, overflow: TextOverflow.visible),
                  softWrap: false,
                ),
              ),
            ),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: priceSpots,
              isCurved: true,
              color: Colors.orange,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

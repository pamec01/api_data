import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Krypto Graf',
      themeMode: _themeMode,
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFF0F0F0),
        brightness: Brightness.light,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        brightness: Brightness.dark,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
      home: CryptoChartPage(onToggleTheme: _toggleTheme),
    );
  }
}

class CryptoChartPage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const CryptoChartPage({required this.onToggleTheme});

  @override
  State<CryptoChartPage> createState() => _CryptoChartPageState();
}

class _CryptoChartPageState extends State<CryptoChartPage> {
  List<FlSpot> priceSpots = [];
  List<String> timeLabels = [];
  Timer? timer;
  ScreenshotController screenshotController = ScreenshotController();

  DateTimeRange dateRange = DateTimeRange(
    start: DateTime.now().subtract(Duration(days: 7)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    fetchCryptoData();
    timer = Timer.periodic(Duration(seconds: 60), (_) => fetchCryptoData());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchCryptoData() async {
    final response = await http.get(Uri.parse(
        'https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=usd&days=30'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prices = data['prices'] as List;

      final filtered = prices.where((e) {
        final time = DateTime.fromMillisecondsSinceEpoch(e[0]);
        return time.isAfter(dateRange.start) && time.isBefore(dateRange.end);
      }).toList();

      setState(() {
        priceSpots = filtered
            .asMap()
            .entries
            .map((e) =>
                FlSpot(e.key.toDouble(), (e.value[1] as num).toDouble()))
            .toList();

        timeLabels = filtered
            .map((e) => DateFormat('dd/MM').format(
                DateTime.fromMillisecondsSinceEpoch(e[0])))
            .toList();
      });
    }
  }

  Future<void> _saveChartAsImage() async {
    final image = await screenshotController.capture();
    if (image != null) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/graf.png');
      await file.writeAsBytes(image);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Graf byl uložen do: ${file.path}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vývoj ceny Bitcoinu'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            tooltip: 'Přepnout světlo/tma',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(Duration(days: 30)),
                      lastDate: DateTime.now(),
                      initialDateRange: dateRange,
                    );
                    if (picked != null) {
                      setState(() {
                        dateRange = picked;
                      });
                      await fetchCryptoData();
                    }
                  },
                  child: Text("Vybrat období"),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _saveChartAsImage,
                  child: Text("Uložit jako PNG"),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("Od: ${DateFormat('dd.MM.yyyy').format(dateRange.start)}"),
                SizedBox(width: 8),
                Text("Do: ${DateFormat('dd.MM.yyyy').format(dateRange.end)}"),
              ],
            ),
            SizedBox(height: 20),

            Expanded(
              child: priceSpots.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : Screenshot(
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
                                  final date = index >= 0 && index < timeLabels.length
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
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: (priceSpots.length / 6).floorToDouble(),
                                getTitlesWidget: (value, _) {
                                  int index = value.toInt();
                                  if (index >= 0 && index < timeLabels.length) {
                                    return Text(
                                      timeLabels[index],
                                      style: TextStyle(fontSize: 10),
                                    );
                                  }
                                  return Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, _) => Text(
                                  NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0).format(value),
                                  style: TextStyle(
                                    fontSize: 11,
                                    overflow: TextOverflow.visible,
                                  ),
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
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

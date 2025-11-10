// chart.dart

// ignore_for_file: unused_field, must_be_immutable, use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_application/data/model/add_date.dart';
import 'package:flutter_application/data/utility.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class Chart extends StatefulWidget {
  int indexx;
  Chart({Key? key, required this.indexx}) : super(key: key);

  @override
  State<Chart> createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  final Box userBox = Hive.box('userBox');

  // --- THEME COLORS ---
  // Dark Theme Colors
  static const Color primaryDark = Color(0xFF0D1829);
  static const Color cardDark = Color(0xFF1B2C42);
  static const Color amberHighlight = Color(0xFFE5B80B);
  static const Color secondaryTextDark = Colors.white70;
  static const Color mainTextDark = Colors.white;

  // Light Theme Colors
  static const Color primaryLight = Color(0xFF1E5033);
  static const Color cardLight = Colors.white;
  // CHANGED: Updated the light theme accent color to a darker green as requested.
  static const Color primaryAccent = Color(0xFF3F8C25); // <--- NEW DARK GREEN CHART LINE COLOR
  static const Color mainTextLight = Colors.black;
  static const Color secondaryTextLight = Colors.black54;

  static const double cardRadius = 14.0;
  static const double padding = 18.0;
  // ----------------------

  List<Add_data> a = [];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: userBox.listenable(keys: ['darkMode']),
      builder: (context, box, child) {
        final bool darkMode = userBox.get('darkMode', defaultValue: false);

        // Dynamic Colors for Chart
        final Color cardBg = darkMode ? cardDark : cardLight;
        final Color accentColor = darkMode ? amberHighlight : primaryAccent;
        final Color primaryTextColor = darkMode ? mainTextDark : mainTextLight;
        final Color secondaryTextColor = darkMode ? secondaryTextDark : secondaryTextLight;

        // **FIX: The chart line color is set to the ACCENT color.**
        final Color chartLineColor = accentColor; 
        final Color shadowColor = darkMode ? Colors.black.withOpacity(0.4) : Colors.grey.withOpacity(0.2);

        // Fetch data based on index (existing logic)
        switch (widget.indexx) {
          case 0:
            a = today();
            break;
          case 1:
            a = week();
            break;
          case 2:
            a = month();
            break;
          case 3:
            a = year();
            break;
        }

        // Determine period type for aggregation (existing logic)
        String period;
        switch (widget.indexx) {
          case 0: period = 'day'; break;
          case 1: period = 'week'; break;
          case 2: period = 'month'; break;
          case 3: period = 'year'; break;
          default: period = 'day';
        }

        List<SalesData> salesList = aggregateData(a, period);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: padding),
          child: Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cardRadius),
              color: cardBg,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8.0),
            child: SfCartesianChart( 
              plotAreaBackgroundColor: Colors.transparent, 
              
              primaryXAxis: CategoryAxis(
                labelRotation: -45,
                majorGridLines: const MajorGridLines(width: 0),
                majorTickLines: MajorTickLines(color: secondaryTextColor),
                axisLine: AxisLine(color: secondaryTextColor),
                labelStyle: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(color: secondaryTextColor.withOpacity(0.2)),
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(width: 0),
                labelStyle: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                builder: (data, point, series, pointIndex, seriesIndex) {
                  final SalesData salesData = data as SalesData;
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(8),
                      // Tooltip border uses the chart/accent color
                      border: Border.all(color: chartLineColor, width: 1), 
                    ),
                    child: Text(
                      '${salesData.period}: ₹${NumberFormat('#,##0').format(salesData.amount)}',
                      style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600),
                    ),
                  );
                }
              ),
              series: <SplineSeries<SalesData, String>>[
                SplineSeries<SalesData, String>( 
                  // **CRITICAL FIX: Uses the dynamic chartLineColor**
                  color: chartLineColor, 
                  width: 3,
                  dataSource: salesList,
                  xValueMapper: (SalesData sales, _) => sales.period,
                  yValueMapper: (SalesData sales, _) => sales.amount,
                  name: 'Net Income',
                  // Marker color also uses chartLineColor
                  markerSettings: MarkerSettings(isVisible: true, color: chartLineColor, borderColor: cardBg, borderWidth: 2),
                  enableTooltip: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // AGGREGATE DATA (No changes needed here)
  List<SalesData> aggregateData(List<Add_data> data, String period) {
    Map<String, int> grouped = {};
    DateTime now = DateTime.now();

    if (period == 'week') {
      for (int i = 6; i >= 0; i--) {
        DateTime day = now.subtract(Duration(days: i));
        String key = DateFormat('d/MM').format(day);
        grouped[key] = 0;
      }
    } else if (period == 'month') {
      int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        String key = DateFormat('d/MM').format(DateTime(now.year, now.month, i));
        grouped[key] = 0;
      }
    } else if (period == 'year') {
      for (int i = 1; i <= 12; i++) {
        String key = DateFormat('MMM').format(DateTime(now.year, i, 1));
        grouped[key] = 0;
      }
    } else {
      String key = DateFormat('d/MM').format(now);
      grouped[key] = 0;
    }

    for (var item in data) {
      String key;
      if (period == 'year') {
        key = DateFormat('MMM').format(item.datetime);
      } else {
        key = DateFormat('d/MM').format(item.datetime);
      }

      if (grouped.containsKey(key)) {
        int amount = int.tryParse(item.amount) ?? 0;
        grouped[key] =
            grouped[key]! + (item.IN == 'Income' ? amount : -amount);
      }
    }

    List<SalesData> sales = grouped.entries
        .map((e) => SalesData(e.key, e.value))
        .toList();

    return sales;
  }
}

class SalesData {
  final String period;
  final int amount;
  SalesData(this.period, this.amount);
}
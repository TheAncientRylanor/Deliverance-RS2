import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatisticsLineChart extends StatelessWidget {
  final Map<int, int>? reportsByDay;
  final double maxX;
  final double maxY;
  final String fullMonthName;
  const StatisticsLineChart({
    super.key,
    required this.reportsByDay,
    required this.maxX,
    this.maxY = 40,
    required this.fullMonthName,
  });

  List<FlSpot> get _dailySpots => [
    for (var day = 1; day <= maxX; day++)
      FlSpot(day.toDouble(), (reportsByDay?[day] ?? 0).toDouble()),
  ];

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.primary),
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: EdgeInsets.all(20.0),
      height: 500,
      child: LineChart(
        key: ValueKey(maxX),
        LineChartData(
          backgroundColor: theme.colorScheme.surfaceContainer,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            getDrawingHorizontalLine: (value) =>
                FlLine(color: theme.colorScheme.primary, strokeWidth: 1),
            drawVerticalLine: false,
          ),
          minX: 1,
          maxX: maxX,
          minY: 0,
          maxY: maxY,
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 24),
              axisNameWidget: Text(
                "Reports",
                style: theme.textTheme.headlineSmall,
              ),
              axisNameSize: 32,
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: Text(
                "Days ($fullMonthName)",
                style: theme.textTheme.headlineSmall,
              ),
              axisNameSize: 32,
              sideTitles: SideTitles(showTitles: true, reservedSize: 24),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              curveSmoothness: 0.5,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: <Color>[
                    Color.fromRGBO(255, 179, 0, 1),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.5, 1.0],
                ),
              ),
              color: theme.colorScheme.primary,
              spots: _dailySpots,
            ),
          ],
        ),
      ),
    );
  }
}

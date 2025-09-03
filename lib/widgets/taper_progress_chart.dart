import 'package:decaf/constants/colors.dart';
import 'package:decaf/models/taper_plan.dart';
import 'package:decaf/providers/events_provider.dart';
import 'package:decaf/utils/taper_calculator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaperProgressChart extends StatelessWidget {
  final TaperPlan plan;
  final List<Event> events;

  const TaperProgressChart({
    super.key,
    required this.plan,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final plannedData = _generatePlannedData();
    final actualData = _generateActualData();
    
    if (plannedData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No chart data available')),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Chart',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem('Planned', Colors.grey[600]!, true), // dashed
                const SizedBox(width: 16),
                _buildLegendItem('Actual', AppColors.caffeine, false), // solid
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.3),
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: _leftTitleWidget,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: _bottomTitleWidget,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  lineBarsData: [
                    // Planned line (dashed)
                    LineChartBarData(
                      spots: plannedData,
                      isCurved: false,
                      color: Colors.grey[600]!,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      dashArray: [8, 4], // Creates dashed line
                    ),
                    // Actual line (solid)
                    LineChartBarData(
                      spots: actualData,
                      isCurved: false,
                      color: AppColors.caffeine,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  minY: 0,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => Colors.black87,
                      getTooltipItems: (touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final date = _getDateFromX(barSpot.x);
                          final isPlanned = barSpot.barIndex == 0;
                          return LineTooltipItem(
                            '${DateFormat('MMM d').format(date)}\n${isPlanned ? 'Planned' : 'Actual'}: ${barSpot.y.toStringAsFixed(0)}mg',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDashed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            border: isDashed ? Border.all(color: color, width: 0) : null,
          ),
          child: isDashed
              ? CustomPaint(
                  painter: DashedLinePainter(color: color),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  List<FlSpot> _generatePlannedData() {
    final schedule = TaperCalculator.generateFullSchedule(plan);
    final sortedDates = schedule.keys.toList()..sort();
    
    return sortedDates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final target = schedule[date] ?? 0;
      return FlSpot(index.toDouble(), target);
    }).toList();
  }

  List<FlSpot> _generateActualData() {
    final schedule = TaperCalculator.generateFullSchedule(plan);
    final sortedDates = schedule.keys.toList()..sort();
    final today = DateTime.now();
    
    return sortedDates.asMap().entries.where((entry) {
      final date = entry.value;
      // Only include actual data for dates up to today
      return date.isBefore(today) || _isSameDay(date, today);
    }).map((entry) {
      final index = entry.key;
      final date = entry.value;
      final actual = _getActualCaffeineForDay(date);
      return FlSpot(index.toDouble(), actual);
    }).toList();
  }

  double _getActualCaffeineForDay(DateTime date) {
    final dayEvents = events.where((event) {
      if (event.type != EventType.caffeine) return false;
      final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
      return _isSameDay(eventDate, date);
    });
    
    return dayEvents.fold(0.0, (sum, event) => sum + event.value);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }


  DateTime _getDateFromX(double x) {
    final schedule = TaperCalculator.generateFullSchedule(plan);
    final sortedDates = schedule.keys.toList()..sort();
    final index = x.round();
    return index < sortedDates.length ? sortedDates[index] : DateTime.now();
  }

  Widget _leftTitleWidget(double value, TitleMeta meta) {
    if (value % 100 != 0) {
      return Container();
    }
    
    return SideTitleWidget(
      meta: meta,
      child: Text(
        '${value.toInt()}mg',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _bottomTitleWidget(double value, TitleMeta meta) {
    final schedule = TaperCalculator.generateFullSchedule(plan);
    final sortedDates = schedule.keys.toList()..sort();
    final index = value.toInt();
    
    if (index < 0 || index >= sortedDates.length) {
      return Container();
    }
    
    final date = sortedDates[index];
    final totalDays = sortedDates.length;
    
    // Show dates at start, middle, and end
    if (index == 0 || index == totalDays ~/ 2 || index == totalDays - 1) {
      return SideTitleWidget(
        meta: meta,
        child: Text(
          DateFormat('MMM d').format(date),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
      );
    }
    
    return Container();
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
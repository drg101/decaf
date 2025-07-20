import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/events_provider.dart';

class ChartsPage extends ConsumerWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charts'),
      ),
      body: eventsAsync.when(
        data: (events) {
          final dailyData = <DateTime, Map<String, dynamic>>{};

          for (var event in events) {
            final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
            final day = DateTime(eventDate.year, eventDate.month, eventDate.day);

            dailyData.putIfAbsent(day, () => {'caffeine': 0.0});

            if (event.type == EventType.caffeine) {
              dailyData[day]!['caffeine'] =
                  (dailyData[day]!['caffeine'] ?? 0) + event.value;
            } else {
              final symptomName = event.type.name;
              dailyData[day]!.putIfAbsent(symptomName, () => []);
              (dailyData[day]![symptomName] as List).add(event.value);
            }
          }

          final sortedDays = dailyData.keys.toList()..sort();

          if (sortedDays.isEmpty) {
            return const Center(
              child: Text("Log some data to see the charts."),
            );
          }

          final barGroups = <BarChartGroupData>[];
          final lineBarsData = <LineChartBarData>[];

          final symptomColors = {
            'headache': Colors.red,
            'brainFog': Colors.purple,
            'anxiety': Colors.orange,
            'fatigue': Colors.blue,
          };

          double maxCaffeine = 0;
          for (var day in sortedDays) {
            final caffeineTotal = dailyData[day]!['caffeine'] as double;
            if (caffeineTotal > maxCaffeine) {
              maxCaffeine = caffeineTotal;
            }
          }

          for (var symptom in symptomColors.keys) {
            final spots = <FlSpot>[];
            for (var i = 0; i < sortedDays.length; i++) {
              final day = sortedDays[i];
              final values = dailyData[day]![symptom] as List?;
              if (values != null && values.isNotEmpty) {
                final avg = values.reduce((a, b) => a + b) / values.length;
                spots.add(FlSpot(i.toDouble(), avg));
              }
            }
            lineBarsData.add(
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: symptomColors[symptom],
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            );
          }

          for (var i = 0; i < sortedDays.length; i++) {
            final day = sortedDays[i];
            final caffeineTotal = dailyData[day]!['caffeine'] as double;
            barGroups.add(
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: caffeineTotal,
                    color: Colors.grey.shade300,
                    width: 16,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      BarChart(
                        BarChartData(
                          barGroups: barGroups,
                          maxY: maxCaffeine,
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                getTitlesWidget: (value, meta) {
                                  return Text('${value.toInt()} mg');
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 24,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < sortedDays.length) {
                                    return Text(DateFormat.E().format(sortedDays[index]));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                      LineChart(
                        LineChartData(
                          lineBarsData: lineBarsData,
                          minY: 0,
                          maxY: 5,
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  return Text(value.toInt().toString());
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  children: symptomColors.entries.map((entry) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          color: entry.value,
                        ),
                        const SizedBox(width: 5),
                        Text(entry.key),
                      ],
                    );
                  }).toList(),
                )
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

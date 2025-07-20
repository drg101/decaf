import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/date_provider.dart';
import '../providers/events_provider.dart';

class DailyCaffeineChart extends ConsumerWidget {
  const DailyCaffeineChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return eventsAsync.when(
      data: (events) {
        final caffeineEvents =
            events.where((e) => e.type == EventType.caffeine).toList();

        final dailyTotals = <DateTime, double>{};
        for (var event in caffeineEvents) {
          final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
          final day =
              DateTime(eventDate.year, eventDate.month, eventDate.day);
          dailyTotals.update(day, (value) => value + event.value,
              ifAbsent: () => event.value);
        }

        if (dailyTotals.isEmpty) {
          return const SizedBox(
            height: 150,
            child: Center(
              child: Text("Log your first coffee to see the chart."),
            ),
          );
        }

        final sortedDays = dailyTotals.keys.toList()..sort();

        final barGroups = <BarChartGroupData>[];
        for (var i = 0; i < sortedDays.length; i++) {
          final day = sortedDays[i];
          final total = dailyTotals[day]!;
          final isSelected = day.year == selectedDate.year &&
              day.month == selectedDate.month &&
              day.day == selectedDate.day;

          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: total,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 150,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedDays.length) {
                          final day = sortedDays[index];
                          return Text(DateFormat.E().format(day));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = sortedDays[group.x.toInt()];
                      final total = rod.toY;
                      return BarTooltipItem(
                        '${DateFormat.yMMMd().format(day)}\n${total.toStringAsFixed(0)} mg',
                        TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (response != null &&
                        response.spot != null &&
                        event is FlTapUpEvent) {
                      final index = response.spot!.touchedBarGroupIndex;
                      ref.read(selectedDateProvider.notifier).state =
                          sortedDays[index];
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(
          height: 150, child: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          SizedBox(height: 150, child: Center(child: Text('Error: $err'))),
    );
  }
}
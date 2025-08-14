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
          final eventDate = DateTime.fromMillisecondsSinceEpoch(
            event.timestamp,
          );
          final day = DateTime(eventDate.year, eventDate.month, eventDate.day);
          dailyTotals.update(
            day,
            (value) => value + event.value,
            ifAbsent: () => event.value,
          );
        }

        if (caffeineEvents.isEmpty) {
          return const SizedBox(
            height: 150,
            child: Center(
              child: Text("Log your first coffee to see the chart."),
            ),
          );
        }

        final sortedDays = dailyTotals.keys.toList()..sort();
        final firstDay = sortedDays.first;
        final lastDay = sortedDays.last;

        final allDays = <DateTime>[];
        for (int i = 0; i <= lastDay.difference(firstDay).inDays; i++) {
          allDays.add(firstDay.add(Duration(days: i)));
        }

        final fullDailyTotals = <DateTime, double>{};
        for (var day in allDays) {
          fullDailyTotals[day] = dailyTotals[day] ?? 0.0;
        }

        final fullSortedDays = fullDailyTotals.keys.toList()..sort();

        final barGroups = <BarChartGroupData>[];
        for (var i = 0; i < fullSortedDays.length; i++) {
          final day = fullSortedDays[i];
          final total = fullDailyTotals[day]!;
          final isSelected =
              day.year == selectedDate.year &&
              day.month == selectedDate.month &&
              day.day == selectedDate.day;

          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: total,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
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
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
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
                  touchCallback: (event, response) {
                    if (response != null &&
                        response.spot != null &&
                        event is FlTapUpEvent) {
                      final index = response.spot!.touchedBarGroupIndex;
                      ref.read(selectedDateProvider.notifier).state =
                          fullSortedDays[index];
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
      loading:
          () => const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (err, stack) =>
              SizedBox(height: 150, child: Center(child: Text('Error: $err'))),
    );
  }
}

import 'package:decaf/constants/colors.dart';
import 'package:decaf/providers/chart_visibility_provider.dart';
import 'package:decaf/providers/taper_plan_provider.dart';
import 'package:decaf/utils/symptom_calculator.dart';
import 'package:decaf/utils/taper_calculator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/date_provider.dart';
import '../providers/events_provider.dart';
import '../providers/symptoms_provider.dart';

class DailyCaffeineChart extends ConsumerWidget {
  const DailyCaffeineChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final symptomsAsync = ref.watch(symptomsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final visibility = ref.watch(chartVisibilityProvider);
    final taperPlanAsync = ref.watch(taperPlanProvider);

    return eventsAsync.when(
      data: (events) => symptomsAsync.when(
        data: (symptoms) => taperPlanAsync.when(
          data: (taperPlan) {
              final caffeineEvents =
                  events.where((e) => e.type == EventType.caffeine).toList();
              final symptomEvents =
                  events.where((e) => e.type == EventType.symptom && e.value > 0).toList();

              final dailyTotals = <DateTime, double>{};
              for (var event in caffeineEvents) {
                final eventDate = DateTime.fromMillisecondsSinceEpoch(
                  event.timestamp,
                );
                final day = DateTime(
                  eventDate.year,
                  eventDate.month,
                  eventDate.day,
                );
                dailyTotals.update(
                  day,
                  (value) => value + event.value,
                  ifAbsent: () => event.value,
                );
              }

              if (caffeineEvents.isEmpty && symptomEvents.isEmpty) {
                return const SizedBox(
                  height: 150,
                  child: Center(
                    child: Text("Log your first coffee or symptom to see the chart."),
                  ),
                );
              }

              // Get all days that have either caffeine or symptom events
              final allEventDays = <DateTime>{};
              
              // Add caffeine event days
              for (var event in caffeineEvents) {
                final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
                final day = DateTime(eventDate.year, eventDate.month, eventDate.day);
                allEventDays.add(day);
              }
              
              // Add symptom event days
              for (var event in symptomEvents) {
                final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
                final day = DateTime(eventDate.year, eventDate.month, eventDate.day);
                allEventDays.add(day);
              }

              final sortedEventDays = allEventDays.toList()..sort();
              final firstDay = sortedEventDays.first;
              final lastDay = sortedEventDays.last;

              final allDays = <DateTime>[];
              for (int i = 0; i <= lastDay.difference(firstDay).inDays; i++) {
                allDays.add(firstDay.add(Duration(days: i)));
              }

              final fullDailyTotals = <DateTime, double>{};
              for (var day in allDays) {
                fullDailyTotals[day] = dailyTotals[day] ?? 0.0;
              }

              final fullSortedDays = fullDailyTotals.keys.toList()..sort();

              // Calculate taper plan targets for chart days
              final taperTargets = <DateTime, double>{};
              if (taperPlan != null) {
                final schedule = TaperCalculator.generateFullSchedule(taperPlan);
                for (var day in fullSortedDays) {
                  final dayKey = DateTime(day.year, day.month, day.day);
                  final target = schedule[dayKey];
                  if (target != null) {
                    taperTargets[day] = target;
                  }
                }
              }

              // Find max caffeine for scaling (including taper targets)
              final allCaffeineValues = <double>[];
              allCaffeineValues.addAll(fullDailyTotals.values);
              allCaffeineValues.addAll(taperTargets.values);
              
              final maxCaffeine =
                  allCaffeineValues.isEmpty
                      ? 400.0
                      : allCaffeineValues.reduce((a, b) => a > b ? a : b);
              final maxCaffeineForScale =
                  maxCaffeine > 0
                      ? maxCaffeine
                      : 400.0; // Fallback to 400mg if no data

              // Calculate daily symptom scores
              final dailyPositiveScores = <DateTime, double>{};
              final dailyNegativeScores = <DateTime, double>{};

              for (var day in fullSortedDays) {
                final symptomScores = SymptomCalculator.calculateDailyScores(
                  events: events,
                  symptoms: symptoms,
                  date: day,
                );
                dailyPositiveScores[day] = symptomScores.positiveScore;
                dailyNegativeScores[day] = symptomScores.negativeScore;
              }

              // Calculate dynamic bar width based on visible series
              int visibleSeriesCount = 0;
              if (visibility.showCaffeine) visibleSeriesCount++;
              if (visibility.showPositives) visibleSeriesCount++;
              if (visibility.showNegatives) visibleSeriesCount++;
              
              // Base width of 24, divided by number of visible series, with minimum of 8 and maximum of 16
              final dynamicBarWidth = visibleSeriesCount > 0 ? (24 / visibleSeriesCount).clamp(8.0, 16.0) : 8.0;

              final barGroups = <BarChartGroupData>[];
              for (var i = 0; i < fullSortedDays.length; i++) {
                final day = fullSortedDays[i];
                final caffeineTotal = fullDailyTotals[day]!;
                final taperTarget = taperTargets[day] ?? 0.0;

                // Normalize all values to 0-100 scale where max caffeine = 100 and max symptom score (4.0) = 100
                final normalizedCaffeine =
                    (caffeineTotal / maxCaffeineForScale) * 100;
                final normalizedTaperTarget =
                    (taperTarget / maxCaffeineForScale) * 100;
                final normalizedPositiveScore =
                    (dailyPositiveScores[day]! / 4.0) * 100;
                final normalizedNegativeScore =
                    (dailyNegativeScores[day]! / 4.0) * 100;
                final isSelected =
                    day.year == selectedDate.year &&
                    day.month == selectedDate.month &&
                    day.day == selectedDate.day;

                final baseColor =
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.6);
                final positiveColor =
                    isSelected
                        ? AppColors.positiveEffect
                        : AppColors.positiveEffect.withOpacity(0.6);
                final negativeColor =
                    isSelected
                        ? AppColors.negativeEffect
                        : AppColors.negativeEffect.withOpacity(0.6);

                barGroups.add(
                  BarChartGroupData(
                    barsSpace: 2,
                    x: i,
                    barRods: [
                      if (visibility.showCaffeine)
                        BarChartRodData(
                          toY: normalizedCaffeine,
                          color: baseColor,
                          width: dynamicBarWidth,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          backDrawRodData: normalizedTaperTarget > 0 ? BackgroundBarChartRodData(
                            show: true,
                            toY: normalizedTaperTarget,
                            color: AppColors.caffeine.withValues(alpha: 0.2),
                          ) : null,
                        ),
                      if (visibility.showPositives && normalizedPositiveScore > 0)
                        BarChartRodData(
                          toY: normalizedPositiveScore,
                          color: positiveColor,
                          width: dynamicBarWidth,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      if (visibility.showNegatives && normalizedNegativeScore > 0)
                        BarChartRodData(
                          toY: normalizedNegativeScore,
                          color: negativeColor,
                          width: dynamicBarWidth,
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
                              if (index >= 0 && index < fullSortedDays.length) {
                                final day = fullSortedDays[index];
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
                          getTooltipColor: (group) => Colors.transparent,
                          getTooltipItem:
                              (group, groupIndex, rod, rodIndex) => null,
                        ),
                        touchCallback: (event, response) {
                          if (response != null &&
                              response.spot != null &&
                              event is FlTapUpEvent) {
                            final index =
                                response.spot!.touchedBarGroupIndex;
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
            loading: () => const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SizedBox(
              height: 150,
              child: Center(child: Text('Error: $err')),
            ),
          ),
          loading: () => const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => SizedBox(
            height: 150,
            child: Center(child: Text('Error: $err')),
          ),
        ),
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

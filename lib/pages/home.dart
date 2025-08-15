import 'package:decaf/constants/colors.dart';
import 'package:decaf/main.dart';
import 'package:decaf/pages/settings.dart';
import 'package:decaf/providers/chart_visibility_provider.dart';
import 'package:decaf/providers/date_provider.dart';
import 'package:decaf/providers/events_provider.dart';
import 'package:decaf/widgets/daily_caffeine_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decaf/widgets/caffeine_list_view.dart';
import 'package:decaf/providers/symptoms_provider.dart';
import 'package:decaf/widgets/symptom_intensity_recorder.dart';
import 'package:intl/intl.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == today) {
      return 'Today';
    } else if (selectedDay == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    return selectedDay == today;
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    Event event,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: const Text('Are you sure you want to delete this event?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                ref.read(eventsProvider.notifier).deleteEvent(event.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final isToday = _isToday(selectedDate);
    final eventsAsync = ref.watch(eventsProvider);
    final symptomsAsync = ref.watch(symptomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      ref.read(selectedDateProvider.notifier).state =
                          selectedDate.subtract(const Duration(days: 1));
                    },
                  ),
                  Text(
                    _formatDate(selectedDate),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Visibility(
                    visible: !isToday,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        ref
                            .read(selectedDateProvider.notifier)
                            .state = selectedDate.add(const Duration(days: 1));
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(pageIndexProvider.notifier).state = 1;
                    },
                    child: const Text('See more'),
                  ),
                ],
              ),
            ),
            const DailyCaffeineChart(),
            eventsAsync.when(
              data: (events) => symptomsAsync.when(
                data: (symptoms) {
                  final caffeineEvents = events.where((event) {
                    final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
                    return event.type == EventType.caffeine &&
                        eventDate.year == selectedDate.year &&
                        eventDate.month == selectedDate.month &&
                        eventDate.day == selectedDate.day;
                  }).toList();

                  final totalCaffeine = caffeineEvents.fold<double>(
                    0,
                    (previousValue, element) => previousValue + element.value,
                  );

                  // Calculate daily symptom scores
                  final positiveSymptoms = symptoms.where((s) => s.connotation == SymptomConnotation.positive).toList();
                  final negativeSymptoms = symptoms.where((s) => s.connotation == SymptomConnotation.negative).toList();
                  
                  double positiveSum = 0;
                  int positiveCount = 0;
                  double negativeSum = 0;
                  int negativeCount = 0;
                  
                  for (final symptom in positiveSymptoms) {
                    final symptomEvents = events.where((event) {
                      final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
                      return event.type == EventType.symptom &&
                          event.name == symptom.name &&
                          eventDate.year == selectedDate.year &&
                          eventDate.month == selectedDate.month &&
                          eventDate.day == selectedDate.day;
                    }).toList();
                    
                    if (symptomEvents.isNotEmpty && symptomEvents.first.value > 0) {
                      positiveSum += symptomEvents.first.value;
                      positiveCount++;
                    }
                  }
                  
                  for (final symptom in negativeSymptoms) {
                    final symptomEvents = events.where((event) {
                      final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
                      return event.type == EventType.symptom &&
                          event.name == symptom.name &&
                          eventDate.year == selectedDate.year &&
                          eventDate.month == selectedDate.month &&
                          eventDate.day == selectedDate.day;
                    }).toList();
                    
                    if (symptomEvents.isNotEmpty && symptomEvents.first.value > 0) {
                      negativeSum += symptomEvents.first.value;
                      negativeCount++;
                    }
                  }
                  
                  final positiveScore = positiveCount > 0 ? positiveSum / positiveCount : 0.0;
                  final negativeScore = negativeCount > 0 ? negativeSum / negativeCount : 0.0;

                  return Consumer(
                    builder: (context, ref, child) {
                      final visibility = ref.watch(chartVisibilityProvider);
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildClickableStatsItem(
                                    context,
                                    'Caffeine',
                                    '${totalCaffeine.toStringAsFixed(0)} mg',
                                    Theme.of(context).colorScheme.primary,
                                    visibility.showCaffeine,
                                    () {
                                      ref.read(chartVisibilityProvider.notifier).toggleCaffeine();
                                    },
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: Colors.grey[300],
                                ),
                                Expanded(
                                  child: _buildClickableStatsItem(
                                    context,
                                    'Positives',
                                    positiveCount > 0 ? positiveScore.toStringAsFixed(1) : '—',
                                    AppColors.positiveEffect,
                                    visibility.showPositives,
                                    () {
                                      ref.read(chartVisibilityProvider.notifier).togglePositives();
                                    },
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: Colors.grey[300],
                                ),
                                Expanded(
                                  child: _buildClickableStatsItem(
                                    context,
                                    'Negatives',
                                    negativeCount > 0 ? negativeScore.toStringAsFixed(1) : '—',
                                    AppColors.negativeEffect,
                                    visibility.showNegatives,
                                    () {
                                      ref.read(chartVisibilityProvider.notifier).toggleNegatives();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
            eventsAsync.when(
              data: (events) {
                final caffeineEvents =
                    events.where((event) {
                      final eventDate = DateTime.fromMillisecondsSinceEpoch(
                        event.timestamp,
                      );
                      return event.type == EventType.caffeine &&
                          eventDate.year == selectedDate.year &&
                          eventDate.month == selectedDate.month &&
                          eventDate.day == selectedDate.day;
                    }).toList();

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CaffeineListView(
                        caffeineEvents: caffeineEvents,
                        showDeleteConfirmationDialog:
                            _showDeleteConfirmationDialog,
                      ),
                      symptomsAsync.when(
                        data: (symptoms) {
                          final positiveSymptoms =
                              symptoms
                                  .where(
                                    (s) =>
                                        s.connotation ==
                                        SymptomConnotation.positive,
                                  )
                                  .toList();
                          final negativeSymptoms =
                              symptoms
                                  .where(
                                    (s) =>
                                        s.connotation ==
                                        SymptomConnotation.negative,
                                  )
                                  .toList();

                          return Column(
                            children: [
                              if (symptoms.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Daily Check-In',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (positiveSymptoms.isNotEmpty)
                                _buildSymptomCard(
                                  context,
                                  ref,
                                  'Positives',
                                  positiveSymptoms,
                                  events,
                                  selectedDate,
                                  AppColors.positiveEffectLight,
                                ),
                              if (positiveSymptoms.isNotEmpty &&
                                  negativeSymptoms.isNotEmpty)
                                const SizedBox(height: 16),
                              if (negativeSymptoms.isNotEmpty)
                                _buildSymptomCard(
                                  context,
                                  ref,
                                  'Negatives',
                                  negativeSymptoms,
                                  events,
                                  selectedDate,
                                  AppColors.negativeEffectLight,
                                ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (e, st) => Text('Error: $e'),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stackTrace) => Center(child: Text('Error: $error')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildClickableStatsItem(
    BuildContext context, 
    String label, 
    String value, 
    Color color, 
    bool isVisible, 
    VoidCallback onTap
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isVisible 
            ? color.withValues(alpha: 0.05) 
            : Colors.grey.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isVisible 
              ? color.withValues(alpha: 0.3) 
              : Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isVisible ? Colors.grey[600] : Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isVisible ? color : Colors.grey[400],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomCard(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<Symptom> symptoms,
    List<Event> events,
    DateTime selectedDate,
    Color backgroundColor,
  ) {
    // Calculate the average score for this group
    double totalScore = 0;
    int countWithValues = 0;
    
    for (final symptom in symptoms) {
      final symptomEvents = events.where((event) {
        final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
        return event.type == EventType.symptom &&
            event.name == symptom.name &&
            eventDate.year == selectedDate.year &&
            eventDate.month == selectedDate.month &&
            eventDate.day == selectedDate.day;
      }).toList();
      
      if (symptomEvents.isNotEmpty && symptomEvents.first.value > 0) {
        totalScore += symptomEvents.first.value;
        countWithValues++;
      }
    }
    
    final averageScore = countWithValues > 0 ? totalScore / countWithValues : 0.0;
    final isPositive = symptoms.isNotEmpty && symptoms.first.connotation == SymptomConnotation.positive;
    final scoreColor = isPositive ? AppColors.positiveEffect : AppColors.negativeEffect;

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (countWithValues > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scoreColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      '${averageScore.toStringAsFixed(1)} avg',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...symptoms.map((symptom) {
              final symptomEvents =
                  events.where((event) {
                    final eventDate = DateTime.fromMillisecondsSinceEpoch(
                      event.timestamp,
                    );
                    return event.type == EventType.symptom &&
                        event.name == symptom.name &&
                        eventDate.year == selectedDate.year &&
                        eventDate.month == selectedDate.month &&
                        eventDate.day == selectedDate.day;
                  }).toList();

              final existingEvent =
                  symptomEvents.isNotEmpty ? symptomEvents.first : null;
              final initialIntensity = existingEvent?.value.toInt() ?? 0;

              return SymptomIntensityRecorder(
                key: ValueKey(symptom.id),
                symptom: symptom,
                initialIntensity: initialIntensity,
                onIntensityChanged: (intensity) {
                  final existingEvent =
                      symptomEvents.isNotEmpty ? symptomEvents.first : null;

                  if (existingEvent != null) {
                    final updatedEvent = Event(
                      id: existingEvent.id,
                      type: EventType.symptom,
                      name: symptom.name,
                      value: intensity.toDouble(),
                      timestamp: existingEvent.timestamp,
                    );
                    ref.read(eventsProvider.notifier).updateEvent(updatedEvent);
                  } else {
                    ref
                        .read(eventsProvider.notifier)
                        .addEvent(
                          EventType.symptom,
                          symptom.name,
                          intensity.toDouble(),
                          selectedDate,
                        );
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

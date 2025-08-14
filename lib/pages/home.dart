import 'package:decaf/main.dart';
import 'package:decaf/pages/settings.dart';
import 'package:decaf/providers/date_provider.dart';
import 'package:decaf/providers/events_provider.dart';
import 'package:decaf/widgets/daily_caffeine_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decaf/widgets/caffeine_list_view.dart';
import 'package:decaf/widgets/input_slider.dart';
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
                        ref.read(selectedDateProvider.notifier).state =
                            selectedDate.add(const Duration(days: 1));
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
                  )
                ],
              ),
            ),
            const DailyCaffeineChart(),
            eventsAsync.when(
              data: (events) {
                final caffeineEvents = events.where((event) {
                  final eventDate = DateTime.fromMillisecondsSinceEpoch(
                    event.timestamp,
                  );
                  return event.type == EventType.caffeine &&
                      eventDate.year == selectedDate.year &&
                      eventDate.month == selectedDate.month &&
                      eventDate.day == selectedDate.day;
                }).toList();

                final totalCaffeine = caffeineEvents.fold<double>(
                    0,
                    (previousValue, element) =>
                        previousValue + element.value);

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Total: ${totalCaffeine.toStringAsFixed(0)} mg',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
            eventsAsync.when(
              data: (events) {
                final caffeineEvents = events.where((event) {
                  final eventDate = DateTime.fromMillisecondsSinceEpoch(
                    event.timestamp,
                  );
                  return event.type == EventType.caffeine &&
                      eventDate.year == selectedDate.year &&
                      eventDate.month == selectedDate.month &&
                      eventDate.day == selectedDate.day;
                }).toList();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CaffeineListView(
                      caffeineEvents: caffeineEvents,
                      showDeleteConfirmationDialog:
                          _showDeleteConfirmationDialog,
                    ),
                    const InputSlider(
                      label: "Brain Fog",
                      lowEmoji: "🧠",
                      lowText: "Clear Minded",
                      highEmoji: "🌫️",
                      highText: "Super Foggy",
                    ),
                    const InputSlider(
                      label: "Headache",
                      lowEmoji: "😊",
                      lowText: "No Headache",
                      highEmoji: "🤕",
                      highText: "Severe Headache",
                    ),
                    const InputSlider(
                      label: "Anxiety",
                      lowEmoji: "😌",
                      lowText: "Calm",
                      highEmoji: "😥",
                      highText: "Anxious",
                    ),
                    const InputSlider(
                      label: "Fatigue",
                      lowEmoji: "⚡",
                      lowText: "Energized",
                      highEmoji: "😴",
                      highText: "Exhausted",
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error')),
            ),
          ],
        ),
      ),
    );
  }
}

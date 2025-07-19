import 'package:decaf/pages/profile.dart';
import 'package:decaf/providers/date_provider.dart';
import 'package:decaf/providers/events_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      BuildContext context, WidgetRef ref, Event event) async {
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
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
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
                )
              ],
            ),
          ),
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                final caffeineEvents = events.where((event) {
                  final eventDate =
                      DateTime.fromMillisecondsSinceEpoch(event.timestamp);
                  return event.type == EventType.caffeine &&
                      eventDate.year == selectedDate.year &&
                      eventDate.month == selectedDate.month &&
                      eventDate.day == selectedDate.day;
                }).toList();

                if (caffeineEvents.isEmpty) {
                  return const Center(
                      child: Text('No caffeine tracked for this day.'));
                }

                return ListView.builder(
                  itemCount: caffeineEvents.length,
                  itemBuilder: (context, index) {
                    final event = caffeineEvents[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      child: ListTile(
                        title: Text(event.name),
                        trailing: Text('${event.value.toStringAsFixed(0)}mg'),
                        onLongPress: () =>
                            _showDeleteConfirmationDialog(context, ref, event),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      
    );
  }
}
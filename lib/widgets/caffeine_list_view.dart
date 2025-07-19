import 'package:decaf/providers/events_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CaffeineListView extends ConsumerWidget {
  final List<Event> caffeineEvents;
  final Future<void> Function(BuildContext, WidgetRef, Event) showDeleteConfirmationDialog;

  const CaffeineListView({
    super.key,
    required this.caffeineEvents,
    required this.showDeleteConfirmationDialog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (caffeineEvents.isEmpty) {
      return const Center(child: Text('No caffeine tracked for this day.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
            onLongPress: () => showDeleteConfirmationDialog(context, ref, event),
          ),
        );
      },
    );
  }
}

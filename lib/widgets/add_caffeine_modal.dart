
import 'package:decaf/providers/events_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddCaffeineModal extends ConsumerStatefulWidget {
  const AddCaffeineModal({super.key});

  @override
  ConsumerState<AddCaffeineModal> createState() => _AddCaffeineModalState();
}

class _AddCaffeineModalState extends ConsumerState<AddCaffeineModal> {
  double? _caffeineAmount;

  final Map<String, double> _commonCaffeineSources = {
    'Espresso': 60,
    'Coffee': 90,
    'Black Tea': 50,
    'Green Tea': 30,
    'Cola': 20,
    'Energy Drink': 80,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add Caffeine', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            children: _commonCaffeineSources.entries.map((entry) {
              return ChoiceChip(
                label: Text('${entry.key} (${entry.value}mg)'),
                selected: _caffeineAmount == entry.value,
                onSelected: (selected) {
                  setState(() {
                    _caffeineAmount = selected ? entry.value : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _caffeineAmount != null
                ? () {
                    ref.read(eventsProvider.notifier).addEvent(EventName.caffeine, _caffeineAmount!);
                    Navigator.pop(context);
                  }
                : null,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}



import 'package:decaf/providers/date_provider.dart';
import 'package:decaf/providers/events_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddCaffeineModal extends ConsumerStatefulWidget {
  const AddCaffeineModal({super.key});

  @override
  ConsumerState<AddCaffeineModal> createState() => _AddCaffeineModalState();
}

class _AddCaffeineModalState extends ConsumerState<AddCaffeineModal> {
  double _caffeineAmount = 0;
  String? _selectedChipKey;

  final Map<String, double> _commonCaffeineSources = {
    '☕ Espresso': 60.0,
    '☕ Coffee': 90.0,
    '🍵 Black Tea': 50.0,
    '🍵 Green Tea': 30.0,
    '🥤 Cola': 20.0,
    '⚡ Energy Drink': 80.0,
    '❓ Other': 50.0,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add Caffeine', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    _caffeineAmount = (_caffeineAmount - 5).clamp(0, double.infinity);
                  });
                },
              ),
              Text(
                '${_caffeineAmount.toStringAsFixed(0)}mg',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _caffeineAmount = _caffeineAmount + 5;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            children: _commonCaffeineSources.entries.map((entry) {
              final String name = entry.key;
              final double value = entry.value;
              return ChoiceChip(
                label: Text('$name (${value.toStringAsFixed(0)}mg)'),
                selected: _selectedChipKey == name,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedChipKey = name;
                      _caffeineAmount = value;
                    } else {
                      _selectedChipKey = null;
                      _caffeineAmount = 0;
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _caffeineAmount > 0
                ? () {
                    final selectedDate = ref.read(selectedDateProvider);
                    final now = DateTime.now();
                    final timestamp = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      now.hour,
                      now.minute,
                      now.second,
                    );
                    ref.read(eventsProvider.notifier).addEvent(
                          EventType.caffeine,
                          _selectedChipKey ?? 'Custom Caffeine',
                          _caffeineAmount,
                          timestamp,
                        );
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



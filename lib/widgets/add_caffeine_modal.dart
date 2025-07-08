

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

  final Map<String, Map<String, dynamic>> _commonCaffeineSources = {
    'Espresso': {'emoji': '☕', 'value': 60.0},
    'Coffee': {'emoji': '☕', 'value': 90.0},
    'Black Tea': {'emoji': '🍵', 'value': 50.0},
    'Green Tea': {'emoji': '🍵', 'value': 30.0},
    'Cola': {'emoji': '🥤', 'value': 20.0},
    'Energy Drink': {'emoji': '⚡', 'value': 80.0},
    'Other': {'emoji': '❓', 'value': 50.0},
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
              final String emoji = entry.value['emoji'] as String;
              final double value = entry.value['value'] as double;
              return ChoiceChip(
                label: Text('$emoji ${entry.key} (${value.toStringAsFixed(0)}mg)'),
                selected: _selectedChipKey == entry.key,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedChipKey = entry.key;
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
                    ref.read(eventsProvider.notifier).addEvent(EventType.caffeine, _selectedChipKey ?? 'Custom Caffeine', _caffeineAmount);
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


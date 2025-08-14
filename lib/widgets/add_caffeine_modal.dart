import 'package:decaf/pages/manage_caffeine_options.dart';
import 'package:decaf/providers/caffeine_options_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final caffeineOptions = ref.watch(caffeineOptionsProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add Caffeine',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    _caffeineAmount = (_caffeineAmount - 5).clamp(
                      0,
                      double.infinity,
                    );
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
            children: [
              ...caffeineOptions.when(
                data: (options) {
                  return options.map((option) {
                    final name = '${option.emoji} ${option.name}';
                    return ChoiceChip(
                      label: Text('$name (${option.caffeineAmount.toStringAsFixed(0)}mg)'),
                      selected: _selectedChipKey == name,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedChipKey = name;
                            _caffeineAmount = option.caffeineAmount;
                          } else {
                            _selectedChipKey = null;
                            _caffeineAmount = 0;
                          }
                        });
                      },
                    );
                  }).toList();
                },
                loading: () => [const CircularProgressIndicator()],
                error: (error, stackTrace) => [Text('Error: $error')],
              ),
              ChoiceChip(
                label: Text('⚙️ Update Options'),
                selected: false,
                onSelected: (selected) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ManageCaffeineOptionsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed:
                _caffeineAmount > 0
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
                      ref
                          .read(eventsProvider.notifier)
                          .addEvent(
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

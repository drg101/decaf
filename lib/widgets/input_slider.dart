import 'package:flutter/material.dart';
import 'package:decaf/providers/events_provider.dart';
import 'package:decaf/providers/date_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InputSlider extends ConsumerStatefulWidget {
  final String label;
  final String lowEmoji;
  final String lowText;
  final String highEmoji;
  final String highText;
  final EventType eventType;

  const InputSlider({
    super.key,
    required this.label,
    required this.lowEmoji,
    required this.lowText,
    required this.highEmoji,
    required this.highText,
    required this.eventType,
  });

  @override
  ConsumerState<InputSlider> createState() => _InputSliderState();
}

class _InputSliderState extends ConsumerState<InputSlider> {
  double _currentSliderValue = 0;

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final eventsAsync = ref.watch(eventsProvider);

    return eventsAsync.when(
      data: (events) {
        final relevantEvent = events.firstWhere(
          (event) {
            final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
            return event.type == widget.eventType &&
                   eventDate.year == selectedDate.year &&
                   eventDate.month == selectedDate.month &&
                   eventDate.day == selectedDate.day;
          },
          orElse: () => Event(id: '', type: widget.eventType, name: '', value: 0, timestamp: 0),
        );

        _currentSliderValue = relevantEvent.value;
        final bool hasSavedValue = relevantEvent.id.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              Text(widget.label),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Text(widget.lowEmoji),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 25.0,
                            thumbShape:
                                hasSavedValue
                                    ? null
                                    : const RoundSliderThumbShape(
                                        enabledThumbRadius: 0.0,
                                      ),
                            overlayShape:
                                hasSavedValue
                                    ? null
                                    : const RoundSliderOverlayShape(
                                        overlayRadius: 0.0,
                                      ),
                          ),
                          child: Slider(
                            value: _currentSliderValue,
                            min: 0,
                            max: 5,
                            divisions: 5,
                            label: _currentSliderValue.round().toString(),
                            onChanged: (double value) {
                              setState(() {
                                _currentSliderValue = value;
                              });
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

                              final events = ref.read(eventsProvider).value ?? [];
                              final existingEvent = events.firstWhere(
                                (event) {
                                  final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
                                  return event.type == widget.eventType &&
                                         eventDate.year == selectedDate.year &&
                                         eventDate.month == selectedDate.month &&
                                         eventDate.day == selectedDate.day;
                                },
                                orElse: () => Event(id: '', type: widget.eventType, name: '', value: 0, timestamp: 0),
                              );

                              if (existingEvent.id.isNotEmpty) {
                                ref.read(eventsProvider.notifier).updateEvent(
                                      Event(
                                        id: existingEvent.id,
                                        type: widget.eventType,
                                        name: existingEvent.name,
                                        value: value,
                                        timestamp: existingEvent.timestamp,
                                      ),
                                    );
                              } else {
                                ref.read(eventsProvider.notifier).addEvent(
                                      widget.eventType,
                                      widget.label,
                                      value,
                                      timestamp,
                                    );
                              }
                            },
                            thumbColor:
                                hasSavedValue ? null : Colors.transparent,
                            overlayColor:
                                hasSavedValue
                                    ? null
                                    : MaterialStateProperty.all(Colors.transparent),
                          ),
                        ),
                      ),
                    ),
                    Text(widget.highEmoji),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(widget.lowText), Text(widget.highText)],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const CircularProgressIndicator(), // Or a suitable loading indicator
      error: (error, stack) => Text('Error: $error'), // Or a suitable error display
    );
  }
}

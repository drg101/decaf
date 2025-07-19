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
  double? _savedValue;

  @override
  void initState() {
    super.initState();
    _updateSliderValue();
  }

  @override
  void didUpdateWidget(covariant InputSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSliderValue();
  }

  void _updateSliderValue() {
    final selectedDate = ref.read(selectedDateProvider);
    final events = ref.read(eventsProvider).value ?? [];
    final relevantEvent = events.firstWhere(
      (event) {
        final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
        return event.type == widget.eventType &&
               eventDate.year == selectedDate.year &&
               eventDate.month == selectedDate.month &&
               eventDate.day == selectedDate.day;
      },
      orElse: () => Event(id: '', type: widget.eventType, name: '', value: 0, timestamp: 0), // Default or empty event
    );

    if (relevantEvent.id.isNotEmpty) { // Check if a real event was found
      _currentSliderValue = relevantEvent.value;
      _savedValue = relevantEvent.value;
    } else {
      _currentSliderValue = 0;
      _savedValue = null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            _savedValue == null
                                ? const RoundSliderThumbShape(
                                  enabledThumbRadius: 0.0,
                                )
                                : null,
                        overlayShape:
                            _savedValue == null
                                ? const RoundSliderOverlayShape(
                                  overlayRadius: 0.0,
                                )
                                : null,
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
                            _savedValue == null ? Colors.transparent : null,
                        overlayColor:
                            _savedValue == null
                                ? MaterialStateProperty.all(Colors.transparent)
                                : null,
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
  }
}

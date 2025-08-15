import 'package:decaf/providers/symptoms_provider.dart';
import 'package:flutter/material.dart';

class SymptomIntensityRecorder extends StatefulWidget {
  final Symptom symptom;
  final int initialIntensity;
  final Function(int) onIntensityChanged;

  const SymptomIntensityRecorder({
    super.key,
    required this.symptom,
    this.initialIntensity = 0,
    required this.onIntensityChanged,
  });

  @override
  State<SymptomIntensityRecorder> createState() =>
      _SymptomIntensityRecorderState();
}

class _SymptomIntensityRecorderState extends State<SymptomIntensityRecorder> {
  late int _intensity;

  @override
  void initState() {
    super.initState();
    _intensity = widget.initialIntensity;
  }

  @override
  void didUpdateWidget(covariant SymptomIntensityRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIntensity != oldWidget.initialIntensity) {
      setState(() {
        _intensity = widget.initialIntensity;
      });
    }
  }

  Color? _getColorForIntensity(int index) {
    if (index >= _intensity) {
      return Colors.grey[300];
    }

    return Color.lerp(
      const Color.fromARGB(255, 0, 140, 255),
      const Color.fromARGB(255, 255, 95, 77),
      index / 4,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '${widget.symptom.emoji} ${widget.symptom.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_intensity == index + 1) {
                      _intensity = 0;
                    } else {
                      _intensity = index + 1;
                    }
                    widget.onIntensityChanged(_intensity);
                  });
                },
                child: Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _getColorForIntensity(index),
                    border: Border.all(
                      color: Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
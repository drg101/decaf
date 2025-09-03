import 'package:decaf/constants/colors.dart';
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
    _intensity = widget.initialIntensity == 0 ? -1 : widget.initialIntensity - 1;
  }

  @override
  void didUpdateWidget(covariant SymptomIntensityRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIntensity != oldWidget.initialIntensity) {
      setState(() {
        _intensity = widget.initialIntensity == 0 ? -1 : widget.initialIntensity - 1;
      });
    }
  }

  Color? _getColorForIntensity(int index) {
    if (_intensity == -1 || index > _intensity) {
      return Colors.grey[500];
    }

    final isPositive = widget.symptom.connotation == SymptomConnotation.positive;
    
    if (isPositive) {
      return Color.lerp(
        AppColors.positiveEffect.withOpacity(0.3),
        AppColors.positiveEffect,
        (index + 1) / 5,
      );
    } else {
      return Color.lerp(
        AppColors.negativeEffect.withOpacity(0.3),
        AppColors.negativeEffect,
        (index + 1) / 5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${widget.symptom.emoji} ${widget.symptom.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    final clickedValue = index;
                    final newIntensity = (_intensity == clickedValue) ? -1 : clickedValue;
                    _intensity = newIntensity;
                    widget.onIntensityChanged(_intensity == -1 ? 0 : _intensity + 1);
                  });
                },
                child: Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _getColorForIntensity(index),
                    border: (_intensity == -1 || index > _intensity) ? Border.all(color: Colors.white, width: 1) : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      index.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
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
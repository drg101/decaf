import 'package:flutter/material.dart';

class InputSlider extends StatefulWidget {
  final String label;
  final String lowEmoji;
  final String highEmoji;

  const InputSlider({
    super.key,
    required this.label,
    required this.lowEmoji,
    required this.highEmoji,
  });

  @override
  State<InputSlider> createState() => _InputSliderState();
}

class _InputSliderState extends State<InputSlider> {
  double _currentSliderValue = 0;

  @override
  Widget build(BuildContext context) {
    final ColorTween colorTween = ColorTween(
      begin: Colors.green,
      end: Colors.red,
    );
    final Color? backgroundColor = colorTween.lerp(_currentSliderValue / 5.0);

    return Column(
      children: [
        Text(widget.label),
        Container(
          color: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Text(widget.lowEmoji),
              Expanded(
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
                  },
                ),
              ),
              Text(widget.highEmoji),
            ],
          ),
        ),
      ],
    );
  }
}

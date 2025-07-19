import 'package:flutter/material.dart';

class InputSlider extends StatefulWidget {
  final String label;
  final String lowEmoji;
  final String lowText;
  final String highEmoji;
  final String highText;
  final double? value;

  const InputSlider({
    super.key,
    required this.label,
    required this.lowEmoji,
    required this.lowText,
    required this.highEmoji,
    required this.highText,
    this.value,
  });

  @override
  State<InputSlider> createState() => _InputSliderState();
}

class _InputSliderState extends State<InputSlider> {
  double _currentSliderValue = 0;

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      _currentSliderValue = widget.value!;
    }
  }

  @override
  void didUpdateWidget(covariant InputSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && widget.value != oldWidget.value) {
      _currentSliderValue = widget.value!;
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
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 25.0,
                        thumbShape: widget.value == null
                            ? const RoundSliderThumbShape(enabledThumbRadius: 0.0)
                            : null,
                        overlayShape: widget.value == null
                            ? const RoundSliderOverlayShape(overlayRadius: 0.0)
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
                        },
                        thumbColor: widget.value == null ? Colors.transparent : null,
                        overlayColor: widget.value == null
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
              children: [
                Text(widget.lowText),
                Text(widget.highText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

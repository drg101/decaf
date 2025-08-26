import 'package:decaf/constants/colors.dart';
import 'package:decaf/models/taper_preset.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class PresetSelector extends StatelessWidget {
  final TaperPreset? selectedPreset;
  final Function(TaperPreset) onPresetSelected;

  const PresetSelector({
    super.key,
    required this.selectedPreset,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Taper Method',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...TaperPreset.values.map((preset) => _buildPresetCard(context, preset)),
      ],
    );
  }

  Widget _buildPresetCard(BuildContext context, TaperPreset preset) {
    final isSelected = selectedPreset == preset;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onPresetSelected(preset),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected 
                    ? AppColors.caffeine 
                    : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected 
                  ? AppColors.caffeine.withValues(alpha: 0.05)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.caffeine.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      preset.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.caffeine : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preset.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPreviewGraph(context, preset, isSelected),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.caffeine,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewGraph(BuildContext context, TaperPreset preset, bool isSelected) {
    final color = isSelected ? AppColors.caffeine : Colors.grey;
    
    return SizedBox(
      height: 40,
      child: CustomPaint(
        size: const Size(double.infinity, 40),
        painter: PresetGraphPainter(preset: preset, color: color),
      ),
    );
  }
}

class PresetGraphPainter extends CustomPainter {
  final TaperPreset preset;
  final Color color;

  PresetGraphPainter({required this.preset, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    
    // Define points based on preset type
    List<Offset> points = [];
    
    switch (preset) {
      case TaperPreset.linear:
        // Smooth linear decline
        for (int i = 0; i <= 20; i++) {
          final x = (i / 20) * size.width;
          final y = size.height - (size.height * (20 - i) / 20);
          points.add(Offset(x, y));
        }
        break;
      case TaperPreset.stepDown:
        // Step function with 4 steps
        for (int step = 0; step < 4; step++) {
          final stepWidth = size.width / 4;
          final stepHeight = size.height * (3 - step) / 4;
          final startX = step * stepWidth;
          final endX = (step + 1) * stepWidth;
          
          points.add(Offset(startX, size.height - stepHeight));
          points.add(Offset(endX, size.height - stepHeight));
        }
        points.add(Offset(size.width, size.height));
        break;
      case TaperPreset.custom:
        // Wavy custom line
        for (int i = 0; i <= 20; i++) {
          final x = (i / 20) * size.width;
          final baseY = size.height - (size.height * (20 - i) / 20);
          final wave = 5 * math.sin(i * 0.5) * (1 - i / 20);
          final y = baseY + wave;
          points.add(Offset(x, y.clamp(0, size.height)));
        }
        break;
    }

    // Create path and fill path
    if (points.isNotEmpty) {
      fillPath.moveTo(0, size.height);
      path.moveTo(points.first.dx, points.first.dy);
      fillPath.lineTo(points.first.dx, points.first.dy);
      
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      
      fillPath.lineTo(size.width, size.height);
      fillPath.close();
    }

    // Draw fill and stroke
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
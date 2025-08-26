import 'package:decaf/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTaperEditor extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final double startingAmount;
  final Map<int, double> customTargets; // day index -> target amount
  final Function(Map<int, double>) onTargetsChanged;

  const CustomTaperEditor({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.startingAmount,
    required this.customTargets,
    required this.onTargetsChanged,
  });

  @override
  State<CustomTaperEditor> createState() => _CustomTaperEditorState();
}

class _CustomTaperEditorState extends State<CustomTaperEditor> {
  late Map<int, double> _targets;
  int? _selectedDay;
  final TextEditingController _targetController = TextEditingController();
  double? _pendingTarget;

  @override
  void initState() {
    super.initState();
    _targets = Map.from(widget.customTargets);
    
    // Ensure first and last days are set
    final totalDays = widget.endDate.difference(widget.startDate).inDays + 1;
    if (!_targets.containsKey(0)) {
      _targets[0] = widget.startingAmount;
    }
    if (!_targets.containsKey(totalDays - 1)) {
      _targets[totalDays - 1] = 0.0;
    }
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = widget.endDate.difference(widget.startDate).inDays + 1;
    final interpolatedTargets = _generateInterpolatedTargets(totalDays);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Taper Schedule',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap days to set custom targets. Values will be interpolated between set points.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        
        // Calendar grid
        _buildCalendarGrid(totalDays, interpolatedTargets),
        
        const SizedBox(height: 16),
        
        // Target input for selected day
        if (_selectedDay != null) _buildTargetInput(),
        
        const SizedBox(height: 16),
        
        // Set points summary
        _buildSetPointsSummary(),
      ],
    );
  }

  Widget _buildCalendarGrid(int totalDays, Map<int, double> interpolatedTargets) {
    // Calculate weeks needed
    final weeksNeeded = (totalDays / 7).ceil();
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Week day headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) =>
                Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
          
          // Calendar days
          for (int week = 0; week < weeksNeeded; week++)
            Row(
              children: List.generate(7, (dayOfWeek) {
                final dayIndex = week * 7 + dayOfWeek;
                if (dayIndex >= totalDays) {
                  return Expanded(child: Container(height: 60));
                }
                
                return Expanded(
                  child: _buildDayCell(dayIndex, interpolatedTargets[dayIndex] ?? 0),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildDayCell(int dayIndex, double targetAmount) {
    final isSelected = _selectedDay == dayIndex;
    final isSetPoint = _targets.containsKey(dayIndex);
    final isFirst = dayIndex == 0;
    final isLast = dayIndex == widget.endDate.difference(widget.startDate).inDays;
    final date = widget.startDate.add(Duration(days: dayIndex));
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = dayIndex;
          _pendingTarget = null;
          // Set controller to current target or interpolated value
          final currentTarget = _targets[dayIndex] ?? targetAmount;
          _targetController.text = currentTarget.toStringAsFixed(0);
        });
      },
      child: Container(
        height: 60,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.caffeine.withValues(alpha: 0.2)
              : (isSetPoint 
                  ? AppColors.caffeine.withValues(alpha: 0.1)
                  : Colors.transparent),
          border: isSetPoint 
              ? Border.all(color: AppColors.caffeine, width: 2)
              : (isSelected 
                  ? Border.all(color: AppColors.caffeine.withValues(alpha: 0.5), width: 1)
                  : null),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                fontWeight: (isFirst || isLast || isSetPoint) ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.caffeine : Colors.black,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${targetAmount.toStringAsFixed(0)}mg',
              style: TextStyle(
                fontSize: 10,
                color: isSetPoint ? AppColors.caffeine : Colors.grey[600],
                fontWeight: isSetPoint ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetInput() {
    final date = widget.startDate.add(Duration(days: _selectedDay!));
    final isFirstOrLast = _selectedDay == 0 || _selectedDay == widget.endDate.difference(widget.startDate).inDays;
    final currentTarget = _targets[_selectedDay] ?? (_generateInterpolatedTargets(widget.endDate.difference(widget.startDate).inDays + 1)[_selectedDay!] ?? 0.0);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Target for ${_formatDate(date)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isFirstOrLast) ...[
              const SizedBox(height: 8),
              Text(
                isFirstOrLast && _selectedDay == 0 
                    ? 'Starting amount (cannot be changed)'
                    : 'Final target (always 0mg)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _targetController,
                    enabled: !isFirstOrLast,
                    decoration: const InputDecoration(
                      labelText: 'Target Amount',
                      suffix: Text('mg'),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      _pendingTarget = double.tryParse(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDay = null;
                      _pendingTarget = null;
                      _targetController.clear();
                    });
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isFirstOrLast ? null : () {
                    if (_pendingTarget != null) {
                      setState(() {
                        if (_pendingTarget! <= 0) {
                          _targets.remove(_selectedDay);
                        } else {
                          _targets[_selectedDay!] = _pendingTarget!;
                        }
                        _selectedDay = null;
                        _pendingTarget = null;
                        _targetController.clear();
                      });
                      widget.onTargetsChanged(_targets);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.caffeine,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetPointsSummary() {
    final sortedKeys = _targets.keys.toList()..sort();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Points',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (sortedKeys.isEmpty)
              Text(
                'No custom points set. Using linear interpolation.',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: sortedKeys.map((dayIndex) {
                  final date = widget.startDate.add(Duration(days: dayIndex));
                  final target = _targets[dayIndex]!;
                  return Chip(
                    label: Text('Day ${dayIndex + 1}: ${target.toStringAsFixed(0)}mg'),
                    backgroundColor: AppColors.caffeine.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Map<int, double> _generateInterpolatedTargets(int totalDays) {
    final result = <int, double>{};
    final sortedKeys = _targets.keys.toList()..sort();
    
    for (int day = 0; day < totalDays; day++) {
      if (_targets.containsKey(day)) {
        result[day] = _targets[day]!;
      } else {
        // Find surrounding set points for interpolation
        int? beforeKey, afterKey;
        
        for (final key in sortedKeys) {
          if (key < day) beforeKey = key;
          if (key > day && afterKey == null) afterKey = key;
        }
        
        if (beforeKey != null && afterKey != null) {
          // Interpolate between two points
          final beforeValue = _targets[beforeKey]!;
          final afterValue = _targets[afterKey]!;
          final progress = (day - beforeKey) / (afterKey - beforeKey);
          result[day] = beforeValue + (afterValue - beforeValue) * progress;
        } else if (beforeKey != null) {
          // Extrapolate from the last point
          result[day] = _targets[beforeKey]!;
        } else if (afterKey != null) {
          // Extrapolate from the first point
          result[day] = _targets[afterKey]!;
        } else {
          // No points set, use linear from start to end
          final progress = day / (totalDays - 1);
          result[day] = widget.startingAmount * (1 - progress);
        }
      }
    }
    
    return result;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
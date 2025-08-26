import 'package:decaf/models/taper_plan.dart';
import 'package:decaf/models/taper_preset.dart';

class TaperCalculator {
  static double calculateTargetForDay(TaperPlan plan, DateTime date) {
    final daysSinceStart = date.difference(plan.startDate).inDays;
    
    if (daysSinceStart < 0) {
      return plan.startingAmount;
    }
    
    if (daysSinceStart >= plan.totalDays) {
      return 0.0;
    }
    
    switch (plan.preset) {
      case TaperPreset.linear:
        return _calculateLinearTarget(plan, daysSinceStart);
      case TaperPreset.stepDown:
        return _calculateStepDownTarget(plan, daysSinceStart);
      case TaperPreset.custom:
        return _calculateCustomTarget(plan, daysSinceStart);
    }
  }

  static double _calculateLinearTarget(TaperPlan plan, int daysSinceStart) {
    final totalReduction = plan.startingAmount;
    final dailyReduction = totalReduction / (plan.totalDays - 1);
    final target = plan.startingAmount - (dailyReduction * daysSinceStart);
    return target.clamp(0.0, plan.startingAmount);
  }

  static double _calculateStepDownTarget(TaperPlan plan, int daysSinceStart) {
    // Support both new and old configuration keys for compatibility
    final stepReduction = plan.presetConfig['stepReduction'] as double? ?? 
                         plan.presetConfig['weeklyReduction'] as double? ??
                         (plan.startingAmount / (plan.totalDays / 7).ceil());
    final stepIntervalDays = plan.presetConfig['stepIntervalDays'] as int? ?? 7;
    
    final stepsSinceStart = (daysSinceStart / stepIntervalDays).floor();
    final target = plan.startingAmount - (stepReduction * stepsSinceStart);
    return target.clamp(0.0, plan.startingAmount);
  }

  static double _calculateCustomTarget(TaperPlan plan, int daysSinceStart) {
    final dailyTargetsRaw = plan.presetConfig['dailyTargets'];
    if (dailyTargetsRaw == null) return 0.0;
    
    final customTargets = <String, double>{};
    if (dailyTargetsRaw is Map) {
      dailyTargetsRaw.forEach((key, value) {
        if (key is String && value is num) {
          customTargets[key] = value.toDouble();
        }
      });
    }
    
    return customTargets[daysSinceStart.toString()] ?? 0.0;
  }

  static Map<int, double> _interpolateCustomTargets(Map<int, double> customTargets, int totalDays, double startingAmount) {
    final result = <int, double>{};
    final targets = Map<int, double>.from(customTargets);
    
    // Ensure first and last days are set
    if (!targets.containsKey(0)) {
      targets[0] = startingAmount;
    }
    if (!targets.containsKey(totalDays - 1)) {
      targets[totalDays - 1] = 0.0;
    }
    
    final sortedKeys = targets.keys.toList()..sort();
    
    for (int day = 0; day < totalDays; day++) {
      if (targets.containsKey(day)) {
        result[day] = targets[day]!;
      } else {
        // Find surrounding set points for interpolation
        int? beforeKey, afterKey;
        
        for (final key in sortedKeys) {
          if (key < day) beforeKey = key;
          if (key > day && afterKey == null) afterKey = key;
        }
        
        if (beforeKey != null && afterKey != null) {
          // Interpolate between two points
          final beforeValue = targets[beforeKey]!;
          final afterValue = targets[afterKey]!;
          final progress = (day - beforeKey) / (afterKey - beforeKey);
          result[day] = beforeValue + (afterValue - beforeValue) * progress;
        } else if (beforeKey != null) {
          // Extrapolate from the last point
          result[day] = targets[beforeKey]!;
        } else if (afterKey != null) {
          // Extrapolate from the first point
          result[day] = targets[afterKey]!;
        } else {
          // No points set, use linear from start to end
          final progress = day / (totalDays - 1);
          result[day] = startingAmount * (1 - progress);
        }
      }
    }
    
    return result;
  }

  static Map<DateTime, double> generateFullSchedule(TaperPlan plan) {
    final schedule = <DateTime, double>{};
    
    for (int i = 0; i < plan.totalDays; i++) {
      final date = plan.startDate.add(Duration(days: i));
      // Normalize the date key to midnight to match calendar display
      final dateKey = DateTime(date.year, date.month, date.day);
      schedule[dateKey] = calculateTargetForDay(plan, date);
    }
    
    return schedule;
  }

  static TaperPlan createLinearPlan({
    required String id,
    required DateTime startDate,
    required int durationWeeks,
    required double startingAmount,
  }) {
    final endDate = startDate.add(Duration(days: (durationWeeks * 7) - 1));
    
    return TaperPlan(
      id: id,
      startDate: startDate,
      endDate: endDate,
      startingAmount: startingAmount,
      preset: TaperPreset.linear,
      createdAt: DateTime.now(),
    );
  }

  static TaperPlan createStepDownPlan({
    required String id,
    required DateTime startDate,
    required int durationWeeks,
    required double startingAmount,
    required double stepReduction,
    int stepIntervalDays = 7,
  }) {
    // Calculate actual number of steps needed
    final stepsNeeded = (startingAmount / stepReduction).ceil();
    // End date is the day after the last step period
    final endDate = startDate.add(Duration(days: (stepsNeeded * stepIntervalDays)));
    
    return TaperPlan(
      id: id,
      startDate: startDate,
      endDate: endDate,
      startingAmount: startingAmount,
      preset: TaperPreset.stepDown,
      presetConfig: {
        'stepReduction': stepReduction,
        'stepIntervalDays': stepIntervalDays,
      },
      createdAt: DateTime.now(),
    );
  }

  static TaperPlan createCustomPlan({
    required String id,
    required DateTime startDate,
    required DateTime endDate,
    required double startingAmount,
    required Map<int, double> customTargets, // day index -> target
  }) {
    final totalDays = endDate.difference(startDate).inDays + 1;
    final interpolatedTargets = _interpolateCustomTargets(customTargets, totalDays, startingAmount);
    
    final dailyTargets = <String, double>{};
    for (int i = 0; i < totalDays; i++) {
      dailyTargets[i.toString()] = interpolatedTargets[i] ?? 0.0;
    }
    
    return TaperPlan(
      id: id,
      startDate: startDate,
      endDate: endDate,
      startingAmount: startingAmount,
      preset: TaperPreset.custom,
      presetConfig: {
        'dailyTargets': dailyTargets,
      },
      createdAt: DateTime.now(),
    );
  }

  static double calculateCurrentIntake(List<dynamic> recentEvents, {int dayLookback = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: dayLookback));
    final recentCaffeineEvents = recentEvents.where((event) {
      final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
      return eventDate.isAfter(cutoffDate);
    }).toList();

    if (recentCaffeineEvents.isEmpty) {
      return 200.0; // Default fallback
    }

    final dailyTotals = <DateTime, double>{};
    for (final event in recentCaffeineEvents) {
      final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
      final day = DateTime(eventDate.year, eventDate.month, eventDate.day);
      dailyTotals.update(day, (value) => value + event.value, ifAbsent: () => event.value);
    }

    if (dailyTotals.isEmpty) {
      return 200.0; // Default fallback
    }

    final averageIntake = dailyTotals.values.reduce((a, b) => a + b) / dailyTotals.length;
    return averageIntake;
  }
}
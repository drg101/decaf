import 'package:decaf/constants/colors.dart';
import 'package:decaf/main.dart';
import 'package:decaf/providers/events_provider.dart';
import 'package:decaf/providers/settings_provider.dart';
import 'package:decaf/providers/taper_plan_provider.dart';
import 'package:decaf/utils/taper_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePlanProgress extends ConsumerWidget {
  const HomePlanProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    
    return settingsAsync.when(
      data: (settings) {
        if (!settings.taperPlanningEnabled) {
          return _buildPlanAdvertisement(context, ref);
        }
        
        final planAsync = ref.watch(taperPlanProvider);
        return planAsync.when(
          data: (plan) {
            if (plan != null) {
              return _buildPlanProgress(context, ref, plan);
            } else {
              return _buildNoPlanPrompt(context, ref);
            }
          },
          loading: () => const SizedBox.shrink(),
          error: (error, _) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildPlanAdvertisement(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.caffeine.withValues(alpha: 0.1),
            AppColors.caffeine.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.caffeine.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.caffeine.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: AppColors.caffeine,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan Your Taper Journey',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reduce caffeine gradually with personalized schedules',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Free for now!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ref.read(settingsProvider.notifier).enableTaperPlanning();
                  // Navigate to Plan tab
                  ref.read(pageIndexProvider.notifier).state = 1;
                },
                child: const Text('Get Started'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlanPrompt(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        // Navigate to Plan tab
        ref.read(pageIndexProvider.notifier).state = 1;
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month,
              color: AppColors.caffeine,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to Create Your Plan?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to start your personalized taper journey',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanProgress(BuildContext context, WidgetRef ref, plan) {
    final eventsAsync = ref.watch(eventsProvider);
    
    return eventsAsync.when(
      data: (events) {
        final today = DateTime.now();
        final todayKey = DateTime(today.year, today.month, today.day);
        final todayTarget = TaperCalculator.calculateTargetForDay(plan, todayKey);
        final todayActual = _getActualCaffeineForDay(events, todayKey);
        
        final daysElapsed = today.difference(plan.startDate).inDays + 1;
        final totalDays = plan.totalDays;
        final progress = (daysElapsed / totalDays).clamp(0.0, 1.0);
        final isOnTrack = todayActual <= todayTarget + 25; // 25mg tolerance
        
        return GestureDetector(
          onTap: () {
            // Navigate to Plan tab
            ref.read(pageIndexProvider.notifier).state = 1;
          },
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isOnTrack 
                  ? Colors.green.withValues(alpha: 0.05)
                  : Colors.orange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOnTrack 
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.orange.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    isOnTrack ? Icons.check_circle : Icons.warning,
                    color: isOnTrack ? Colors.green : Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Taper Plan Progress',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Day $daysElapsed of $totalDays',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isOnTrack ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOnTrack ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTodayMetric(
                      context,
                      'Target',
                      '${todayTarget.toStringAsFixed(0)}mg',
                      Colors.grey[600]!,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _buildTodayMetric(
                      context,
                      'Actual',
                      '${todayActual.toStringAsFixed(0)}mg',
                      isOnTrack ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildTodayMetric(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  double _getActualCaffeineForDay(List<Event> events, DateTime date) {
    final dayEvents = events.where((event) {
      if (event.type != EventType.caffeine) return false;
      final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
      return eventDate.year == date.year &&
             eventDate.month == date.month &&
             eventDate.day == date.day;
    });
    
    return dayEvents.fold(0.0, (sum, event) => sum + event.value);
  }
}
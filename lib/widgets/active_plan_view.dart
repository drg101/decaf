import 'package:decaf/constants/colors.dart';
import 'package:decaf/models/taper_plan.dart';
import 'package:decaf/providers/events_provider.dart';
import 'package:decaf/providers/taper_plan_provider.dart';
import 'package:decaf/utils/taper_calculator.dart';
import 'package:decaf/widgets/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivePlanView extends ConsumerStatefulWidget {
  final TaperPlan plan;

  const ActivePlanView({
    super.key,
    required this.plan,
  });

  @override
  ConsumerState<ActivePlanView> createState() => _ActivePlanViewState();
}

class _ActivePlanViewState extends ConsumerState<ActivePlanView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Taper Plan'),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Text('Reset Plan'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Calendar', icon: Icon(Icons.calendar_month)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          CalendarView(plan: widget.plan),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final eventsAsync = ref.watch(eventsProvider);
    
    return eventsAsync.when(
      data: (events) => _buildOverviewContent(events),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildOverviewContent(List<Event> events) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final todayTarget = TaperCalculator.calculateTargetForDay(widget.plan, todayKey);
    final todayActual = _getActualCaffeineForDay(events, todayKey);
    
    final daysElapsed = today.difference(widget.plan.startDate).inDays + 1;
    final totalDays = widget.plan.totalDays;
    final progress = (daysElapsed / totalDays).clamp(0.0, 1.0);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress overview
          _buildProgressCard(progress, daysElapsed, totalDays),
          
          const SizedBox(height: 16),
          
          // Today's target vs actual
          _buildTodayCard(todayTarget, todayActual),
          
          const SizedBox(height: 16),
          
          // Plan details
          _buildPlanDetailsCard(),
          
          const SizedBox(height: 16),
          
          // Recent adherence
          _buildAdherenceCard(events),
          
          const SizedBox(height: 50), // Bottom padding for FAB
        ],
      ),
    );
  }

  Widget _buildProgressCard(double progress, int daysElapsed, int totalDays) {
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(1); // Navigate to calendar tab (index 1)
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.caffeine),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Day $daysElapsed of $totalDays'),
                  Text('${(progress * 100).toStringAsFixed(0)}%'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCard(double target, double actual) {
    final isOnTrack = actual <= target + 25; // 25mg tolerance
    
    return Card(
      color: isOnTrack 
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.orange.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOnTrack ? Icons.check_circle : Icons.warning,
                  color: isOnTrack ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTodayMetric(
                    'Target',
                    '${target.toStringAsFixed(0)}mg',
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
                    'Actual',
                    '${actual.toStringAsFixed(0)}mg',
                    isOnTrack ? Colors.green : Colors.orange,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildTodayMetric(
                    'Difference',
                    '${(actual - target).toStringAsFixed(0)}mg',
                    actual <= target ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayMetric(String label, String value, Color color) {
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Method', widget.plan.preset.displayName),
            _buildDetailRow('Starting Amount', '${widget.plan.startingAmount.toStringAsFixed(0)}mg'),
            _buildDetailRow('Target Amount', '0mg'),
            _buildDetailRow('Start Date', _formatDate(widget.plan.startDate)),
            _buildDetailRow('End Date', _formatDate(widget.plan.endDate)),
            _buildDetailRow('Duration', '${widget.plan.totalDays} days'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceCard(List<Event> events) {
    final schedule = TaperCalculator.generateFullSchedule(widget.plan);
    final recentDays = _getLast7Days();
    int onTrackDays = 0;
    int totalDays = 0;

    for (final date in recentDays) {
      final today = DateTime.now();
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      final isFuture = date.isAfter(today) && !isToday;
      
      if (date.isBefore(widget.plan.startDate) || isFuture) {
        continue;
      }
      
      final target = schedule[date] ?? 0;
      final actual = _getActualCaffeineForDay(events, date);
      
      totalDays++;
      if (actual <= target + 25) {
        onTrackDays++;
      }
    }

    final adherenceRate = totalDays > 0 ? (onTrackDays / totalDays) : 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Adherence (7 days)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        totalDays > 0 ? '${(adherenceRate * 100).toStringAsFixed(0)}%' : '—',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: totalDays > 0 ? (adherenceRate >= 0.8 ? Colors.green : 
                                 adherenceRate >= 0.6 ? Colors.orange : Colors.red) : Colors.grey[600],
                        ),
                      ),
                      Text(
                        totalDays > 0 ? '$onTrackDays of $totalDays days on track' : 'No recent data, keep going!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: totalDays > 0 ? adherenceRate : 0.0,
                  backgroundColor: Colors.grey.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    totalDays > 0 ? (adherenceRate >= 0.8 ? Colors.green : 
                    adherenceRate >= 0.6 ? Colors.orange : Colors.red) : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
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


  List<DateTime> _getLast7Days() {
    final today = DateTime.now();
    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return DateTime(date.year, date.month, date.day);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleMenuAction(String action) {
    if (action == 'reset') {
      _showResetDialog();
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Plan'),
        content: const Text('Are you sure you want to reset your taper plan? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(taperPlanProvider.notifier).deactivateCurrentPlan();
              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset Plan'),
          ),
        ],
      ),
    );
  }
}
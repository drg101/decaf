import 'package:decaf/constants/colors.dart';
import 'package:decaf/models/taper_plan.dart';
import 'package:decaf/providers/events_provider.dart';
import 'package:decaf/utils/taper_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarView extends ConsumerStatefulWidget {
  final TaperPlan plan;
  final Function(DateTime)? onDateSelected;

  const CalendarView({
    super.key,
    required this.plan,
    this.onDateSelected,
  });

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.plan.startDate.year, widget.plan.startDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    
    return eventsAsync.when(
      data: (events) => _buildCalendar(events),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildCalendar(List<Event> events) {
    final schedule = TaperCalculator.generateFullSchedule(widget.plan);
    
    return Column(
      children: [
        _buildHeader(),
        _buildWeekDayHeaders(),
        Expanded(
          child: _buildCalendarGrid(events, schedule),
        ),
        _buildLegend(),
        const SizedBox(height: 50), // Bottom padding for FAB
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            _formatMonth(_currentMonth),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDayHeaders() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: weekdays.map((day) => 
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
    );
  }

  Widget _buildCalendarGrid(List<Event> events, Map<DateTime, double> schedule) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday;
    
    // Calculate days to show (including leading/trailing days from other months)
    final daysToShow = <DateTime>[];
    
    // Add days from previous month
    for (int i = firstDayOfWeek - 1; i > 0; i--) {
      daysToShow.add(firstDayOfMonth.subtract(Duration(days: i)));
    }
    
    // Add days from current month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      daysToShow.add(DateTime(_currentMonth.year, _currentMonth.month, day));
    }
    
    // Add days from next month to fill the grid
    while (daysToShow.length % 7 != 0) {
      final lastDay = daysToShow.last;
      daysToShow.add(lastDay.add(const Duration(days: 1)));
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: daysToShow.length,
      itemBuilder: (context, index) {
        final date = daysToShow[index];
        return _buildCalendarDay(date, events, schedule);
      },
    );
  }

  Widget _buildCalendarDay(DateTime date, List<Event> events, Map<DateTime, double> schedule) {
    final isCurrentMonth = date.month == _currentMonth.month;
    final isToday = _isSameDay(date, DateTime.now());
    final isSelected = _selectedDate != null && _isSameDay(date, _selectedDate!);
    final isPlanActive = _isDateInPlan(date);
    final isLastDay = _isSameDay(date, widget.plan.endDate);
    
    final dayKey = DateTime(date.year, date.month, date.day);
    final targetAmount = schedule[dayKey] ?? 0.0;
    final actualAmount = _getActualCaffeineForDay(events, date);
    
    final adherenceStatus = _getAdherenceStatus(targetAmount, actualAmount, isPlanActive, date);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        widget.onDateSelected?.call(date);
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _getDayBackgroundColor(adherenceStatus, isSelected, isToday),
          border: _getDayBorder(isSelected, isToday),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLastDay) ...[
              const Text(
                '🎉',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              date.day.toString(),
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isCurrentMonth 
                    ? (isSelected || isToday ? Colors.white : _getDayTextColor(adherenceStatus))
                    : Colors.grey,
                fontSize: 14,
              ),
            ),
            if (isPlanActive && targetAmount > 0) ...[
              const SizedBox(height: 2),
              Text(
                '${targetAmount.toStringAsFixed(0)}mg',
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrentMonth 
                      ? (isSelected || isToday ? Colors.white70 : Colors.grey[600])
                      : Colors.grey,
                ),
              ),
            ],
            if (actualAmount > 0) ...[
              const SizedBox(height: 1),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected || isToday ? Colors.white : _getAdherenceDotColor(adherenceStatus),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(Colors.green, 'On Track'),
              _buildLegendItem(Colors.orange, 'Close'),
              _buildLegendItem(Colors.red, 'Over Target'),
              _buildLegendItem(Colors.grey, 'No Data'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Target amounts shown below dates • Dots indicate logged caffeine',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  bool _isDateInPlan(DateTime date) {
    return date.isAfter(widget.plan.startDate.subtract(const Duration(days: 1))) &&
           date.isBefore(widget.plan.endDate.add(const Duration(days: 1)));
  }

  double _getActualCaffeineForDay(List<Event> events, DateTime date) {
    final dayEvents = events.where((event) {
      if (event.type != EventType.caffeine) return false;
      final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
      return _isSameDay(eventDate, date);
    });
    
    return dayEvents.fold(0.0, (sum, event) => sum + event.value);
  }


  AdherenceStatus _getAdherenceStatus(double target, double actual, bool isPlanActive, DateTime date) {
    if (!isPlanActive) return AdherenceStatus.notInPlan;
    
    // Future dates should show as no data
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final isFuture = date.isAfter(today) && !isToday;
    if (isFuture) return AdherenceStatus.noData;
    
    final difference = actual - target;
    if (difference <= 25) return AdherenceStatus.onTrack;
    if (difference <= 50) return AdherenceStatus.close;
    return AdherenceStatus.overTarget;
  }

  Color _getDayBackgroundColor(AdherenceStatus status, bool isSelected, bool isToday) {
    if (isSelected) return AppColors.caffeine;
    if (isToday) return AppColors.caffeine.withValues(alpha: 0.7);
    
    switch (status) {
      case AdherenceStatus.onTrack:
        return Colors.green.withValues(alpha: 0.1);
      case AdherenceStatus.close:
        return Colors.orange.withValues(alpha: 0.1);
      case AdherenceStatus.overTarget:
        return Colors.red.withValues(alpha: 0.1);
      case AdherenceStatus.noData:
      case AdherenceStatus.notInPlan:
        return Colors.transparent;
    }
  }

  Border? _getDayBorder(bool isSelected, bool isToday) {
    if (isSelected) return Border.all(color: AppColors.caffeine, width: 2);
    if (isToday) return Border.all(color: AppColors.caffeine.withValues(alpha: 0.7), width: 2);
    return null;
  }

  Color _getDayTextColor(AdherenceStatus status) {
    switch (status) {
      case AdherenceStatus.onTrack:
        return Colors.green;
      case AdherenceStatus.close:
        return Colors.orange;
      case AdherenceStatus.overTarget:
        return Colors.red;
      case AdherenceStatus.noData:
      case AdherenceStatus.notInPlan:
        return Colors.black;
    }
  }

  Color _getAdherenceDotColor(AdherenceStatus status) {
    switch (status) {
      case AdherenceStatus.onTrack:
        return Colors.green;
      case AdherenceStatus.close:
        return Colors.orange;
      case AdherenceStatus.overTarget:
        return Colors.red;
      case AdherenceStatus.noData:
      case AdherenceStatus.notInPlan:
        return Colors.grey;
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  String _formatMonth(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

enum AdherenceStatus {
  onTrack,
  close,
  overTarget,
  noData,
  notInPlan,
}
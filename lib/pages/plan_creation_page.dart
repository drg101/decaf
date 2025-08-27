import 'package:decaf/constants/colors.dart';
import 'package:decaf/models/taper_plan.dart';
import 'package:decaf/models/taper_preset.dart';
import 'package:decaf/providers/events_provider.dart';
import 'package:decaf/providers/taper_plan_provider.dart';
import 'package:decaf/utils/analytics.dart';
import 'package:decaf/utils/taper_calculator.dart';
import 'package:decaf/widgets/preset_selector.dart';
import 'package:decaf/widgets/custom_taper_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlanCreationPage extends ConsumerStatefulWidget {
  const PlanCreationPage({super.key});

  @override
  ConsumerState<PlanCreationPage> createState() => _PlanCreationPageState();
}

class _PlanCreationPageState extends ConsumerState<PlanCreationPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Form data
  TaperPreset? _selectedPreset;
  DateTime _startDate = DateTime.now();
  int _durationWeeks = 4;
  double? _startingAmount;
  double _stepDownAmount = 50.0;
  int _stepDownIntervalDays = 7;
  Map<int, double> _customTargets = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculateStartingAmount();
  }

  void _calculateStartingAmount() {
    final eventsAsync = ref.read(eventsProvider);
    eventsAsync.whenData((events) {
      final caffeineEvents = events.where((e) => e.type == EventType.caffeine).toList();
      final calculated = TaperCalculator.calculateCurrentIntake(caffeineEvents);
      setState(() {
        _startingAmount = calculated;
      });
    });
  }

  int _calculateStepDownDuration() {
    if (_startingAmount == null || _stepDownAmount <= 0) return 4;
    final steps = (_startingAmount! / _stepDownAmount).ceil();
    return ((steps * _stepDownIntervalDays) / 7).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Taper Plan'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: List.generate(3, (index) {
                final isActive = index <= _currentStep;
                
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive 
                          ? AppColors.caffeine
                          : Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildPresetSelectionStep(),
                _buildConfigurationStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          
          // Navigation buttons
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _isLoading ? null : _previousStep,
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.caffeine,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(_currentStep == 2 ? 'Create Plan' : 'Next'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: Choose Your Method',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select how you want to reduce your caffeine intake.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          PresetSelector(
            selectedPreset: _selectedPreset,
            onPresetSelected: (preset) {
              Analytics.track(
                AnalyticsEvent.selectTaperPreset,
                {'preset': preset.name},
              );
              setState(() {
                _selectedPreset = preset;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Configure Your Plan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your timeline and starting amount.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Starting amount
          _buildConfigCard(
            'Starting Amount',
            'Based on your recent intake',
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _startingAmount?.toStringAsFixed(0) ?? '',
                        decoration: const InputDecoration(
                          suffix: Text('mg'),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) {
                          final newAmount = double.tryParse(value) ?? 0;
                          if (_startingAmount != null && newAmount != _startingAmount) {
                            Analytics.track(
                              AnalyticsEvent.modifyStartingAmount,
                              {
                                'original_amount': _startingAmount ?? 0,
                                'new_amount': newAmount,
                              },
                            );
                          }
                          _startingAmount = newAmount;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Start date
          _buildConfigCard(
            'Start Date',
            'When to begin your taper',
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_formatDate(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectStartDate,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Duration
          if (_selectedPreset != TaperPreset.stepDown)
            _buildConfigCard(
              'Duration',
              'How long to take reducing to 0mg',
              Column(
                children: [
                  Slider(
                    value: _durationWeeks.toDouble(),
                    min: 2,
                    max: 12,
                    divisions: 10,
                    label: '$_durationWeeks weeks',
                    onChanged: (value) {
                      final newDuration = value.toInt();
                      if (newDuration != _durationWeeks) {
                        Analytics.track(
                          AnalyticsEvent.adjustPlanDuration,
                          {
                            'old_duration_weeks': _durationWeeks,
                            'new_duration_weeks': newDuration,
                          },
                        );
                      }
                      setState(() {
                        _durationWeeks = newDuration;
                      });
                    },
                  ),
                  Text('$_durationWeeks weeks'),
                ],
              ),
            )
          else
            _buildConfigCard(
              'Duration',
              'Calculated based on reduction amount',
              Text(
                '${_calculateStepDownDuration()} weeks',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.caffeine,
                ),
              ),
            ),
          
          if (_selectedPreset == TaperPreset.stepDown) ...[
            const SizedBox(height: 16),
            _buildConfigCard(
              'Reduction Amount',
              'Amount to reduce each step',
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _stepDownAmount.toStringAsFixed(0),
                      decoration: const InputDecoration(
                        suffix: Text('mg'),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        final newAmount = double.tryParse(value) ?? 50;
                        if (newAmount != _stepDownAmount) {
                          Analytics.track(
                            AnalyticsEvent.configureStepDown,
                            {
                              'step_reduction_amount': newAmount,
                              'step_interval_days': _stepDownIntervalDays,
                            },
                          );
                        }
                        setState(() {
                          _stepDownAmount = newAmount;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildConfigCard(
              'Step Interval',
              'Days between each reduction',
              Column(
                children: [
                  Slider(
                    value: _stepDownIntervalDays.toDouble(),
                    min: 1,
                    max: 14,
                    divisions: 13,
                    label: '$_stepDownIntervalDays days',
                    onChanged: (value) {
                      final newInterval = value.toInt();
                      if (newInterval != _stepDownIntervalDays) {
                        Analytics.track(
                          AnalyticsEvent.configureStepDown,
                          {
                            'step_reduction_amount': _stepDownAmount,
                            'step_interval_days': newInterval,
                          },
                        );
                      }
                      setState(() {
                        _stepDownIntervalDays = newInterval;
                      });
                    },
                  ),
                  Text('$_stepDownIntervalDays days'),
                ],
              ),
            ),
          ],
          
          if (_selectedPreset == TaperPreset.custom) ...[
            const SizedBox(height: 16),
            if (_startingAmount != null)
              CustomTaperEditor(
                startDate: _startDate,
                endDate: _startDate.add(Duration(days: (_durationWeeks * 7) - 1)),
                startingAmount: _startingAmount!,
                customTargets: _customTargets,
                onTargetsChanged: (targets) {
                  Analytics.track(
                    AnalyticsEvent.customizeTargets,
                    {
                      'custom_targets_count': targets.length,
                      'duration_weeks': _durationWeeks,
                    },
                  );
                  setState(() {
                    _customTargets = targets;
                  });
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    if (_startingAmount == null || _selectedPreset == null) {
      return const Center(child: Text('Invalid configuration'));
    }

    final plan = _createPlanFromConfiguration();
    final schedule = TaperCalculator.generateFullSchedule(plan);
    final sortedDates = schedule.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3: Review Your Plan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your taper plan before creating it.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Plan summary
          _buildConfigCard(
            'Plan Summary',
            '',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow('Method', _selectedPreset!.displayName),
                _buildSummaryRow('Starting Amount', '${_startingAmount!.toStringAsFixed(0)}mg'),
                _buildSummaryRow('Target Amount', '0mg'),
                _buildSummaryRow('Duration', '$_durationWeeks weeks'),
                _buildSummaryRow('Start Date', _formatDate(_startDate)),
                _buildSummaryRow('End Date', _formatDate(plan.endDate)),
                if (_selectedPreset == TaperPreset.stepDown)
                  _buildSummaryRow('Weekly Reduction', '${_stepDownAmount.toStringAsFixed(0)}mg'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Schedule preview
          _buildConfigCard(
            'Schedule Preview',
            'First few days of your plan',
            Column(
              children: sortedDates.take(7).map((date) {
                final target = schedule[date]!;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDateShort(date)),
                      Text('${target.toStringAsFixed(0)}mg'),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(String title, String subtitle, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateShort(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]} ${date.day}/${date.month}';
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() async {
    if (_currentStep < 2) {
      if (_currentStep == 0 && _selectedPreset == null) {
        _showSnackBar('Please select a taper method');
        return;
      }
      
      if (_currentStep == 1 && (_startingAmount == null || _startingAmount! <= 0)) {
        _showSnackBar('Please enter a valid starting amount');
        return;
      }
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _createPlan();
    }
  }

  TaperPlan _createPlanFromConfiguration() {
    switch (_selectedPreset!) {
      case TaperPreset.linear:
        return TaperCalculator.createLinearPlan(
          id: '',
          startDate: _startDate,
          durationWeeks: _durationWeeks,
          startingAmount: _startingAmount!,
        );
      case TaperPreset.stepDown:
        return TaperCalculator.createStepDownPlan(
          id: '',
          startDate: _startDate,
          durationWeeks: _calculateStepDownDuration(),
          startingAmount: _startingAmount!,
          stepReduction: _stepDownAmount,
          stepIntervalDays: _stepDownIntervalDays,
        );
      case TaperPreset.custom:
        return TaperCalculator.createCustomPlan(
          id: '',
          startDate: _startDate,
          endDate: _startDate.add(Duration(days: (_durationWeeks * 7) - 1)),
          startingAmount: _startingAmount!,
          customTargets: _customTargets,
        );
    }
  }

  Future<void> _createPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final plan = _createPlanFromConfiguration();
      await ref.read(taperPlanProvider.notifier).createPlan(plan);
      
      Analytics.track(
        AnalyticsEvent.completePlanCreation,
        {
          'preset': _selectedPreset!.name,
          'duration_weeks': _durationWeeks,
          'starting_amount': _startingAmount ?? 0,
          'custom_targets_count': _customTargets.length,
        },
      );
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      _showSnackBar('Failed to create plan: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
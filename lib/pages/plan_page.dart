import 'package:decaf/constants/colors.dart';
import 'package:decaf/pages/plan_creation_page.dart';
import 'package:decaf/providers/settings_provider.dart';
import 'package:decaf/providers/taper_plan_provider.dart';
import 'package:decaf/utils/analytics.dart';
import 'package:decaf/widgets/active_plan_view.dart';
import 'package:decaf/widgets/taper_plan_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    
    return settingsAsync.when(
      data: (settings) {
        if (!settings.taperPlanningEnabled) {
          return const TaperPlanPreview();
        }
        
        // Feature is enabled, check for active plan
        final planAsync = ref.watch(taperPlanProvider);
        
        return planAsync.when(
          data: (plan) {
            if (plan != null) {
              return ActivePlanView(plan: plan);
            } else {
              return _buildNoPlanView(context, ref);
            }
          },
          loading: () => _buildLoadingView(),
          error: (error, stackTrace) => _buildErrorView(error),
        );
      },
      loading: () => _buildLoadingView(),
      error: (error, stackTrace) => _buildErrorView(error),
    );
  }

  Widget _buildNoPlanView(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.caffeine.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.calendar_month,
                size: 64,
                color: AppColors.caffeine,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ready to Start Your Taper?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Create a personalized plan to gradually reduce your caffeine intake and minimize withdrawal symptoms.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Analytics.track(AnalyticsEvent.startPlanCreation);
                  _navigateToCreatePlan(context, ref);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.caffeine,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Create Taper Plan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _showPlanInfo(context),
              child: const Text('Learn more about taper planning'),
            ),
            const SizedBox(height: 50), // Bottom padding for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Trigger a refresh by accessing the provider again
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreatePlan(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const PlanCreationPage(),
      ),
    );
    
    if (result == true) {
      // Plan was created successfully, the provider will automatically update
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Taper plan created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showPlanInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Taper Planning'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Taper planning helps you reduce caffeine gradually to minimize withdrawal symptoms like:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Headaches\n• Fatigue\n• Brain fog\n• Irritability'),
              SizedBox(height: 16),
              Text(
                'Our plans use proven methods:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('📉 Linear Taper: Smooth daily reduction\n🪜 Step Down: Weekly reductions\n🎯 Custom: Your own schedule'),
              SizedBox(height: 16),
              Text(
                'Track your progress with visual calendars and charts to stay motivated!',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
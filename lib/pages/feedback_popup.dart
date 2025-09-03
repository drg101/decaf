import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:decaf/utils/analytics.dart';

class FeedbackPopupPage extends ConsumerStatefulWidget {
  const FeedbackPopupPage({super.key});

  @override
  ConsumerState<FeedbackPopupPage> createState() => _FeedbackPopupPageState();
}

class _AnimatedGradientButton extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onPressed;
  final Widget icon;
  final Widget label;

  const _AnimatedGradientButton({
    required this.animation,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: SweepGradient(
              colors: const [
                Colors.pink,
                Colors.pinkAccent,
                Colors.pink,
                Colors.pinkAccent,
              ],
              stops: const [0.0, 0.5, 1.0, 1.5],
              transform: GradientRotation(animation.value * 2 * 3.14159),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: icon,
            label: label,
            onPressed: onPressed,
          ),
        );
      },
    );
  }
}

class _FeedbackPopupPageState extends ConsumerState<FeedbackPopupPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '☕️',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Enjoying Decaf?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Decaf is completely free and open source! If you\'re finding it helpful on your caffeine journey, we\'d really appreciate your support.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.star),
                label: const Text('Star on GitHub'),
                onPressed: () async {
                  Analytics.track(AnalyticsEvent.starOnGithubFromPopup);
                  final Uri url = Uri.parse('https://github.com/drg101/decaf');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(height: 12),
            _AnimatedGradientButton(
              animation: _animation,
              icon: const Icon(Icons.favorite),
              label: const Text('Leave Review'),
              onPressed: () async {
                Analytics.track(AnalyticsEvent.requestAppReviewFromPopup);
                final InAppReview inAppReview = InAppReview.instance;
                
                if (await inAppReview.isAvailable()) {
                  inAppReview.requestReview();
                } else {
                  inAppReview.openStoreListing();
                }
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Maybe later'),
            ),
          ],
        ),
      ),
    );
  }
}
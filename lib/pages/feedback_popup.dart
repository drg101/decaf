import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:decaf/utils/analytics.dart';

class FeedbackPopupPage extends ConsumerWidget {
  const FeedbackPopupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
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
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
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
                ),
              ],
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
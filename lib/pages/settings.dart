import 'package:decaf/pages/manage_caffeine_options.dart';
import 'package:decaf/pages/manage_symptoms_page.dart';
import 'package:decaf/providers/caffeine_options_provider.dart';
import 'package:decaf/providers/symptoms_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decaf/providers/events_provider.dart';
import 'package:decaf/privacy_policy.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset Account'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Reset'),
                    content: const Text(
                      'Are you sure you want to reset your account? This action cannot be undone.',
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Reset'),
                        onPressed: () async {
                          // Clear all user events
                          await ref.read(eventsProvider.notifier).clearAllEvents();
                          
                          // Reset caffeine options and symptoms to their default state
                          // This will re-enable default options and disable extras
                          final caffeineNotifier = ref.read(caffeineOptionsProvider.notifier);
                          final symptomsNotifier = ref.read(symptomsProvider.notifier);
                          
                          await caffeineNotifier.resetToDefaults();
                          await symptomsNotifier.resetToDefaults();
                          
                          Navigator.of(context).pop(); // Close the dialog
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.coffee),
            title: const Text('Manage Caffeine Options'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ManageCaffeineOptionsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.medical_services),
            title: const Text('Manage Symptoms'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ManageSymptomsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Leave us a Review'),
            onTap: () async {
              final InAppReview inAppReview = InAppReview.instance;
              
              if (await inAppReview.isAvailable()) {
                inAppReview.requestReview();
              } else {
                inAppReview.openStoreListing();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Star Decaf on Github'),
            onTap: () async {
              final Uri url = Uri.parse('https://github.com/drg101/decaf');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
        ],
      ),
    );
  }
}

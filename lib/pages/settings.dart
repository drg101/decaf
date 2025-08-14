import 'package:decaf/pages/manage_caffeine_options.dart';
import 'package:decaf/pages/manage_symptoms_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decaf/providers/events_provider.dart';

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
                        onPressed: () {
                          ref.read(eventsProvider.notifier).clearAllEvents();
                          Navigator.of(context).pop(); // Close the dialog
                          Navigator.of(context).pop(); // Pop the settings page
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
        ],
      ),
    );
  }
}

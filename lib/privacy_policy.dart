import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: 2025',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Data Collection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'We do not collect, store, or transmit any personal data. Our application operates entirely locally on your device and does not send any information to external servers.',
            ),
            SizedBox(height: 24),
            Text(
              'Information We Do Not Collect',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('• Personal identification information'),
            Text('• Usage data or analytics'),
            Text('• Device information'),
            Text('• Location data'),
            Text('• Cookies or tracking technologies'),
            SizedBox(height: 24),
            Text(
              'Data Storage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'All application data is stored locally on your device. No data is transmitted to or stored on external servers.',
            ),
            SizedBox(height: 24),
            Text(
              'Third-Party Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Our application does not integrate with any third-party services that collect user data.',
            ),
            SizedBox(height: 24),
            Text(
              'Changes to This Policy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'We may update this privacy policy from time to time. Any changes will be reflected in the application and indicated by updating the "Last updated" date.',
            ),
            SizedBox(height: 24),
            Text(
              'Contact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'If you have any questions about this privacy policy, please contact us at admin@rootcauseapp.org.',
            ),
          ],
        ),
      ),
    );
  }
}
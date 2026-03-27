import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalScreen({super.key, required this.title, required this.content});

  static const termsOfService = '''
Terms of Service

Last updated: March 2026

1. Acceptance of Terms

By accessing or using TaskEngine ("the App"), you agree to be bound by these Terms of Service. If you do not agree, do not use the App.

2. Description of Service

TaskEngine is a student productivity application that helps users manage academic assignments, track study sessions, and monitor workload. The App integrates with Moodle calendar exports to import assignment data.

3. User Accounts

You must provide accurate information when creating an account. You are responsible for maintaining the confidentiality of your login credentials. You must notify us immediately of any unauthorized use of your account.

4. Acceptable Use

You agree not to:
- Use the App for any unlawful purpose
- Attempt to gain unauthorized access to the App's systems
- Interfere with other users' access to the App
- Upload malicious content or code
- Use the App to store sensitive personal data beyond what is required for its functionality

5. Moodle Integration

The App accesses Moodle calendar data through ICS URLs you provide. You are responsible for ensuring you have permission to export and use this data. The App stores your ICS URL in encrypted form and uses it solely to sync your assignment data.

6. Data and Content

Assignment data imported from Moodle remains your data. Study session logs and settings you create within the App are your data. We do not claim ownership of your content.

7. Service Availability

TaskEngine is provided on an "as-is" basis. We do not guarantee uninterrupted or error-free service. The App may be updated, modified, or discontinued at any time.

8. Limitation of Liability

TaskEngine is a productivity tool and should not be your sole method of tracking deadlines. We are not liable for missed assignments, incorrect data imports, or any academic consequences arising from use of the App.

9. Modifications

We reserve the right to modify these terms at any time. Continued use of the App after changes constitutes acceptance of the new terms.

10. Contact

For questions about these terms, contact the TaskEngine development team.
''';

  static const privacyPolicy = '''
Privacy Policy

Last updated: March 2026

1. Information We Collect

Account information: name, email address, and password (stored as a secure hash).
Academic data: assignment titles, due dates, course names, difficulty ratings, and study session logs imported from Moodle or entered manually.
App preferences: notification settings, dark mode preference, and notification lead time.
Moodle ICS URL: stored in AES-256-GCM encrypted form for calendar synchronization.

2. How We Use Your Information

To provide the App's core functionality: assignment tracking, workload analysis, study session logging, and deadline notifications.
To sync your Moodle calendar data when you initiate a sync.
To save your preferences across sessions.
We do not use your data for advertising, profiling, or any purpose beyond the App's functionality.

3. Data Storage and Security

Your data is stored in a PostgreSQL database hosted on Render.
Passwords are hashed using bcrypt and are never stored in plain text.
Moodle ICS URLs are encrypted at rest using AES-256-GCM.
API access requires JWT authentication.
Rate limiting is applied to sensitive endpoints.

4. Data Sharing

We do not sell, rent, or share your personal data with third parties.
Your data is only accessed by the App's backend to provide its services.

5. Data Retention

Your data is retained as long as your account is active.
You can disconnect your Moodle integration at any time, which removes the stored ICS URL.
Deleting your account removes all associated data.

6. Notifications

The App uses local on-device notifications to remind you of upcoming deadlines. Notification scheduling happens entirely on your device. No notification data is sent to external services.

7. Third-Party Services

The App connects to Moodle servers only when you provide an ICS URL and initiate a sync. No other third-party analytics, tracking, or advertising services are used.

8. Your Rights

You can view all data associated with your account within the App.
You can modify your preferences at any time.
You can disconnect Moodle and delete your synced data.
You can request account deletion by contacting the development team.

9. Children's Privacy

The App is intended for university students and is not directed at children under 16.

10. Changes to This Policy

We may update this policy from time to time. Changes will be reflected in the "Last updated" date above.

11. Contact

For privacy-related questions, contact the TaskEngine development team.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _loading = true;
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = await ApiService.getProfile();
      if (!mounted) return;
      setState(() {
        _user = user;
        notificationsEnabled = user.notificationsEnabled;
        darkModeEnabled = user.darkModeEnabled;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _showMoodleDialog() {
    final moodleConnected = _user?.icsUrl != null;
    if (moodleConnected) {
      _showConnectedMoodleDialog();
    } else {
      _showConnectMoodleDialog();
    }
  }

  void _showConnectMoodleDialog() {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        var syncing = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Connect Moodle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Paste your Moodle calendar ICS URL below:'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      hintText: 'https://moodle.example.com/calendar/export_execute.php?…',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !syncing,
                  ),
                  if (syncing) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: syncing ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: syncing
                      ? null
                      : () async {
                          final url = urlController.text.trim();
                          if (url.isEmpty) return;
                          setDialogState(() => syncing = true);
                          try {
                            final result = await ApiService.syncMoodle(url);
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Synced: ${result['created']} created, ${result['updated']} updated',
                                ),
                              ),
                            );
                            _fetchProfile();
                          } catch (e) {
                            if (!mounted) return;
                            setDialogState(() => syncing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Sync failed: $e')),
                            );
                          }
                        },
                  child: const Text('Sync'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showConnectedMoodleDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        var syncing = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Moodle Connected'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _user?.lastSync != null
                        ? 'Last synced: ${_user!.lastSync!.toLocal()}'
                        : 'Connected',
                  ),
                  if (syncing) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: syncing ? null : () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
                OutlinedButton(
                  onPressed: syncing
                      ? null
                      : () async {
                          setDialogState(() => syncing = true);
                          try {
                            await ApiService.disconnectMoodle();
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Moodle disconnected'),
                              ),
                            );
                            _fetchProfile();
                          } catch (e) {
                            if (!mounted) return;
                            setDialogState(() => syncing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Disconnect failed: $e')),
                            );
                          }
                        },
                  child: const Text('Disconnect'),
                ),
                ElevatedButton(
                  onPressed: syncing
                      ? null
                      : () async {
                          final url = _user?.icsUrl;
                          if (url == null) return;
                          setDialogState(() => syncing = true);
                          try {
                            final result = await ApiService.syncMoodle(url);
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Synced: ${result['created']} created, ${result['updated']} updated',
                                ),
                              ),
                            );
                            _fetchProfile();
                          } catch (e) {
                            if (!mounted) return;
                            setDialogState(() => syncing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Sync failed: $e')),
                            );
                          }
                        },
                  child: const Text('Re-sync'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleDisconnect() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => notificationsEnabled = value);
    try {
      await ApiService.updateSettings(notifications: value);
    } catch (e) {
      if (!mounted) return;
      setState(() => notificationsEnabled = !value);
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() => darkModeEnabled = value);
    try {
      await ApiService.updateSettings(darkMode: value);
    } catch (e) {
      if (!mounted) return;
      setState(() => darkModeEnabled = !value);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF167C80);
    const dangerRed = Color(0xFFE53935);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text(
            'Profile',
            style: TextStyle(
              color: Color(0xFF333333),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const BottomNav(currentIndex: 3),
      );
    }

    final moodleConnected = _user?.icsUrl != null;
    final lastSync = _user?.lastSync;
    String moodleSubtitle;
    if (!moodleConnected) {
      moodleSubtitle = 'Not connected';
    } else if (lastSync != null) {
      final diff = DateTime.now().difference(lastSync);
      if (diff.inMinutes < 60) {
        moodleSubtitle = 'Last synced ${diff.inMinutes} min ago';
      } else {
        moodleSubtitle = 'Last synced ${diff.inHours}h ago';
      }
    } else {
      moodleSubtitle = 'Connected';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            // Account section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.name ?? 'Student Name',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF555555),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _showMoodleDialog,
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: moodleConnected
                                      ? primaryTeal
                                      : Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  moodleConnected ? Icons.check : Icons.close,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      moodleConnected
                                          ? 'Moodle Connected'
                                          : 'Moodle Not Connected',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      moodleSubtitle,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF555555),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Settings section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Color(0xFFF4F6F9),
                                  child: Icon(
                                    Icons.notifications,
                                    size: 18,
                                    color: primaryTeal,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notifications',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Get deadline reminders',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF555555),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: notificationsEnabled,
                              activeThumbColor: Colors.white,
                              activeTrackColor: primaryTeal,
                              onChanged: _toggleNotifications,
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Color(0xFFF4F6F9),
                                  child: Icon(
                                    Icons.nightlight_round,
                                    size: 18,
                                    color: primaryTeal,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dark Mode',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Change app appearance',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF555555),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: darkModeEnabled,
                              activeThumbColor: Colors.white,
                              activeTrackColor: primaryTeal,
                              onChanged: _toggleDarkMode,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // About section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'TaskEngine v1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '\u00A9 2026 TaskEngine',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Terms of Service',
                          style: TextStyle(color: primaryTeal),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Privacy Policy',
                          style: TextStyle(color: primaryTeal),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Disconnect button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: dangerRed,
                  side: const BorderSide(color: dangerRed, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _handleDisconnect,
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }
}

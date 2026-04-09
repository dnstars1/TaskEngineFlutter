import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../main.dart';
import '../models/user.dart';
import '../services/ad_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/bottom_nav.dart';
import 'legal_screen.dart';
import 'premium_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _loading = true;
  bool notificationsEnabled = true;
  int notificationLeadTime = 1440;
  bool darkModeEnabled = false;
  InterstitialAd? _interstitialAd;

  static const _leadTimeOptions = [
    (60, '1 hour before'),
    (180, '3 hours before'),
    (720, '12 hours before'),
    (1440, '1 day before'),
    (2880, '2 days before'),
    (10080, '1 week before'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _loadInterstitial();
  }

  void _loadInterstitial() {
    if (!AdService.isSupported || premiumService.isPremium) return;
    InterstitialAd.load(
      adUnitId: AdService.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  Future<void> _fetchProfile() async {
    try {
      final user = await ApiService.getProfile();
      if (!mounted) return;
      setState(() {
        _user = user;
        notificationsEnabled = user.notificationsEnabled;
        notificationLeadTime = user.notificationLeadTime;
        darkModeEnabled = user.darkModeEnabled;
        _loading = false;
      });
      themeNotifier.setDark(user.darkModeEnabled);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _showMoodleDialog() {
    final moodleConnected = _user?.moodleConnected == true;
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
                          final messenger = ScaffoldMessenger.of(ctx);
                          try {
                            final result = await ApiService.syncMoodle(url);
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Synced: ${result['created']} created, ${result['updated']} updated',
                                ),
                              ),
                            );
                            _fetchProfile();
                          } catch (e) {
                            if (!ctx.mounted) return;
                            setDialogState(() => syncing = false);
                            messenger.showSnackBar(
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
                          final messenger = ScaffoldMessenger.of(ctx);
                          try {
                            await ApiService.disconnectMoodle();
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Moodle disconnected'),
                              ),
                            );
                            _fetchProfile();
                          } catch (e) {
                            if (!ctx.mounted) return;
                            setDialogState(() => syncing = false);
                            messenger.showSnackBar(
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
                          setDialogState(() => syncing = true);
                          final messenger = ScaffoldMessenger.of(ctx);
                          try {
                            final result = await ApiService.resyncMoodle();
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Synced: ${result['created']} created, ${result['updated']} updated',
                                ),
                              ),
                            );
                            _fetchProfile();
                          } catch (e) {
                            if (!ctx.mounted) return;
                            setDialogState(() => syncing = false);
                            messenger.showSnackBar(
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
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          ad.dispose();
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        },
      );
      _interstitialAd!.show();
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => notificationsEnabled = value);
    try {
      await ApiService.updateSettings(notifications: value);
      if (value) {
        final assignments = await ApiService.getAssignments();
        await NotificationService.scheduleForAssignments(
          assignments,
          leadTimeMinutes: notificationLeadTime,
        );
      } else {
        await NotificationService.cancelAll();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => notificationsEnabled = !value);
    }
  }

  Future<void> _changeLeadTime(int minutes) async {
    final old = notificationLeadTime;
    setState(() => notificationLeadTime = minutes);
    try {
      await ApiService.updateSettings(notificationLeadTime: minutes);
      if (notificationsEnabled) {
        final assignments = await ApiService.getAssignments();
        await NotificationService.scheduleForAssignments(
          assignments,
          leadTimeMinutes: minutes,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => notificationLeadTime = old);
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() => darkModeEnabled = value);
    themeNotifier.setDark(value);
    try {
      await ApiService.updateSettings(darkMode: value);
    } catch (e) {
      if (!mounted) return;
      setState(() => darkModeEnabled = !value);
      themeNotifier.setDark(!value);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF167C80);
    const dangerRed = Color(0xFFE53935);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final cardColor = Theme.of(context).cardTheme.color;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const BottomNav(currentIndex: 3),
      );
    }

    final moodleConnected = _user?.moodleConnected == true;
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
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            // Account section
            Container(
              decoration: BoxDecoration(
                color: cardColor,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.email ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: onSurfaceVariant,
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
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      moodleSubtitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: onSurfaceVariant,
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
                color: cardColor,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
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
                              children: [
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Color(0xFFF4F6F9),
                                  child: Icon(
                                    Icons.notifications,
                                    size: 18,
                                    color: primaryTeal,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notifications',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Get deadline reminders',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: onSurfaceVariant,
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
                        if (notificationsEnabled) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 40, top: 4, bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 16, color: onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(
                                  'Remind me ',
                                  style: TextStyle(fontSize: 13, color: onSurfaceVariant),
                                ),
                                DropdownButton<int>(
                                  value: notificationLeadTime,
                                  underline: const SizedBox(),
                                  isDense: true,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTeal,
                                  ),
                                  items: _leadTimeOptions.map((opt) {
                                    return DropdownMenuItem(
                                      value: opt.$1,
                                      child: Text(opt.$2),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) _changeLeadTime(value);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Color(0xFFF4F6F9),
                                  child: Icon(
                                    Icons.nightlight_round,
                                    size: 18,
                                    color: primaryTeal,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dark Mode',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Change app appearance',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: onSurfaceVariant,
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

            // Go Premium button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: const Color(0xFF333333),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PremiumScreen()),
                  );
                  setState(() {});
                },
                icon: Icon(
                  premiumService.isPremium
                      ? Icons.workspace_premium
                      : Icons.star_outline,
                ),
                label: Text(
                  premiumService.isPremium ? 'Premium Active' : 'Go Premium',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // About section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
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
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TaskEngine v1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      color: onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\u00A9 2026 TaskEngine',
                    style: TextStyle(
                      fontSize: 13,
                      color: onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LegalScreen(
                              title: 'Terms of Service',
                              content: LegalScreen.termsOfService,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Terms of Service',
                          style: TextStyle(color: primaryTeal),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LegalScreen(
                              title: 'Privacy Policy',
                              content: LegalScreen.privacyPolicy,
                            ),
                          ),
                        ),
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

import 'package:flutter/material.dart';

import '../main.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF167C80);
    final isPremium = premiumService.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Premium',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Icon(
              isPremium ? Icons.workspace_premium : Icons.star_outline,
              size: 80,
              color: isPremium ? const Color(0xFFFFC107) : primaryTeal,
            ),
            const SizedBox(height: 16),
            Text(
              isPremium ? 'You are Premium!' : 'Upgrade to Premium',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPremium
                  ? 'Enjoy your ad-free experience'
                  : 'Remove ads and enjoy a better experience',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            if (!isPremium) ...[
              _benefitTile(Icons.block, 'No advertisements', 'Enjoy an ad-free experience'),
              _benefitTile(Icons.speed, 'Faster experience', 'No loading delays from ads'),
              _benefitTile(Icons.auto_awesome, 'Clean interface', 'Focus on what matters'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: const Color(0xFF333333),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    await premiumService.upgrade();
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Welcome to Premium!'),
                        content: const Text(
                          'You are now a premium user (simulation). Ads have been removed.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    'Upgrade (Mock)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This is a simulation — no real payment required',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ] else ...[
              _benefitTile(Icons.check_circle, 'No advertisements', 'Active'),
              _benefitTile(Icons.check_circle, 'Faster experience', 'Active'),
              _benefitTile(Icons.check_circle, 'Clean interface', 'Active'),
              const SizedBox(height: 32),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                ),
                onPressed: () async {
                  await premiumService.reset();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Premium reset — ads will return')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Reset Premium (Demo)'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _benefitTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF167C80), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

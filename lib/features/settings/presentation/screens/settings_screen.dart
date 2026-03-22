import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../../../profile/data/profile_model.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../../core/storage/secure_storage.dart';

final profileProvider = FutureProvider<ProfileModel>((ref) async {
  return ProfileRepository().getProfile();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SecureStorage.getAccessToken().then((token) {
      print(
        '[Debug] Token in storage: ${token != null ? token.substring(0, 20) + "..." : "NULL"}',
      );
    });

    final silentMode = ref.watch(silentModeProvider);
    final testMode = ref.watch(testModeProvider);
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          // Refresh profile to pick up verification status
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(profileProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Test Mode Section ──────────────────────────────
            const _SectionHeader(title: 'Test Mode'),
            Card(
              child: testMode.when(
                data: (isTest) => SwitchListTile(
                  secondary: Icon(
                    Icons.science_outlined,
                    color: isTest ? Colors.orange : Colors.grey,
                  ),
                  title: const Text('Test Mode'),
                  subtitle: const Text(
                    'Alerts sent only to you — contacts not notified',
                  ),
                  value: isTest,
                  activeColor: Colors.orange,
                  onChanged: (value) =>
                      ref.read(testModeProvider.notifier).setValue(value),
                ),
                loading: () => const ListTile(
                  title: Text('Test Mode'),
                  trailing: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Active test mode warning banner
            testMode.maybeWhen(
              data: (isTest) => isTest
                  ? Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Test Mode is ON. All SOS triggers send '
                              'only to your Telegram. Emergency contacts '
                              'will NOT be notified.',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // ── Connect Your Telegram Section ──────────────────
            const _SectionHeader(title: 'Your Telegram'),
            const Text(
              'Connect your own Telegram account to receive '
              'test alerts. Uses the same verification flow '
              'as your emergency contacts.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),

            profileState.when(
              loading: () => const Card(
                child: ListTile(
                  title: Text('Loading profile...'),
                  trailing: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (e, _) => Card(
                child: ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: const Text('Could not load profile'),
                  subtitle: Text(e.toString()),
                  trailing: TextButton(
                    onPressed: () => ref.invalidate(profileProvider),
                    child: const Text('Retry'),
                  ),
                ),
              ),
              data: (profile) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Connection status row
                      Row(
                        children: [
                          Icon(
                            profile.telegramVerified
                                ? Icons.check_circle
                                : Icons.link_off,
                            color: profile.telegramVerified
                                ? Colors.green
                                : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.telegramVerified
                                      ? 'Telegram Connected'
                                      : 'Telegram Not Connected',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile.telegramVerified
                                      ? 'Test alerts will be sent to your Telegram'
                                      : 'Connect to enable Test Mode',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Connect / Reconnect button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _shareInviteLink(context, profile.inviteLink),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: profile.telegramVerified
                                ? Colors.grey.shade200
                                : Colors.red,
                            foregroundColor: profile.telegramVerified
                                ? Colors.grey.shade700
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.telegram),
                          label: Text(
                            profile.telegramVerified
                                ? 'Reconnect Telegram'
                                : 'Connect My Telegram',
                          ),
                        ),
                      ),

                      // Refresh hint shown when not yet verified
                      if (!profile.telegramVerified) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () => ref.invalidate(profileProvider),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text(
                              'Already clicked the link? Tap to refresh',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Alert Settings Section ─────────────────────────
            const _SectionHeader(title: 'Alert Settings'),
            Card(
              child: silentMode.when(
                data: (isSilent) => SwitchListTile(
                  secondary: Icon(
                    isSilent ? Icons.volume_off : Icons.volume_up,
                    color: isSilent ? Colors.red : Colors.grey,
                  ),
                  title: const Text('Silent Mode'),
                  subtitle: const Text(
                    'Skip countdown — alert fires immediately '
                    'with vibration only',
                  ),
                  value: isSilent,
                  activeColor: Colors.red,
                  onChanged: (_) =>
                      ref.read(silentModeProvider.notifier).toggle(),
                ),
                loading: () => const ListTile(
                  title: Text('Silent Mode'),
                  trailing: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SizedBox(height: 24),

            // ── How To Section ─────────────────────────────────
            const _SectionHeader(title: 'How to use Test Mode'),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _HowToStep(
                      number: '1',
                      text: 'Tap "Connect My Telegram" above',
                    ),
                    _HowToStep(
                      number: '2',
                      text: 'Share or tap the link to open Telegram',
                    ),
                    _HowToStep(
                      number: '3',
                      text: 'Tap Start in the bot — you get a confirmation',
                    ),
                    _HowToStep(
                      number: '4',
                      text: 'Come back and tap refresh — status turns green',
                    ),
                    _HowToStep(
                      number: '5',
                      text: 'Enable Test Mode with the toggle above',
                    ),
                    _HowToStep(
                      number: '6',
                      text: 'Trigger an SOS — you receive the test alert',
                    ),
                    _HowToStep(
                      number: '7',
                      text: 'Disable Test Mode when satisfied',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _shareInviteLink(
    BuildContext context,
    String? inviteLink,
  ) async {
    if (inviteLink == null || inviteLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load invite link — try refreshing'),
        ),
      );
      return;
    }

    final message =
        'AlertGuard - Connect My Telegram\n\n'
        'Tap this link to connect your Telegram to your '
        'AlertGuard account. This allows you to receive '
        'test SOS alerts:\n\n'
        '$inviteLink\n\n'
        'Once you tap Start in Telegram, come back to '
        'the app and tap refresh.';

    final encodedText = Uri.encodeComponent(message);
    final encodedUrl = Uri.encodeComponent(inviteLink);

    final tgNative = Uri.parse(
      'tg://msg_url?url=$encodedUrl&text=$encodedText',
    );
    final tgWeb = Uri.parse(
      'https://t.me/share/url?url=$encodedUrl&text=$encodedText',
    );

    if (await canLaunchUrl(tgNative)) {
      await launchUrl(tgNative, mode: LaunchMode.externalApplication);
      return;
    }

    if (await canLaunchUrl(tgWeb)) {
      await launchUrl(tgWeb, mode: LaunchMode.externalApplication);
      return;
    }

    await Share.share(message, subject: 'Connect AlertGuard to Telegram');
  }
}

// ── Supporting widgets ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _HowToStep extends StatelessWidget {
  final String number;
  final String text;
  const _HowToStep({super.key, required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

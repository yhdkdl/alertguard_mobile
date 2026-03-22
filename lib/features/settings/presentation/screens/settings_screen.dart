import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final silentMode = ref.watch(silentModeProvider);
    final testMode = ref.watch(testModeProvider);
    final volumeEnabled = ref.watch(volumeTriggerProvider);
    final shakeEnabled = ref.watch(shakeTriggerProvider);
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
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
            // ── Test Mode ──────────────────────────────────────
            const _SectionHeader(title: 'Test Mode'),
            Card(
              child: Column(
                children: [
                  testMode.when(
                    data: (isTest) => profileState.maybeWhen(
                      data: (profile) => SwitchListTile(
                        secondary: Icon(
                          Icons.science_outlined,
                          color: isTest
                              ? Colors.orange
                              : profile.telegramVerified
                              ? Colors.grey
                              : Colors.grey.shade300,
                        ),
                        title: Text(
                          'Test Mode',
                          style: TextStyle(
                            color: profile.telegramVerified
                                ? null
                                : Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          profile.telegramVerified
                              ? 'Alerts sent only to you — contacts not notified'
                              : 'Connect your Telegram first to enable Test Mode',
                          style: TextStyle(
                            color: profile.telegramVerified
                                ? null
                                : Colors.grey.shade400,
                          ),
                        ),
                        value: isTest,
                        activeColor: Colors.orange,
                        // onChanged is null when telegram not connected
                        // null makes the toggle appear disabled
                        onChanged: profile.telegramVerified
                            ? (value) => ref
                                  .read(testModeProvider.notifier)
                                  .setValue(value)
                            : null,
                      ),
                      orElse: () => SwitchListTile(
                        secondary: const Icon(Icons.science_outlined),
                        title: const Text('Test Mode'),
                        subtitle: const Text('Loading...'),
                        value: isTest,
                        onChanged: null,
                      ),
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
                ],
              ),
            ),

            // Active test mode warning
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

            // ── Your Telegram ──────────────────────────────────
            const _SectionHeader(title: 'Your Telegram'),
            const Text(
              'Connect your Telegram to receive test alerts. '
              'Uses the same verification flow as your contacts.',
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
                      // Status row
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

            // ── Trigger Methods ────────────────────────────────
            const _SectionHeader(title: 'Trigger Methods'),
            const Text(
              'Choose which methods can activate an SOS alert. '
              'The manual SOS button is always available.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  // Volume button toggle
                  volumeEnabled.when(
                    data: (isEnabled) => SwitchListTile(
                      secondary: Icon(
                        Icons.volume_up,
                        color: isEnabled ? Colors.red : Colors.grey,
                      ),
                      title: const Text('Volume Button'),
                      subtitle: const Text(
                        'Triple press volume button to trigger SOS',
                      ),
                      value: isEnabled,
                      activeColor: Colors.red,
                      onChanged: (value) => ref
                          .read(volumeTriggerProvider.notifier)
                          .setValue(value),
                    ),
                    loading: () => const ListTile(title: Text('Volume Button')),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Shake toggle
                  shakeEnabled.when(
                    data: (isEnabled) => SwitchListTile(
                      secondary: Icon(
                        Icons.vibration,
                        color: isEnabled ? Colors.red : Colors.grey,
                      ),
                      title: const Text('Shake Detection'),
                      subtitle: const Text(
                        'Shake phone firmly twice to trigger SOS',
                      ),
                      value: isEnabled,
                      activeColor: Colors.red,
                      onChanged: (value) => ref
                          .read(shakeTriggerProvider.notifier)
                          .setValue(value),
                    ),
                    loading: () =>
                        const ListTile(title: Text('Shake Detection')),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Manual — always on, no toggle
                  ListTile(
                    leading: const Icon(Icons.touch_app, color: Colors.red),
                    title: const Text('Manual SOS Button'),
                    subtitle: const Text(
                      'Always available — cannot be disabled',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Text(
                        'Always On',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Alert Settings ─────────────────────────────────
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

            // ── How To Use Test Mode ───────────────────────────
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
                      text: 'Tap Start in the bot — receive confirmation',
                    ),
                    _HowToStep(
                      number: '4',
                      text: 'Come back and tap refresh — status turns green',
                    ),
                    _HowToStep(
                      number: '5',
                      text: 'Enable Test Mode with the toggle',
                    ),
                    _HowToStep(
                      number: '6',
                      text: 'Trigger SOS — you receive the test alert',
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
    final link = inviteLink?.trim() ?? '';
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load invite link — try refreshing'),
        ),
      );
      return;
    }

    // Best path for "Connect My Telegram": open the invite link directly.
    final inviteUri = Uri.tryParse(link);
    if (inviteUri != null && await canLaunchUrl(inviteUri)) {
      await launchUrl(inviteUri, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback: attempt Telegram share URLs directly before generic share sheet.
    final message =
        'AlertGuard - Connect My Telegram\n\n'
        'Tap this link to connect your Telegram to your '
        'AlertGuard account. This lets you receive test '
        'SOS alerts:\n\n'
        '$link\n\n'
        'Once you tap Start in Telegram, come back to '
        'the app and tap refresh.';

    final encodedText = Uri.encodeComponent(message);
    final encodedUrl = Uri.encodeComponent(link);
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

// ── Supporting Widgets ────────────────────────────────────────────

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

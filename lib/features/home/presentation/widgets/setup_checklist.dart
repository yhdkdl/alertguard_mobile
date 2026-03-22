import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../contacts/presentation/providers/contact_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class SetupStatus {
  final bool hasContact;
  final bool hasVerifiedContact;
  final bool hasTelegramConnected;

  const SetupStatus({
    required this.hasContact,
    required this.hasVerifiedContact,
    required this.hasTelegramConnected,
  });

  bool get isComplete =>
      hasContact && hasVerifiedContact && hasTelegramConnected;
}

final setupStatusProvider = FutureProvider<SetupStatus>((ref) async {
  final contactsState = ref.watch(contactsProvider);
  final contacts = contactsState.maybeWhen(data: (c) => c, orElse: () => []);

  final profile = await ref.watch(profileProvider.future);

  return SetupStatus(
    hasContact: contacts.isNotEmpty,
    hasVerifiedContact: contacts.any((c) => c.telegramVerified),
    hasTelegramConnected: profile.telegramVerified,
  );
});

class SetupChecklist extends ConsumerWidget {
  final Function(int) onSwitchTab;

  const SetupChecklist({super.key, required this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusState = ref.watch(setupStatusProvider);

    return statusState.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Could not load checklist. Tap Retry.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.invalidate(setupStatusProvider);
                ref.invalidate(profileProvider);
                ref.invalidate(contactsProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (status) {
        if (status.isComplete) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complete these steps so AlertGuard works '
              'when you need it most.',
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),

            _ChecklistItem(
              done: status.hasContact,
              title: 'Add an emergency contact',
              subtitle: 'Go to Contacts and add someone you trust',
              actionLabel: 'Add Contact',
              onAction: () => onSwitchTab(1),
            ),
            const SizedBox(height: 10),

            _ChecklistItem(
              done: status.hasVerifiedContact,
              title: 'Verify at least one contact',
              subtitle: 'Share the invite link so they verify on Telegram',
              actionLabel: 'Go to Contacts',
              onAction: () => onSwitchTab(1),
            ),
            const SizedBox(height: 10),

            _ChecklistItem(
              done: status.hasTelegramConnected,
              title: 'Connect your own Telegram',
              subtitle: 'Required for Test Mode',
              actionLabel: 'Go to Settings',
              onAction: () => onSwitchTab(3),
            ),

            const SizedBox(height: 20),

            // Overall progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_completedCount(status)} of 3 steps complete',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${(_completedCount(status) / 3 * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _completedCount(status) / 3,
                    minHeight: 6,
                    backgroundColor: Colors.orange.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  int _completedCount(SetupStatus status) {
    int count = 0;
    if (status.hasContact) count++;
    if (status.hasVerifiedContact) count++;
    if (status.hasTelegramConnected) count++;
    return count;
  }
}

class _ChecklistItem extends StatelessWidget {
  final bool done;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _ChecklistItem({
    required this.done,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: done ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: done ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? Colors.green : Colors.grey,
            size: 22,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: done ? Colors.green.shade700 : Colors.black87,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!done) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),

          if (!done) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

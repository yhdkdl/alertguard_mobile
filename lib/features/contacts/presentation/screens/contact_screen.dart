import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/contact_model.dart';
import '../providers/contact_provider.dart';
import 'add_contact_screen.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsState = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          // Refresh to pick up new verifications
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(contactsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: contactsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(e.toString()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(contactsProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (contacts) => contacts.isEmpty
            ? _EmptyState(onAdd: () => _navigateToAdd(context, ref))
            : RefreshIndicator(
                onRefresh: () => ref.read(contactsProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) => _ContactCard(
                    contact: contacts[index],
                    onDelete: () =>
                        _confirmDelete(context, ref, contacts[index]),
                    onShare: () => _shareInviteLink(contacts[index]),
                  ),
                ),
              ),
      ),
      floatingActionButton: contactsState.maybeWhen(
        data: (contacts) => contacts.length < 3
            ? FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () => _navigateToAdd(context, ref),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null, // hide FAB when 3 contacts reached
        orElse: () => null,
      ),
    );
  }

  Future<void> _navigateToAdd(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddContactScreen()));
    // result = true means a contact was added — already updated via provider
  }

  Future<void> _shareInviteLink(ContactModel contact) async {
    final message =
        'AlertGuard Emergency Contact Invite\n\n'
        'Hi ${contact.name}, I\'ve added you as my emergency contact on '
        'AlertGuard. Please click the link below to verify on Telegram so '
        'you can receive my SOS alerts:\n\n'
        '${contact.inviteLink}';

    if (contact.inviteLink.trim().isEmpty) {
      await Share.share(
        'Invite link is missing for ${contact.name}. Please refresh contacts and try again.',
      );
      return;
    }

    final encodedText = Uri.encodeComponent(message);
    final encodedUrl = Uri.encodeComponent(contact.inviteLink);

    final tgNative = Uri.parse(
      'tg://msg_url?url=$encodedUrl&text=$encodedText',
    );
    final tgWeb = Uri.parse(
      'https://t.me/share/url?url=$encodedUrl&text=$encodedText',
    );

    // Try opening Telegram directly. Fall back to generic share sheet.
    if (await canLaunchUrl(tgNative)) {
      await launchUrl(tgNative, mode: LaunchMode.externalApplication);
      return;
    }

    if (await canLaunchUrl(tgWeb)) {
      await launchUrl(tgWeb, mode: LaunchMode.externalApplication);
      return;
    }

    await Share.share(message, subject: 'AlertGuard Emergency Contact Invite');
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ContactModel contact,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text(
          'Remove ${contact.name} as an emergency contact? '
          'They will no longer receive your SOS alerts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(contactsProvider.notifier).deleteContact(contact.id);
    }
  }
}

// ─── Contact Card Widget ──────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _ContactCard({
    required this.contact,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + verification badge
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: Text(
                    contact.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        contact.phoneNumber,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Verification badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: contact.telegramVerified
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        contact.telegramVerified
                            ? Icons.verified
                            : Icons.pending,
                        size: 14,
                        color: contact.telegramVerified
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        contact.telegramVerified ? 'Verified' : 'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          color: contact.telegramVerified
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Relationship tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                contact.relationship[0].toUpperCase() +
                    contact.relationship.substring(1),
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Share invite link
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share, size: 16),
                    label: Text(
                      contact.telegramVerified ? 'Share Again' : 'Share Invite',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove contact',
                ),
              ],
            ),

            // Pending verification hint
            if (!contact.telegramVerified) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Contact has not verified yet. Share the invite '
                        'link so they can receive your SOS alerts.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Empty State Widget ───────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No emergency contacts yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add up to 3 contacts who will receive your SOS alerts. '
              'At least one contact is recommended.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add First Contact'),
            ),
          ],
        ),
      ),
    );
  }
}

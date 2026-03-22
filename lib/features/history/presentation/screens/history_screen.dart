import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/alert_history_model.dart';
import '../providers/history_provider.dart';
import 'alert_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(alertHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert History'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(alertHistoryProvider.notifier).refresh(),
          ),
        ],
      ),
      body: historyState.when(
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
                onPressed: () =>
                    ref.read(alertHistoryProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (alerts) => alerts.isEmpty
            ? _EmptyState()
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(alertHistoryProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) => _AlertCard(
                    alert: alerts[index],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AlertDetailScreen(alert: alerts[index]),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Alert Card ────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final AlertHistoryModel alert;
  final VoidCallback onTap;

  const _AlertCard({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = alert.status == 'sent'
        ? Colors.green
        : alert.status == 'failed'
        ? Colors.red
        : Colors.orange;

    final statusIcon = alert.status == 'sent'
        ? Icons.check_circle
        : alert.status == 'failed'
        ? Icons.error
        : Icons.schedule;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: trigger + status ──────────────────
              Row(
                children: [
                  // Trigger icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _triggerIcon(alert.triggerType),
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Trigger label + date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              alert.triggerLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (alert.isTest) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'TEST',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          alert.formattedDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          alert.statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Bottom row: location + photos indicator ────
              if (alert.hasLocation ||
                  alert.frontPhotoUrl != null ||
                  alert.rearPhotoUrl != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (alert.hasLocation) ...[
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Location captured',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                    const Spacer(),
                    if (alert.frontPhotoUrl != null ||
                        alert.rearPhotoUrl != null)
                      Row(
                        children: [
                          Icon(
                            Icons.photo_camera,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _photoCount(alert),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _triggerIcon(String triggerType) {
    switch (triggerType) {
      case 'volume_button':
        return Icons.volume_up;
      case 'shake':
        return Icons.vibration;
      case 'manual':
        return Icons.touch_app;
      default:
        return Icons.warning;
    }
  }

  String _photoCount(AlertHistoryModel alert) {
    final count = [
      alert.frontPhotoUrl,
      alert.rearPhotoUrl,
    ].where((u) => u != null).length;
    return '$count photo${count == 1 ? '' : 's'}';
  }
}

// ── Empty State ───────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No alerts yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your SOS alert history will appear here '
              'after your first alert is triggered.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

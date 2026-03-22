import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/alert_history_model.dart';

class AlertDetailScreen extends StatelessWidget {
  final AlertHistoryModel alert;

  const AlertDetailScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Details'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status banner ──────────────────────────────────
            _StatusBanner(status: alert.status),
            const SizedBox(height: 16),

            // ── Info card ──────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.access_time,
                      label: 'Time',
                      value: alert.formattedDate,
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.touch_app,
                      label: 'Trigger',
                      value: alert.triggerLabel,
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.science_outlined,
                      label: 'Mode',
                      value: alert.isTest ? 'Test Alert' : 'Real Alert',
                      valueColor: alert.isTest ? Colors.orange : Colors.red,
                    ),
                    if (alert.hasLocation) ...[
                      const Divider(),
                      _InfoRow(
                        icon: Icons.location_on,
                        label: 'Location',
                        value: '${alert.latitude}, ${alert.longitude}',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Open in maps button ────────────────────────────
            if (alert.hasLocation)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openMaps(context),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open Location in Maps'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // ── Photos ─────────────────────────────────────────
            if (alert.frontPhotoUrl != null || alert.rearPhotoUrl != null) ...[
              const Text(
                'Captured Photos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (alert.frontPhotoUrl != null)
                    Expanded(
                      child: _PhotoCard(
                        label: 'Front Camera',
                        url: alert.frontPhotoUrl!,
                      ),
                    ),
                  if (alert.frontPhotoUrl != null && alert.rearPhotoUrl != null)
                    const SizedBox(width: 8),
                  if (alert.rearPhotoUrl != null)
                    Expanded(
                      child: _PhotoCard(
                        label: 'Rear Camera',
                        url: alert.rearPhotoUrl!,
                      ),
                    ),
                ],
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.no_photography_outlined,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'No photos captured',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps(BuildContext context) async {
    final uri = Uri.parse(alert.mapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    }
  }
}

// ── Supporting widgets ────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'sent'
        ? Colors.green
        : status == 'failed'
        ? Colors.red
        : Colors.orange;

    final icon = status == 'sent'
        ? Icons.check_circle
        : status == 'failed'
        ? Icons.error
        : Icons.schedule;

    final label = status == 'sent'
        ? 'Alert was sent successfully'
        : status == 'failed'
        ? 'Alert failed to send'
        : 'Alert is pending';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final String label;
  final String url;

  const _PhotoCard({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 160,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stack) {
              return Container(
                height: 160,
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined, color: Colors.grey[400]),
                    const SizedBox(height: 4),
                    Text(
                      'Photo unavailable',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

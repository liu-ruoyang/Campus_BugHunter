import 'package:flutter/material.dart';

import '../services/bounty_image_service.dart';
import '../theme/app_theme.dart';
import '../utils/bounty_rules.dart';

class BountyDetailPage extends StatelessWidget {
  final String bountyId;
  final Map<String, dynamic> data;

  const BountyDetailPage({
    super.key,
    required this.bountyId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final status = (data['status'] ?? 'NOT ACCEPTED').toString().toUpperCase();
    final amount = (data['amount'] ?? 0).toDouble();
    final stacks = (data['techStacks'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList();
    final imageUrls = BountyImageService.urlsFromData(data);
    final locationType = data['locationType']?.toString() ?? 'Offline';
    final location = locationType == 'Online'
        ? (data['meetingLink'] ?? data['location'] ?? '').toString()
        : (data['location'] ?? '').toString();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(elevation: 0, title: const Text('Bounty Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.primarySoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.bug_report_outlined,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: _StatusHeader(status: status)),
                      Text(
                        'RM ${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: colors.success,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    data['title']?.toString() ?? 'No Title',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DetailBlock(
                    label: 'Problem Description',
                    icon: Icons.description_outlined,
                    child: Text(
                      data['description']?.toString() ??
                          'No description provided.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 16,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailBlock(
                    label: 'Tech Stack',
                    icon: Icons.code,
                    child: stacks.isEmpty
                        ? Text(
                            'Not provided',
                            style: TextStyle(color: colors.textSecondary),
                          )
                        : Wrap(
                            spacing: 9,
                            runSpacing: 9,
                            children: stacks
                                .map((stack) => _StackPill(stack))
                                .toList(),
                          ),
                  ),
                  if (imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DetailBlock(
                      label: 'Code Screenshots',
                      icon: Icons.image_outlined,
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < imageUrls.length;
                            index++
                          ) ...[
                            _Screenshot(url: imageUrls[index], index: index),
                            if (index < imageUrls.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Order ID',
                    value: bountyId,
                    icon: Icons.tag,
                  ),
                  _DetailRow(
                    label: 'Difficulty',
                    value: data['difficulty']?.toString() ?? 'Simple',
                    icon: Icons.speed_outlined,
                  ),
                  _DetailRow(
                    label: 'Urgency',
                    value: data['urgencyLevel']?.toString() ?? 'Not provided',
                    icon: Icons.schedule_outlined,
                  ),
                  _DetailRow(
                    label: locationType == 'Online'
                        ? 'Meeting Link'
                        : 'Location',
                    value: location.isEmpty ? 'Not provided' : location,
                    icon: locationType == 'Online'
                        ? Icons.videocam_outlined
                        : Icons.place_outlined,
                  ),
                  _DetailRow(
                    label: 'Posted At',
                    value: _formatDate(data['createdAt']),
                    icon: Icons.event_available_outlined,
                  ),
                  _DetailRow(
                    label: 'Expires At',
                    value: _formatDate(data['expiresAt']),
                    icon: Icons.event_busy_outlined,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final String status;

  const _StatusHeader({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BOUNTY REQUEST',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          status,
          style: TextStyle(
            color: status == 'COMPLETED' ? colors.success : colors.primary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _DetailBlock extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const _DetailBlock({
    required this.label,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.chip,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary, size: 17),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 11,
                  letterSpacing: 1.7,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Screenshot extends StatelessWidget {
  final String url;
  final int index;

  const _Screenshot({required this.url, required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(18),
          child: InteractiveViewer(
            minScale: 0.7,
            maxScale: 4,
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 360),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Screenshot ${index + 1} could not be loaded',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

class _StackPill extends StatelessWidget {
  final String text;

  const _StackPill(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  value,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    height: 1.35,
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

String _formatDate(dynamic value) {
  final date = timestampDate(value)?.toLocal();
  if (date == null) return 'Not available';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.year}-$month-$day $hour:$minute';
}

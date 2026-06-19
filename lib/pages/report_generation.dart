import 'package:flutter/material.dart';

import '../services/report_generation_service.dart';
import '../theme/app_theme.dart';

class ReportGenerationPage extends StatefulWidget {
  const ReportGenerationPage({super.key});

  @override
  State<ReportGenerationPage> createState() => _ReportGenerationPageState();
}

class _ReportGenerationPageState extends State<ReportGenerationPage> {
  final _service = ReportGenerationService();
  bool _requesterLoading = false;
  bool _helperLoading = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(elevation: 0, title: const Text('Report Generation')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generate Your Campus BugHunter Report',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Download a polished PDF summary of your requester or helper activity.',
                  style: TextStyle(color: Color(0xFF4B5563), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _ReportOption(
            title: 'Generate requester report',
            subtitle: 'View your activity report as a requester.',
            icon: Icons.download_outlined,
            loading: _requesterLoading,
            onTap: () => _run(
              loadingSetter: (value) =>
                  setState(() => _requesterLoading = value),
              action: _service.generateRequesterReport,
            ),
          ),
          const SizedBox(height: 16),
          _ReportOption(
            title: 'Generate helper report',
            subtitle: 'View your activity report as a helper.',
            icon: Icons.download_for_offline_outlined,
            loading: _helperLoading,
            onTap: () => _run(
              loadingSetter: (value) => setState(() => _helperLoading = value),
              action: _service.generateHelperReport,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _run({
    required ValueChanged<bool> loadingSetter,
    required Future<void> Function() action,
  }) async {
    loadingSetter(true);
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate report')),
      );
    } finally {
      if (mounted) loadingSetter(false);
    }
  }
}

class _ReportOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;

  const _ReportOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: loading
                  ? Padding(
                      padding: const EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    )
                  : Icon(icon, color: colors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

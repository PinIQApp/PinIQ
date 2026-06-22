import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';

class AdminCenterScreen extends StatelessWidget {
  const AdminCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
          padding: EdgeInsets.zero,
          children: [
          const SubpageHeader(
            title: 'Admin Center',
            subtitle:
                'Monitor system health, run manual jobs, and keep operator controls out of coach workflows.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _AdminSummaryRow(),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1120;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(flex: 3, child: _AdminJobPanel()),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 2, child: _SystemHealthPanel()),
                  ],
                );
              }

              return const Column(
                children: [
                  _AdminJobPanel(),
                  SizedBox(height: AppSpacing.lg),
                  _SystemHealthPanel(),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Manual controls'),
          const SizedBox(height: AppSpacing.md),
          const _ManualControlPanel(),
          const SizedBox(height: AppSpacing.xl),
          ],
    );
  }
}

class _AdminSummaryRow extends StatelessWidget {
  const _AdminSummaryRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: const [
        SizedBox(
          width: 220,
          child: _AdminMetric(label: 'Jobs', value: '6', note: 'scanner tasks', color: Color(0xFF94A3B8)),
        ),
        SizedBox(
          width: 220,
          child: _AdminMetric(label: 'Errors', value: '2', note: 'open diagnostics', color: Color(0xFFEF4444)),
        ),
        SizedBox(
          width: 220,
          child: _AdminMetric(label: 'Refreshes', value: '11', note: 'manual today', color: Color(0xFFF59E0B)),
        ),
        SizedBox(
          width: 220,
          child: _AdminMetric(label: 'Teams', value: '3', note: 'demo org coverage', color: Color(0xFF38BDF8)),
        ),
      ],
    );
  }
}

class _AdminMetric extends StatelessWidget {
  const _AdminMetric({
    required this.label,
    required this.value,
    required this.note,
    required this.color,
  });

  final String label;
  final String value;
  final String note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.cardTitle.copyWith(color: color)),
          const SizedBox(height: AppSpacing.xxs),
          Text(note, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _AdminJobPanel extends StatelessWidget {
  const _AdminJobPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(title: 'Job queue'),
          SizedBox(height: AppSpacing.md),
          _AdminRow(
            title: 'Tournament discovery',
            subtitle: 'Daily scan job completed with one delayed provider retry.',
            value: 'Retry queued',
          ),
          SizedBox(height: AppSpacing.sm),
          _AdminRow(
            title: 'Messaging sync',
            subtitle: 'Thread summaries refreshed cleanly across coach demo team.',
            value: 'Healthy',
          ),
          SizedBox(height: AppSpacing.sm),
          _AdminRow(
            title: 'Brand asset propagation',
            subtitle: 'Logo and color settings updated across local web target.',
            value: 'Healthy',
          ),
        ],
      ),
    );
  }
}

class _SystemHealthPanel extends StatelessWidget {
  const _SystemHealthPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(title: 'System health'),
          SizedBox(height: AppSpacing.md),
          _AdminRow(
            title: 'Auth service',
            subtitle: 'Login and seeded demo accounts are responding.',
            value: 'Live',
          ),
          SizedBox(height: AppSpacing.sm),
          _AdminRow(
            title: 'Messaging API',
            subtitle: 'Announcements and thread endpoints are available.',
            value: 'Live',
          ),
          SizedBox(height: AppSpacing.sm),
          _AdminRow(
            title: 'Web runtime',
            subtitle: 'Watch browser CanvasKit stability after hot restart.',
            value: 'Watch',
          ),
        ],
      ),
    );
  }
}

class _ManualControlPanel extends StatelessWidget {
  const _ManualControlPanel();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _ControlCard(
          title: 'Force refresh data',
          subtitle: 'Reload dashboard, team, messaging, and weights.',
          icon: Icons.refresh_rounded,
        ),
        _ControlCard(
          title: 'Run scanner',
          subtitle: 'Trigger tournament discovery or data sync jobs manually.',
          icon: Icons.radar_outlined,
        ),
        _ControlCard(
          title: 'Open logs',
          subtitle: 'Review operator-facing failures and warnings.',
          icon: Icons.article_outlined,
        ),
        _ControlCard(
          title: 'Debug mode',
          subtitle: 'Access internal diagnostics without exposing coach clutter.',
          icon: Icons.bug_report_outlined,
        ),
      ],
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.xxs),
          Text(subtitle, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _AdminRow extends StatelessWidget {
  const _AdminRow({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(value, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

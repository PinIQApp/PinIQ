import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';

class FlyerStudioScreen extends StatefulWidget {
  const FlyerStudioScreen({super.key});

  @override
  State<FlyerStudioScreen> createState() => _FlyerStudioScreenState();
}

class _FlyerStudioScreenState extends State<FlyerStudioScreen> {
  String _template = 'tournament';

  @override
  Widget build(BuildContext context) {
    final templateTitle = switch (_template) {
      'fundraiser' => 'Fundraiser Drive',
      'camp' => 'Summer Camp Push',
      _ => 'Tournament Weekend',
    };

    final templateSubtext = switch (_template) {
      'fundraiser' => 'Sponsor logos, pricing blocks, and social-ready fundraising copy.',
      'camp' => 'Girls camp layout with registration CTA and branded story export.',
      _ => 'Event-ready promo with date, location, weights, and registration details.',
    };

    return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1120;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const SubpageHeader(
                title: 'Flyer Studio',
                subtitle:
                    'Build branded tournament, fundraiser, and camp promos without leaving the app.',
              ),
              const SizedBox(height: AppSpacing.lg),
              const _FlyerSummaryRow(),
              const SizedBox(height: AppSpacing.xl),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _FlyerControlPanel(
                        template: _template,
                        onTemplateChanged: (value) => setState(() => _template = value),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      flex: 4,
                      child: _FlyerPreviewPanel(
                        title: templateTitle,
                        subtitle: templateSubtext,
                        template: _template,
                      ),
                    ),
                  ],
                )
              else ...[
                _FlyerControlPanel(
                  template: _template,
                  onTemplateChanged: (value) => setState(() => _template = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                _FlyerPreviewPanel(
                  title: templateTitle,
                  subtitle: templateSubtext,
                  template: _template,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Export outputs'),
              const SizedBox(height: AppSpacing.md),
              const _ExportPanel(),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
    );
  }
}

class _FlyerSummaryRow extends StatelessWidget {
  const _FlyerSummaryRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: const [
        SizedBox(
          width: 240,
          child: _FlyerMetric(label: 'Templates', value: '16', note: 'saved layouts', color: Color(0xFFEC4899)),
        ),
        SizedBox(
          width: 240,
          child: _FlyerMetric(label: 'Drafts', value: '7', note: 'active builds', color: Color(0xFF8B5CF6)),
        ),
        SizedBox(
          width: 240,
          child: _FlyerMetric(label: 'Exports', value: '23', note: 'last 30 days', color: Color(0xFFF59E0B)),
        ),
        SizedBox(
          width: 240,
          child: _FlyerMetric(label: 'Campaigns', value: '4', note: 'live promos', color: Color(0xFF38BDF8)),
        ),
      ],
    );
  }
}

class _FlyerControlPanel extends StatelessWidget {
  const _FlyerControlPanel({
    required this.template,
    required this.onTemplateChanged,
  });

  final String template;
  final ValueChanged<String> onTemplateChanged;

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
        children: [
          Text('Template controls', style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final chip in const [
                  ('tournament', 'Tournament'),
                  ('fundraiser', 'Fundraiser'),
                  ('camp', 'Camp'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(chip.$2),
                      selected: template == chip.$1,
                      onSelected: (_) => onTemplateChanged(chip.$1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _EditorBlock(
            title: 'Content blocks',
            items: [
              'Logo + mascot placement',
              'Dates, location, and pricing',
              'Weights and registration notes',
              'Sponsor and CTA sections',
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _EditorBlock(
            title: 'Branding',
            items: [
              'School color theme',
              'Accent gradient',
              'Coach-controlled copy',
              'Saved program templates',
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _EditorBlock(
            title: 'Workflow',
            items: [
              'Drag-and-drop builder',
              'Live preview',
              'Connect tournaments and events',
              'Prepare social exports',
            ],
          ),
        ],
      ),
    );
  }
}

class _EditorBlock extends StatelessWidget {
  const _EditorBlock({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.sm),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 8, color: Color(0xFFEC4899)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlyerPreviewPanel extends StatelessWidget {
  const _FlyerPreviewPanel({
    required this.title,
    required this.subtitle,
    required this.template,
  });

  final String title;
  final String subtitle;
  final String template;

  @override
  Widget build(BuildContext context) {
    final accent = switch (template) {
      'fundraiser' => const Color(0xFFF59E0B),
      'camp' => const Color(0xFF38BDF8),
      _ => const Color(0xFFEC4899),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Live preview', style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.ios_share_outlined),
                label: const Text('Export'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: AppColors.brandedGradient(primary: accent, secondary: AppColors.surfaceElevated),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FlyerTag(label: template.toUpperCase()),
                const SizedBox(height: AppSpacing.xl),
                Text(title, style: AppTextStyles.pageTitle.copyWith(fontSize: 34)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: const [
                    _FlyerTag(label: 'Martin County'),
                    _FlyerTag(label: 'Girls Wrestling'),
                    _FlyerTag(label: 'Logo + mascot ready'),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Date • Location • Pricing • Registration • Weights',
                    style: AppTextStyles.bodyStrong,
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

class _ExportPanel extends StatelessWidget {
  const _ExportPanel();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: const [
        _ExportCard(title: 'PDF', subtitle: 'Printable event handout'),
        _ExportCard(title: 'Square', subtitle: 'Instagram + Facebook post'),
        _ExportCard(title: 'Story', subtitle: 'Vertical social promo'),
        _ExportCard(title: 'Share Pack', subtitle: 'Coach-ready social bundle'),
      ],
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.xxs),
          Text(subtitle, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _FlyerMetric extends StatelessWidget {
  const _FlyerMetric({
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

class _FlyerTag extends StatelessWidget {
  const _FlyerTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
    );
  }
}

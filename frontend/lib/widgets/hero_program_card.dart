import 'package:flutter/material.dart';

import '../models/team_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'school_logo_badge.dart';

class HeroProgramCard extends StatelessWidget {
  const HeroProgramCard({
    super.key,
    required this.team,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.badge,
    this.primaryAction,
    this.secondaryAction,
  });

  final TeamModel? team;
  final String title;
  final String subtitle;
  final String description;
  final String badge;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 560;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated.withValues(alpha: 0.94),
            AppColors.surface.withValues(alpha: 0.84),
            scheme.primary.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.76)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!isCompact) SchoolLogoBadge(team: team, radius: 28),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isCompact ? width - 72 : 560,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team?.schoolName ?? 'Program',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  badge,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? AppSpacing.md : AppSpacing.lg),
          Text(
            title,
            style: AppTextStyles.pageTitle.copyWith(
              fontSize: isCompact ? 24 : 29,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _HeroTag(label: team?.mascotName ?? 'Program'),
              if (team?.tagline?.trim().isNotEmpty == true)
                _HeroTag(label: team!.tagline!.trim()),
              _HeroTag(label: 'School branded'),
            ],
          ),
          if (primaryAction != null || secondaryAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (primaryAction != null) primaryAction!,
                if (secondaryAction != null) secondaryAction!,
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
    );
  }
}

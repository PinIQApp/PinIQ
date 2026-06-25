import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/school_logo_badge.dart';
import '../../widgets/subpage_header.dart';

class BrandingEditScreen extends StatefulWidget {
  const BrandingEditScreen({super.key});

  @override
  State<BrandingEditScreen> createState() => _BrandingEditScreenState();
}

class _BrandingEditScreenState extends State<BrandingEditScreen> {
  static const List<_ColorOption> _palette = [
    _ColorOption('Navy', '#0F172A'),
    _ColorOption('Royal Blue', '#2563EB'),
    _ColorOption('Sky Blue', '#38BDF8'),
    _ColorOption('Teal', '#0F766E'),
    _ColorOption('Forest Green', '#166534'),
    _ColorOption('Kelly Green', '#22C55E'),
    _ColorOption('Gold', '#EAB308'),
    _ColorOption('Amber', '#F59E0B'),
    _ColorOption('Orange', '#F97316'),
    _ColorOption('Cardinal Red', '#B91C1C'),
    _ColorOption('Victory Red', '#DC2626'),
    _ColorOption('Maroon', '#7F1D1D'),
    _ColorOption('Purple', '#7C3AED'),
    _ColorOption('Black', '#050B14'),
    _ColorOption('Slate', '#121D2E'),
    _ColorOption('Steel', '#334155'),
    _ColorOption('Silver', '#94A3B8'),
    _ColorOption('White', '#F8FAFC'),
  ];

  late final TextEditingController _schoolName;
  late final TextEditingController _abbr;
  late final TextEditingController _mascot;
  late final TextEditingController _tagline;
  late final TextEditingController _primaryColor;
  late final TextEditingController _secondaryColor;
  late final TextEditingController _accentColor;
  late final TextEditingController _surfaceColor;
  String? _message;
  String? _error;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final team = context.read<AppState>().activeTeam!;
    _schoolName = TextEditingController(text: team.schoolName);
    _abbr = TextEditingController(text: team.schoolAbbreviation ?? '');
    _mascot = TextEditingController(text: team.mascotName);
    _tagline = TextEditingController(text: team.tagline ?? '');
    _primaryColor = TextEditingController(text: team.primaryColor);
    _secondaryColor = TextEditingController(text: team.secondaryColor);
    _accentColor = TextEditingController(text: team.accentColor);
    _surfaceColor = TextEditingController(text: team.surfaceColor);
  }

  @override
  void dispose() {
    _schoolName.dispose();
    _abbr.dispose();
    _mascot.dispose();
    _tagline.dispose();
    _primaryColor.dispose();
    _secondaryColor.dispose();
    _accentColor.dispose();
    _surfaceColor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (!appState.canManageBranding) {
      return const Center(child: Text('Only staff can edit branding.'));
    }

    final colors = [
      _primaryColor.text.trim(),
      _secondaryColor.text.trim(),
      _accentColor.text.trim(),
      _surfaceColor.text.trim(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SubpageHeader(
                title: 'Branding Controls',
                subtitle:
                    'Edit school identity, mascot, colors, and logo so the app stays school-branded.',
              ),
              const SizedBox(height: AppSpacing.md),
              _BrandHero(
                schoolName: _schoolName.text.trim(),
                abbreviation: _abbr.text.trim(),
                mascot: _mascot.text.trim(),
                tagline: _tagline.text.trim(),
                colors: colors,
                logo: SchoolLogoBadge(
                  team: appState.activeTeam,
                  radius: 42,
                  showLabel: false,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _BrandPreviewPanel(
                        joinCode: appState.activeTeam?.joinCode ?? '--',
                        logoUrl: appState.activeTeam?.logoUrl,
                        colors: colors,
                        onRotateJoinCode:
                            appState.isBusy ? null : _rotateJoinCode,
                        onUploadLogo: appState.isBusy ? null : _uploadLogo,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      flex: 7,
                      child: _BrandControlsPanel(
                        fields: [
                          _field(_schoolName, 'School Name'),
                          _field(_abbr, 'School Abbreviation'),
                          _field(_mascot, 'Mascot'),
                          _field(_tagline, 'Tagline'),
                          _colorField(_primaryColor, 'Primary Color'),
                          _colorField(_secondaryColor, 'Secondary Color'),
                          _colorField(_accentColor, 'Accent Color'),
                          _colorField(_surfaceColor, 'Surface Color'),
                        ],
                        isBusy: appState.isBusy,
                        onSave: _saveBranding,
                      ),
                    ),
                  ],
                )
              else ...[
                _BrandPreviewPanel(
                  joinCode: appState.activeTeam?.joinCode ?? '--',
                  logoUrl: appState.activeTeam?.logoUrl,
                  colors: colors,
                  onRotateJoinCode: appState.isBusy ? null : _rotateJoinCode,
                  onUploadLogo: appState.isBusy ? null : _uploadLogo,
                ),
                const SizedBox(height: AppSpacing.lg),
                _BrandControlsPanel(
                  fields: [
                    _field(_schoolName, 'School Name'),
                    _field(_abbr, 'School Abbreviation'),
                    _field(_mascot, 'Mascot'),
                    _field(_tagline, 'Tagline'),
                    _colorField(_primaryColor, 'Primary Color'),
                    _colorField(_secondaryColor, 'Secondary Color'),
                    _colorField(_accentColor, 'Accent Color'),
                    _colorField(_surfaceColor, 'Surface Color'),
                  ],
                  isBusy: appState.isBusy,
                  onSave: _saveBranding,
                ),
              ],
              if (appState.activeTeam?.logoUrl?.isNotEmpty != true) ...[
                const SizedBox(height: AppSpacing.lg),
                const EmptyStateCard(
                  title: 'No School Logo Yet',
                  message:
                      'Upload an official school or mascot logo so the dashboard and settings feel fully branded for coaches and families.',
                  icon: Icons.image_outlined,
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_message!,
                    style: AppTextStyles.bodyStrong
                        .copyWith(color: AppColors.success)),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!,
                    style: AppTextStyles.bodyStrong
                        .copyWith(color: AppColors.danger)),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  Future<void> _rotateJoinCode() async {
    try {
      setState(() {
        _error = null;
        _message = null;
      });
      await context.read<AppState>().rotateJoinCode();
      setState(() => _message = 'Join code rotated.');
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _uploadLogo() async {
    final state = context.read<AppState>();
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    try {
      setState(() {
        _error = null;
        _message = null;
      });
      await state.uploadLogo(File(picked.path));
      setState(() => _message = 'Logo uploaded.');
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _saveBranding() async {
    try {
      setState(() {
        _error = null;
        _message = null;
      });
      await context.read<AppState>().updateBranding({
        'school_name': _schoolName.text.trim(),
        'school_abbreviation': _abbr.text.trim(),
        'mascot_name': _mascot.text.trim(),
        'logo_url': context.read<AppState>().activeTeam?.logoUrl,
        'tagline': _tagline.text.trim(),
        'primary_color': _primaryColor.text.trim(),
        'secondary_color': _secondaryColor.text.trim(),
        'accent_color': _accentColor.text.trim(),
        'surface_color': _surfaceColor.text.trim(),
        'dark_mode': true,
      });
      setState(() => _message = 'Branding updated.');
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Widget _field(TextEditingController controller, String label) {
    return SizedBox(
      width: 360,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _colorField(TextEditingController controller, String label) {
    final current = controller.text.trim().toUpperCase();
    final options = [..._palette];
    if (current.isNotEmpty && options.every((item) => item.hex != current)) {
      options.insert(0, _ColorOption('Current', current));
    }

    return SizedBox(
      width: 360,
      child: DropdownButtonFormField<String>(
        initialValue: current.isEmpty ? null : current,
        decoration: InputDecoration(labelText: label),
        items: options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option.hex,
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _hexColor(option.hex),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('${option.name} • ${option.hex}'),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() => controller.text = value);
        },
      ),
    );
  }

  Color _hexColor(String hex) {
    final clean = hex.replaceAll('#', '');
    final normalized = clean.length == 6 ? 'FF$clean' : clean;
    return Color(int.parse(normalized, radix: 16));
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero({
    required this.schoolName,
    required this.abbreviation,
    required this.mascot,
    required this.tagline,
    required this.colors,
    required this.logo,
  });

  final String schoolName;
  final String abbreviation;
  final String mascot;
  final String tagline;
  final List<String> colors;
  final Widget logo;

  @override
  Widget build(BuildContext context) {
    final primary =
        _safeHex(colors.isEmpty ? null : colors.first, AppColors.danger);
    final secondary = _safeHex(
      colors.length > 1 ? colors[1] : null,
      const Color(0xFF38BDF8),
    );
    final surface = _safeHex(
      colors.length > 3 ? colors[3] : null,
      AppColors.surfaceElevated,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surface.withValues(alpha: 0.92),
            AppColors.bg.withValues(alpha: 0.98),
            primary.withValues(alpha: 0.52),
          ],
          stops: const [0, 0.58, 1],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 760;
          final identity = Row(
            children: [
              logo,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _BrandBadge(
                          label:
                              abbreviation.isEmpty ? 'Program' : abbreviation,
                          color: secondary,
                        ),
                        _BrandBadge(label: 'Pin IQ', color: primary),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      schoolName.isEmpty ? 'School name' : schoolName,
                      style: AppTextStyles.pageTitle.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      mascot.isEmpty ? 'Mascot' : mascot,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final taglineBlock = Text(
            tagline.isEmpty ? 'Built for the mat.' : tagline,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.9),
            ),
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: AppSpacing.lg),
                taglineBlock,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: AppSpacing.lg),
              SizedBox(width: 280, child: taglineBlock),
            ],
          );
        },
      ),
    );
  }
}

class _BrandPreviewPanel extends StatelessWidget {
  const _BrandPreviewPanel({
    required this.joinCode,
    required this.logoUrl,
    required this.colors,
    required this.onRotateJoinCode,
    required this.onUploadLogo,
  });

  final String joinCode;
  final String? logoUrl;
  final List<String> colors;
  final VoidCallback? onRotateJoinCode;
  final VoidCallback? onUploadLogo;

  @override
  Widget build(BuildContext context) {
    final logoText =
        logoUrl?.isNotEmpty == true ? 'Logo connected' : 'Logo still needed';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.68)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Brand preview', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Check the pieces families and coaches see first.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          _BrandPreviewRow(colors: colors),
          const SizedBox(height: AppSpacing.lg),
          _BrandActionCard(
            icon: Icons.key_rounded,
            title: 'Join code',
            value: joinCode,
            actionLabel: 'Rotate',
            onTap: onRotateJoinCode,
          ),
          const SizedBox(height: AppSpacing.sm),
          _BrandActionCard(
            icon: Icons.image_outlined,
            title: 'Logo',
            value: logoText,
            actionLabel: 'Upload',
            onTap: onUploadLogo,
          ),
        ],
      ),
    );
  }
}

class _BrandControlsPanel extends StatelessWidget {
  const _BrandControlsPanel({
    required this.fields,
    required this.isBusy,
    required this.onSave,
  });

  final List<Widget> fields;
  final bool isBusy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.68)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Identity controls', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Update the school name, mascot, tagline, and app color system.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: fields,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isBusy ? null : onSave,
              icon: Icon(isBusy ? Icons.sync_rounded : Icons.save_outlined),
              label: Text(isBusy ? 'Saving...' : 'Save branding'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandActionCard extends StatelessWidget {
  const _BrandActionCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.52)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF38BDF8)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.caption),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong),
              ],
            ),
          ),
          TextButton(onPressed: onTap, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _BrandPreviewRow extends StatelessWidget {
  const _BrandPreviewRow({required this.colors});

  final List<String> colors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors
          .map(
            (hex) => Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _hexColor(hex),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                hex,
                style: TextStyle(
                  color: _hexColor(hex).computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Color _hexColor(String hex) {
    return _safeHex(hex, AppColors.surfaceElevated);
  }
}

Color _safeHex(String? hex, Color fallback) {
  final value = hex?.trim();
  if (value == null || value.isEmpty) return fallback;
  try {
    final clean = value.replaceAll('#', '');
    final normalized = clean.length == 6 ? 'FF$clean' : clean;
    return Color(int.parse(normalized, radix: 16));
  } catch (_) {
    return fallback;
  }
}

class _ColorOption {
  const _ColorOption(this.name, this.hex);

  final String name;
  final String hex;
}

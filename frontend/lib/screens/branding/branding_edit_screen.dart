import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
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
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (!appState.canManageBranding) {
      return const Center(child: Text('Only staff can edit branding.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SubpageHeader(
                title: 'Branding Controls',
                subtitle: 'Edit school identity, mascot, colors, and logo so the app stays school-branded.',
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  SchoolLogoBadge(
                    team: appState.activeTeam,
                    radius: 38,
                    showLabel: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _field(_schoolName, 'School Name'),
                  _field(_abbr, 'School Abbreviation'),
                  _field(_mascot, 'Mascot'),
                  _field(_tagline, 'Tagline'),
                  _colorField(_primaryColor, 'Primary Color'),
                  _colorField(_secondaryColor, 'Secondary Color'),
                  _colorField(_accentColor, 'Accent Color'),
                  _colorField(_surfaceColor, 'Surface Color'),
                ],
              ),
              const SizedBox(height: 16),
              _BrandPreviewRow(
                colors: [
                  _primaryColor.text.trim(),
                  _secondaryColor.text.trim(),
                  _accentColor.text.trim(),
                  _surfaceColor.text.trim(),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Join code: ${appState.activeTeam?.joinCode ?? '--'}'),
                      ),
                      TextButton(
                        onPressed: appState.isBusy
                            ? null
                            : () async {
                                try {
                                  await context.read<AppState>().rotateJoinCode();
                                  setState(() => _message = 'Join code rotated.');
                                } catch (e) {
                                  setState(() => _error = e.toString());
                                }
                              },
                        child: const Text('Rotate Code'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          appState.activeTeam?.logoUrl?.isNotEmpty == true
                              ? 'Current logo: ${appState.activeTeam!.logoUrl}'
                              : 'No uploaded logo yet.',
                        ),
                      ),
                      TextButton(
                        onPressed: appState.isBusy
                            ? null
                            : () async {
                                final state = context.read<AppState>();
                                final picked = await _picker.pickImage(source: ImageSource.gallery);
                                if (picked == null || !mounted) return;
                                try {
                                  await state.uploadLogo(
                                        File(picked.path),
                                      );
                                  setState(() => _message = 'Logo uploaded.');
                                } catch (e) {
                                  setState(() => _error = e.toString());
                                }
                              },
                        child: const Text('Upload Logo'),
                      ),
                    ],
                  ),
                ),
              ),
              if (appState.activeTeam?.logoUrl?.isNotEmpty != true) ...[
                const SizedBox(height: 12),
                const EmptyStateCard(
                  title: 'No School Logo Yet',
                  message:
                      'Upload an official school or mascot logo so the dashboard and settings feel fully branded for coaches and families.',
                  icon: Icons.image_outlined,
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(_message!, style: const TextStyle(color: Colors.greenAccent)),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: appState.isBusy
                    ? null
                    : () async {
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
                      },
                child: Text(appState.isBusy ? 'Saving...' : 'Save Branding'),
              ),
            ],
          ),
        ),
      ),
    );
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
                  color: _hexColor(hex).computeLuminance() > 0.45 ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Color _hexColor(String hex) {
    final clean = hex.replaceAll('#', '');
    final normalized = clean.length == 6 ? 'FF$clean' : clean;
    return Color(int.parse(normalized, radix: 16));
  }
}

class _ColorOption {
  const _ColorOption(this.name, this.hex);

  final String name;
  final String hex;
}

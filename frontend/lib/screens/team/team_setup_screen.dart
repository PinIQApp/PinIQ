import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../widgets/branded_header_card.dart';

class TeamSetupScreen extends StatefulWidget {
  const TeamSetupScreen({super.key});

  @override
  State<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends State<TeamSetupScreen> {
  final _teamName = TextEditingController(text: 'Martin County Girls Wrestling');
  final _schoolName = TextEditingController(text: 'Martin County High School');
  final _abbr = TextEditingController(text: 'MCHS');
  final _mascot = TextEditingController(text: 'Cardinals');
  final _season = TextEditingController(text: '2026-2027');
  final _tagline = TextEditingController(text: 'Built Different');
  final _logoUrl = TextEditingController(text: 'https://placehold.co/200x200/png?text=LOGO');
  final _slug = TextEditingController();

  String _selectedDivision = 'High School Varsity';
  String _primaryColorName = 'Red';
  String _secondaryColorName = 'Columbia Blue';
  String _accentColorName = 'Black';
  String _surfaceColorName = 'Grey';
  bool _showAdvanced = false;
  String? _error;

  static const List<String> _divisionOptions = [
    'High School Varsity',
    'High School JV',
    'Middle School',
    'Youth Club',
    'College',
  ];

  static const Map<String, String> _namedColors = {
    'Red': '#D62828',
    'Columbia Blue': '#B9D6F2',
    'Black': '#111111',
    'Grey': '#6B7280',
    'White': '#FFFFFF',
    'Gold': '#FCBF49',
    'Orange': '#F77F00',
    'Navy': '#14213D',
    'Blue': '#1D4ED8',
    'Green': '#2A9D8F',
  };

  String _slugify(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return normalized.length >= 2 ? normalized : 'team-${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final seed = DateTime.now().microsecondsSinceEpoch;
    return List.generate(8, (index) => chars[(seed + index * 17) % chars.length]).join();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final slug = _slug.text.trim().isEmpty
        ? _slugify('${_schoolName.text.trim()} ${_teamName.text.trim()}')
        : _slugify(_slug.text.trim());

    try {
      await context.read<AppState>().createTeam({
            'name': _teamName.text.trim(),
            'slug': slug,
            'join_code': _generateJoinCode(),
            'school_name': _schoolName.text.trim(),
            'school_abbreviation': _abbr.text.trim(),
            'mascot_name': _mascot.text.trim(),
            'division': _selectedDivision,
            'season_label': _season.text.trim(),
            'tagline': _tagline.text.trim(),
            'logo_url': _logoUrl.text.trim(),
            'primary_color': _namedColors[_primaryColorName],
            'secondary_color': _namedColors[_secondaryColorName],
            'accent_color': _namedColors[_accentColorName],
            'surface_color': _namedColors[_surfaceColorName],
            'dark_mode': true,
          });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Team Setup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandedHeaderCard(
                    title: 'Build Your Team',
                    subtitle: 'Start with the basics, then dial in your look without fighting a crowded form.',
                  ),
                  const SizedBox(height: 18),
                  _sectionCard(
                    title: 'Essentials',
                    subtitle: 'The few things everyone needs first.',
                    child: Column(
                      children: [
                        _textField(_teamName, 'Team name'),
                        const SizedBox(height: 14),
                        _textField(_schoolName, 'School name'),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _textField(_abbr, 'Abbreviation')),
                            const SizedBox(width: 12),
                            Expanded(child: _textField(_mascot, 'Mascot')),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _dropdownField(
                          label: 'Division',
                          value: _selectedDivision,
                          items: _divisionOptions,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedDivision = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Look & Feel',
                    subtitle: 'Choose a cleaner palette with dropdowns instead of raw color codes.',
                    child: Column(
                      children: [
                        _colorDropdown(
                          label: 'Primary color',
                          value: _primaryColorName,
                          onChanged: (value) => setState(() => _primaryColorName = value!),
                        ),
                        const SizedBox(height: 12),
                        _colorDropdown(
                          label: 'Secondary color',
                          value: _secondaryColorName,
                          onChanged: (value) => setState(() => _secondaryColorName = value!),
                        ),
                        const SizedBox(height: 12),
                        _colorDropdown(
                          label: 'Accent color',
                          value: _accentColorName,
                          onChanged: (value) => setState(() => _accentColorName = value!),
                        ),
                        const SizedBox(height: 12),
                        _colorDropdown(
                          label: 'Surface color',
                          value: _surfaceColorName,
                          onChanged: (value) => setState(() => _surfaceColorName = value!),
                        ),
                        const SizedBox(height: 16),
                        _palettePreview(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Identity',
                    subtitle: 'Optional finishing touches for launch day.',
                    child: Column(
                      children: [
                        _textField(_tagline, 'Tagline'),
                        const SizedBox(height: 14),
                        _textField(_season, 'Season label'),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                            child: Text(_showAdvanced ? 'Hide advanced options' : 'Show advanced options'),
                          ),
                        ),
                        if (_showAdvanced) ...[
                          const SizedBox(height: 6),
                          _textField(_logoUrl, 'Logo URL'),
                          const SizedBox(height: 14),
                          _textField(_slug, 'Custom slug (optional)'),
                        ],
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A1216),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF8F2D38)),
                      ),
                      child: Text(
                        _error!,
                        style: textTheme.bodyMedium?.copyWith(color: const Color(0xFFFFB7C0), height: 1.4),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: appState.isBusy ? null : _submit,
                    child: Text(appState.isBusy ? 'Saving...' : 'Create Team'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11161F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _textField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _colorDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: _namedColors.entries
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Color(int.parse('FF${entry.value.substring(1)}', radix: 16)),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(entry.key),
                  const SizedBox(width: 10),
                  Text(entry.value, style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _palettePreview() {
    final palette = [
      _namedColors[_primaryColorName]!,
      _namedColors[_secondaryColorName]!,
      _namedColors[_accentColorName]!,
      _namedColors[_surfaceColorName]!,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1018),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final color in palette) ...[
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Color(int.parse('FF${color.substring(1)}', radix: 16)),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            if (color != palette.last) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

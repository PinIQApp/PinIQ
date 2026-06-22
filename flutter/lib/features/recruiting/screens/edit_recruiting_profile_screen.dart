import 'package:flutter/material.dart';

import '../models/recruiting_models.dart';
import '../services/recruiting_api_service.dart';
import '../widgets/recruiting_ui.dart';

class EditRecruitingProfileScreen extends StatefulWidget {
  const EditRecruitingProfileScreen({
    super.key,
    required this.api,
    required this.athleteId,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
    this.initialProfile,
  });

  final RecruitingApiService api;
  final int athleteId;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;
  final RecruitingProfileDetail? initialProfile;

  @override
  State<EditRecruitingProfileScreen> createState() => _EditRecruitingProfileScreenState();
}

class _EditRecruitingProfileScreenState extends State<EditRecruitingProfileScreen> {
  late final TextEditingController _schoolController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _gpaController;
  late final TextEditingController _bioController;
  late final TextEditingController _achievementsController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _imageController;
  late final TextEditingController _highlightOneController;
  late final TextEditingController _highlightTwoController;
  late final TextEditingController _statsTdController;
  late final TextEditingController _statsShotController;
  late int _graduationYear;
  late bool _isOpen;
  late bool _activelyLooking;
  late bool _showContactToCoaches;
  late bool _showGpa;
  late bool _parentVisibilityRequired;
  RecruitingVisibilityLevel _visibilityLevel = RecruitingVisibilityLevel.coachesOnly;
  RecruitingContactVisibility _contactVisibility = RecruitingContactVisibility.hidden;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _schoolController = TextEditingController(text: profile?.schoolTeam ?? '');
    _weightController = TextEditingController(text: profile?.weightClass ?? '');
    _heightController = TextEditingController(text: profile?.height ?? '');
    _gpaController = TextEditingController(text: profile?.gpa ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _achievementsController = TextEditingController(text: (profile?.achievements ?? const []).join('\n'));
    _emailController = TextEditingController(text: profile?.contact.email ?? '');
    _phoneController = TextEditingController(text: profile?.contact.phone ?? '');
    _locationController = TextEditingController(text: profile?.locationLabel ?? '');
    _imageController = TextEditingController(text: profile?.profileImageUrl ?? '');
    _highlightOneController = TextEditingController(
      text: profile != null && profile.highlights.isNotEmpty ? profile.highlights.first.highlightUrl : '',
    );
    _highlightTwoController = TextEditingController(
      text: profile != null && profile.highlights.length > 1 ? profile.highlights[1].highlightUrl : '',
    );
    _statsTdController = TextEditingController(
      text: profile == null
          ? ''
          : profile.statsMetrics
              .firstWhere(
                (metric) => metric.label == 'TD / Match',
                orElse: () => const RecruitingStatMetric(label: 'TD / Match', value: ''),
              )
              .value,
    );
    _statsShotController = TextEditingController(
      text: profile == null
          ? ''
          : profile.statsMetrics
              .firstWhere(
                (metric) => metric.label == 'Shot Conv.',
                orElse: () => const RecruitingStatMetric(label: 'Shot Conv.', value: ''),
              )
              .value
              .replaceAll('%', ''),
    );
    _graduationYear = profile?.graduationYear ?? DateTime.now().year + 1;
    _isOpen = profile?.isOpen ?? true;
    _activelyLooking = profile?.isActivelyLooking ?? false;
    _showContactToCoaches = profile?.visibility.showContactToCoaches ?? false;
    _showGpa = profile?.visibility.showGpa ?? false;
    _parentVisibilityRequired = profile?.visibility.parentVisibilityRequired ?? true;
    _visibilityLevel = profile?.visibilityLevel ?? RecruitingVisibilityLevel.coachesOnly;
    _contactVisibility = profile?.contactVisibility ?? RecruitingContactVisibility.hidden;
  }

  @override
  void dispose() {
    _schoolController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _gpaController.dispose();
    _bioController.dispose();
    _achievementsController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _imageController.dispose();
    _highlightOneController.dispose();
    _highlightTwoController.dispose();
    _statsTdController.dispose();
    _statsShotController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final draft = RecruitingProfileDraft(
      athleteId: widget.athleteId,
      graduationYear: _graduationYear,
      schoolTeam: _schoolController.text.trim(),
      weightClass: _weightController.text.trim(),
      height: _heightController.text.trim(),
      gpa: _gpaController.text.trim(),
      bio: _bioController.text.trim(),
      achievements: _achievementsController.text
          .split('\n')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      contactEmail: _emailController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      locationLabel: _locationController.text.trim(),
      profileImageUrl: _imageController.text.trim(),
      isOpen: _isOpen,
      isActivelyLooking: _activelyLooking,
      isFeatured: widget.initialProfile?.isFeatured ?? false,
      boostRequested: widget.initialProfile?.boostRequested ?? false,
      visibilityLevel: _visibilityLevel,
      contactVisibility: _contactVisibility,
      visibilitySettings: RecruitingVisibilitySettingsDraft(
        showContactToCoaches: _showContactToCoaches,
        showGpa: _showGpa,
        showLocation: true,
        showProfilePhoto: true,
        parentVisibilityRequired: _parentVisibilityRequired,
        allowDirectContactRequest: true,
      ),
      highlights: [
        if (_highlightOneController.text.trim().isNotEmpty)
          RecruitingHighlightDraft(title: 'Highlight 1', highlightUrl: _highlightOneController.text.trim(), sortOrder: 0),
        if (_highlightTwoController.text.trim().isNotEmpty)
          RecruitingHighlightDraft(title: 'Highlight 2', highlightUrl: _highlightTwoController.text.trim(), sortOrder: 1),
      ],
      statsSummary: {
        if (_statsTdController.text.trim().isNotEmpty)
          'takedowns_per_match': double.tryParse(_statsTdController.text.trim()) ?? 0,
        if (_statsShotController.text.trim().isNotEmpty)
          'shot_conversion_rate': (double.tryParse(_statsShotController.text.trim()) ?? 0) / 100,
      },
    );

    try {
      final profile = widget.initialProfile == null
          ? await widget.api.createProfile(draft)
          : await widget.api.updateProfile(athleteId: widget.athleteId, draft: draft);
      if (!mounted) return;
      Navigator.of(context).pop(profile);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Edit Recruiting Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          RecruitingPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RecruitingSectionTitle('Profile Details'),
                const SizedBox(height: 12),
                _input(_schoolController, 'School / team'),
                _row(
                  _input(_weightController, 'Weight class'),
                  _input(_heightController, 'Height'),
                ),
                _row(
                  _dropdownYear(),
                  _input(_gpaController, 'GPA (optional)'),
                ),
                _input(_locationController, 'Location'),
                _input(_imageController, 'Profile image URL'),
                _input(_bioController, 'Bio', maxLines: 5),
                _input(_achievementsController, 'Achievements (one per line)', maxLines: 4),
              ],
            ),
          ),
          const SizedBox(height: 18),
          RecruitingPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RecruitingSectionTitle('Film + Stats'),
                const SizedBox(height: 12),
                _input(_highlightOneController, 'Highlight URL 1'),
                _input(_highlightTwoController, 'Highlight URL 2'),
                _row(
                  _input(_statsTdController, 'Takedowns / match'),
                  _input(_statsShotController, 'Shot conversion %'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          RecruitingPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RecruitingSectionTitle('Exposure + Visibility'),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isOpen,
                  onChanged: (value) => setState(() => _isOpen = value),
                  title: const Text('Open to recruiting', style: TextStyle(color: Colors.white)),
                ),
                SwitchListTile(
                  value: _activelyLooking,
                  onChanged: (value) => setState(() => _activelyLooking = value),
                  title: const Text('Actively looking', style: TextStyle(color: Colors.white)),
                ),
                SwitchListTile(
                  value: _showContactToCoaches,
                  onChanged: (value) => setState(() => _showContactToCoaches = value),
                  title: const Text('Show contact to coaches', style: TextStyle(color: Colors.white)),
                ),
                SwitchListTile(
                  value: _showGpa,
                  onChanged: (value) => setState(() => _showGpa = value),
                  title: const Text('Show GPA', style: TextStyle(color: Colors.white)),
                ),
                SwitchListTile(
                  value: _parentVisibilityRequired,
                  onChanged: (value) => setState(() => _parentVisibilityRequired = value),
                  title: const Text('Require parent visibility', style: TextStyle(color: Colors.white)),
                ),
                DropdownButtonFormField<RecruitingVisibilityLevel>(
                  value: _visibilityLevel,
                  dropdownColor: const Color(0xFF161E29),
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('Profile visibility'),
                  items: RecruitingVisibilityLevel.values
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name.replaceAll('Profile', '').replaceAll('Only', ' only')),
                          ))
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _visibilityLevel = value ?? _visibilityLevel),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RecruitingContactVisibility>(
                  value: _contactVisibility,
                  dropdownColor: const Color(0xFF161E29),
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('Contact visibility'),
                  items: RecruitingContactVisibility.values
                      .map((value) => DropdownMenuItem(value: value, child: Text(value.name)))
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _contactVisibility = value ?? _contactVisibility),
                ),
                const SizedBox(height: 12),
                _input(_emailController, 'Contact email'),
                _input(_phoneController, 'Contact phone'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: widget.schoolPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_saving ? 'Saving...' : 'Save Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _dropdownYear() {
    return DropdownButtonFormField<int>(
      value: _graduationYear,
      dropdownColor: const Color(0xFF161E29),
      style: const TextStyle(color: Colors.white),
      decoration: _decoration('Graduation year'),
      items: List.generate(8, (index) => DateTime.now().year + index)
          .map((year) => DropdownMenuItem(value: year, child: Text(year.toString())))
          .toList(growable: false),
      onChanged: (value) => setState(() => _graduationYear = value ?? _graduationYear),
    );
  }

  Widget _input(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: _decoration(label),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF96A4B7)),
      filled: true,
      fillColor: const Color(0xFF0F141C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.white10),
      ),
    );
  }
}

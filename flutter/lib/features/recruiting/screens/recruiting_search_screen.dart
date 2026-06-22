import 'package:flutter/material.dart';

import '../models/recruiting_models.dart';
import '../services/recruiting_api_service.dart';
import '../widgets/recruiting_ui.dart';
import 'athlete_recruiting_profile_screen.dart';

class RecruitingSearchScreen extends StatefulWidget {
  const RecruitingSearchScreen({
    super.key,
    required this.api,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
  });

  final RecruitingApiService api;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;

  @override
  State<RecruitingSearchScreen> createState() => _RecruitingSearchScreenState();
}

class _RecruitingSearchScreenState extends State<RecruitingSearchScreen> {
  final _queryController = TextEditingController();
  final _locationController = TextEditingController();
  final _weightController = TextEditingController();
  int? _graduationYear;
  double _minWinPercentage = 0;
  double _minTakedowns = 0;
  late Future<RecruitingSearchResponseModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _search();
  }

  Future<RecruitingSearchResponseModel> _search() {
    return widget.api.searchAthletes(
      query: _queryController.text.trim().isEmpty ? null : _queryController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      weightClass: _weightController.text.trim().isEmpty ? null : _weightController.text.trim(),
      graduationYear: _graduationYear,
      minWinPercentage: _minWinPercentage <= 0 ? null : _minWinPercentage,
      minTakedownsPerMatch: _minTakedowns <= 0 ? null : _minTakedowns,
      isOpen: true,
    );
  }

  Future<void> _runSearch() async {
    setState(() {
      _future = _search();
    });
    await _future;
  }

  @override
  void dispose() {
    _queryController.dispose();
    _locationController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Recruiting Search'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          RecruitingPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RecruitingSectionTitle('Filter Athletes'),
                const SizedBox(height: 12),
                TextField(
                  controller: _queryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Name, school, bio, achievements'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Weight class'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _locationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Location'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  dropdownColor: const Color(0xFF161E29),
                  value: _graduationYear,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Graduation year'),
                  items: List.generate(8, (index) => 2025 + index)
                      .map((year) => DropdownMenuItem(value: year, child: Text(year.toString())))
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _graduationYear = value),
                ),
                const SizedBox(height: 14),
                _slider(
                  label: 'Minimum win percentage',
                  value: _minWinPercentage,
                  valueText: '${(_minWinPercentage * 100).round()}%',
                  onChanged: (value) => setState(() => _minWinPercentage = value),
                ),
                _slider(
                  label: 'Minimum takedowns per match',
                  value: _minTakedowns,
                  max: 6,
                  valueText: _minTakedowns.toStringAsFixed(1),
                  onChanged: (value) => setState(() => _minTakedowns = value),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _runSearch,
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.schoolPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Run Search'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FutureBuilder<RecruitingSearchResponseModel>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ));
              }
              if (snapshot.hasError) {
                return Text(snapshot.error.toString(), style: const TextStyle(color: Colors.redAccent));
              }
              final data = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.total} athletes found',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ...data.results.map(
                    (athlete) => RecruitingAthleteCardView(
                      athlete: athlete,
                      primaryColor: widget.schoolPrimaryColor,
                      accentColor: widget.schoolAccentColor,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AthleteRecruitingProfileScreen(
                              api: widget.api,
                              athleteId: athlete.athleteId,
                              schoolPrimaryColor: widget.schoolPrimaryColor,
                              schoolAccentColor: widget.schoolAccentColor,
                            ),
                          ),
                        );
                      },
                      trailing: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.visibility_outlined, color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
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

  Widget _slider({
    required String label,
    required double value,
    required String valueText,
    required ValueChanged<double> onChanged,
    double max = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        Slider(
          value: value,
          max: max,
          activeColor: widget.schoolAccentColor,
          inactiveColor: Colors.white12,
          label: valueText,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

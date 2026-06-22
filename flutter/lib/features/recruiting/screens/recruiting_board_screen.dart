import 'package:flutter/material.dart';

import '../models/recruiting_models.dart';
import '../services/recruiting_api_service.dart';
import '../widgets/recruiting_ui.dart';
import 'athlete_recruiting_profile_screen.dart';

class RecruitingBoardScreen extends StatefulWidget {
  const RecruitingBoardScreen({
    super.key,
    required this.api,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
  });

  final RecruitingApiService api;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;

  @override
  State<RecruitingBoardScreen> createState() => _RecruitingBoardScreenState();
}

class _RecruitingBoardScreenState extends State<RecruitingBoardScreen> {
  late Future<RecruitingBoard> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchBoard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Recruiting Board'),
      ),
      body: FutureBuilder<RecruitingBoard>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(snapshot.error.toString(), style: const TextStyle(color: Colors.redAccent)),
              ),
            );
          }
          final board = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _section('Trending Athletes', board.trendingAthletes),
              const SizedBox(height: 18),
              _section('Featured Athletes', board.featuredAthletes),
              const SizedBox(height: 18),
              _section('Recently Updated', board.recentlyUpdated),
              const SizedBox(height: 18),
              _section('Top Performers', board.topPerformers),
            ],
          );
        },
      ),
    );
  }

  Widget _section(String title, List<RecruitingAthleteCard> athletes) {
    return RecruitingPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecruitingSectionTitle(title),
          const SizedBox(height: 12),
          ...athletes.map(
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
            ),
          ),
        ],
      ),
    );
  }
}

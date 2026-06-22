import 'package:flutter/material.dart';
import '../models/recruiting_models.dart';
import '../services/recruiting_api_service.dart';
import '../widgets/recruiting_ui.dart';

class AthleteRecruitingProfileScreen extends StatefulWidget {
  const AthleteRecruitingProfileScreen({
    super.key,
    required this.api,
    required this.athleteId,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
  });

  final RecruitingApiService api;
  final int athleteId;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;

  @override
  State<AthleteRecruitingProfileScreen> createState() => _AthleteRecruitingProfileScreenState();
}

class _AthleteRecruitingProfileScreenState extends State<AthleteRecruitingProfileScreen> {
  late Future<RecruitingProfileDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchAthleteProfile(widget.athleteId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.api.fetchAthleteProfile(widget.athleteId);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Recruiting Profile'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<RecruitingProfileDetail>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(snapshot.error.toString(), style: const TextStyle(color: Colors.redAccent)),
                ],
              );
            }
            final profile = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _header(profile),
                const SizedBox(height: 18),
                RecruitingPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RecruitingSectionTitle('Performance Snapshot'),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _factCard('Record', profile.record),
                          _factCard('Weight', profile.weightClass),
                          _factCard('Class', '${profile.graduationYear}'),
                          if (profile.height != null) _factCard('Height', profile.height!),
                          if (profile.gpa != null) _factCard('GPA', profile.gpa!),
                        ],
                      ),
                      if (profile.statsMetrics.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: profile.statsMetrics
                              .map((metric) => RecruitingMetricChip(metric: metric, tint: widget.schoolAccentColor))
                              .toList(growable: false),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                RecruitingPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RecruitingSectionTitle('Achievements'),
                      const SizedBox(height: 12),
                      ...profile.achievements.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            '• $item',
                            style: const TextStyle(color: Color(0xFFD4DEEB), height: 1.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                RecruitingPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RecruitingSectionTitle('Film'),
                      const SizedBox(height: 12),
                      ...profile.highlights.map(
                        (clip) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: widget.schoolAccentColor.withOpacity(0.15),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                          ),
                          title: Text(clip.title, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            clip.highlightUrl,
                            style: const TextStyle(color: Color(0xFF9CAEC4)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.link_rounded, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                RecruitingPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RecruitingSectionTitle('Bio'),
                      const SizedBox(height: 10),
                      Text(
                        profile.bio ?? 'No bio added yet.',
                        style: const TextStyle(color: Color(0xFFD4DEEB), height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                RecruitingPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RecruitingSectionTitle('Recent Matches'),
                      const SizedBox(height: 12),
                      ...profile.recentMatches.map(
                        (match) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${match.opponentName} • ${match.scoreDisplay}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${match.eventName ?? 'Recent event'} • ${match.weightClass} • ${match.result.toUpperCase()}',
                            style: const TextStyle(color: Color(0xFF9CAEC4)),
                          ),
                          trailing: Text(
                            '${match.matchDate.month}/${match.matchDate.day}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                RecruitingPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RecruitingSectionTitle('Contact'),
                      const SizedBox(height: 10),
                      Text(
                        profile.contact.visibleToViewer
                            ? 'Email: ${profile.contact.email ?? 'Not listed'}\nPhone: ${profile.contact.phone ?? 'Not listed'}'
                            : profile.contact.complianceMessage ?? 'Contact information is hidden.',
                        style: const TextStyle(color: Color(0xFFD4DEEB), height: 1.5),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Messaging route: ${profile.contact.messagingEntrypoint}',
                        style: const TextStyle(color: Color(0xFF8CA0BA)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(RecruitingProfileDetail profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.schoolPrimaryColor.withOpacity(0.5),
            widget.schoolAccentColor.withOpacity(0.22),
            const Color(0xFF111923),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty
                    ? NetworkImage(profile.profileImageUrl!)
                    : null,
                backgroundColor: Colors.white12,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.athleteName,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${profile.schoolTeam ?? 'Independent athlete'} • ${profile.locationLabel ?? 'Location hidden'}',
                      style: const TextStyle(color: Color(0xFFE1E8F2)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              RecruitingStatusPill(
                label: profile.isActivelyLooking ? 'Actively Looking' : 'Open To Recruiting',
                color: widget.schoolAccentColor,
              ),
              if (profile.isFeatured)
                const RecruitingStatusPill(label: 'Featured', color: Color(0xFFFF7B54)),
              RecruitingStatusPill(label: 'Visibility: ${profile.visibleAs}', color: widget.schoolPrimaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _factCard(String label, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF93A4BC), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

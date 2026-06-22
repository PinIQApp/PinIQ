import 'package:flutter/material.dart';

import '../models/tournament_models.dart';

class TournamentSurface extends StatelessWidget {
  const TournamentSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2D5C2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class TournamentSectionTitle extends StatelessWidget {
  const TournamentSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1D1A15),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF6F6256),
            ),
          ),
        ],
      ],
    );
  }
}

class TournamentTag extends StatelessWidget {
  const TournamentTag({
    super.key,
    required this.label,
    this.color = const Color(0xFF8B1E3F),
    this.backgroundColor = const Color(0xFFF3D8DE),
  });

  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class TournamentCard extends StatelessWidget {
  const TournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
    this.onSave,
  });

  final TournamentSummaryModel tournament;
  final VoidCallback onTap;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE6D7C4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1F1B16),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${tournament.dateLabel} • ${tournament.locationLabel.isEmpty ? 'Location pending' : tournament.locationLabel}',
                        style: const TextStyle(
                          color: Color(0xFF675D53),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onSave != null)
                  IconButton(
                    onPressed: onSave,
                    icon: Icon(
                      tournament.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: const Color(0xFF8B1E3F),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TournamentTag(label: tournament.sourceLabel),
                TournamentTag(
                  label: tournament.eventType.toUpperCase(),
                  color: const Color(0xFF6D4C1D),
                  backgroundColor: const Color(0xFFF8E4B7),
                ),
                if (tournament.isOnTeamSchedule)
                  const TournamentTag(
                    label: 'On Schedule',
                    color: Color(0xFF135C3B),
                    backgroundColor: Color(0xFFD6F0E2),
                  ),
                if (tournament.distanceMiles != null)
                  TournamentTag(
                    label: '${tournament.distanceMiles!.toStringAsFixed(0)} mi',
                    color: const Color(0xFF164A72),
                    backgroundColor: const Color(0xFFD9ECFA),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tournament.description ?? 'Tournament details and registration info available in the detail view.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF5A5046),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TournamentFilterField extends StatelessWidget {
  const TournamentFilterField({
    super.key,
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD8C8B5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD8C8B5)),
        ),
      ),
    );
  }
}

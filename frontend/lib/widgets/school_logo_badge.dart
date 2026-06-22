import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/team_model.dart';

class SchoolLogoBadge extends StatelessWidget {
  const SchoolLogoBadge({
    super.key,
    required this.team,
    this.radius = 32,
    this.showLabel = false,
  });

  final TeamModel? team;
  final double radius;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final abbreviation = (team?.schoolAbbreviation?.isNotEmpty == true
            ? team!.schoolAbbreviation!
            : _fallbackInitials(team))
        .toUpperCase();

    final badge = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: team?.logoUrl?.isNotEmpty == true
            ? Image.network(
                _resolvedLogoUrl(team!.logoUrl!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackMark(abbreviation),
              )
            : _fallbackMark(abbreviation),
      ),
    );

    if (!showLabel) return badge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                team?.schoolName ?? 'Pin IQ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                team?.mascotName ?? 'Program',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallbackMark(String text) {
    return Image.asset(
      'assets/images/wrestletech_icon.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: radius * 0.45,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  String _resolvedLogoUrl(String logoUrl) {
    if (logoUrl.startsWith('http://') || logoUrl.startsWith('https://')) {
      return logoUrl;
    }
    final host = kIsWeb
        ? (Uri.base.host.isEmpty ? '127.0.0.1' : Uri.base.host)
        : '127.0.0.1';
    return 'http://$host:8000$logoUrl';
  }

  String _fallbackInitials(TeamModel? team) {
    final school = team?.schoolName ?? 'Pin IQ';
    final parts =
        school.split(' ').where((part) => part.trim().isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1);
    }
    return '${parts.first[0]}${parts.last[0]}';
  }
}

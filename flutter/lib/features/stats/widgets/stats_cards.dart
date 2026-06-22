import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/stats_models.dart';

final _dateFormat = DateFormat('MMM d');

class StatsMetricCard extends StatelessWidget {
  const StatsMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.accentColor = const Color(0xFFE6B800),
  });

  final String label;
  final String value;
  final String? caption;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151A22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF8690A5),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 6),
            Text(
              caption!,
              style: const TextStyle(
                color: Color(0xFFB6C0D2),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LeaderTile extends StatelessWidget {
  const LeaderTile({
    super.key,
    required this.entry,
  });

  final LeaderEntryModel entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121720),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF202A39),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              entry.metricValue % 1 == 0
                  ? entry.metricValue.toStringAsFixed(0)
                  : '${(entry.metricValue * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.athleteName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.metricLabel}${entry.subtitle != null ? ' • ${entry.subtitle}' : ''}',
                  style: const TextStyle(color: Color(0xFF97A1B4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MatchHistoryTile extends StatelessWidget {
  const MatchHistoryTile({
    super.key,
    required this.match,
  });

  final MatchEntry match;

  @override
  Widget build(BuildContext context) {
    final isWin = match.result == MatchOutcome.win;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121720),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isWin ? const Color(0xFF17361E) : const Color(0xFF37171B),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isWin ? 'WIN' : 'LOSS',
                  style: TextStyle(
                    color: isWin ? const Color(0xFF7DFFA0) : const Color(0xFFFF9AA7),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _dateFormat.format(match.matchDate.toLocal()),
                style: const TextStyle(color: Color(0xFF93A0B7)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            match.opponentName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if ((match.opponentSchool ?? '').isNotEmpty) match.opponentSchool,
              if ((match.eventName ?? '').isNotEmpty) match.eventName,
              match.weightClass,
              match.scoreDisplay,
              matchResultTypeLabel(match.resultType),
            ].join('  •  '),
            style: const TextStyle(color: Color(0xFFA7B1C3), height: 1.35),
          ),
          if (match.stats != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill('TD', '${match.stats!.takedowns}'),
                _pill('Esc', '${match.stats!.escapes}'),
                _pill('Rev', '${match.stats!.reversals}'),
                _pill('NF', '${match.stats!.nearfallPoints}'),
              ],
            ),
          ],
          if ((match.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              match.notes!,
              style: const TextStyle(color: Color(0xFFD8DFEB), height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2430),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: Color(0xFFE4EAF5),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SummaryTextPanel extends StatelessWidget {
  const SummaryTextPanel({
    super.key,
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final line in lines) ...[
            Text(
              '• $line',
              style: const TextStyle(color: Color(0xFFD4DBE7), height: 1.4),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

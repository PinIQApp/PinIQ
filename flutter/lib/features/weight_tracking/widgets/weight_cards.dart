import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weight_models.dart';
import 'weight_status_chip.dart';

final _dateTimeFormat = DateFormat('MMM d, h:mm a');
final _dateFormat = DateFormat('MMM d');

class WeightMetricCard extends StatelessWidget {
  const WeightMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
  });

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF191D25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF8B94A7),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 6),
            Text(
              caption!,
              style: const TextStyle(color: Color(0xFFB7C0D1), height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}

class AlertTile extends StatelessWidget {
  const AlertTile({
    super.key,
    required this.alert,
  });

  final WeightAlertItem alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171B23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WeightStatusChip(status: alert.severity),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.alertMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _dateTimeFormat.format(alert.triggeredAt.toLocal()),
                  style: const TextStyle(color: Color(0xFF96A0B5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeightLogTile extends StatelessWidget {
  const WeightLogTile({
    super.key,
    required this.log,
  });

  final WeightLogEntry log;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151A22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${log.weight.toStringAsFixed(1)} lbs',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                _dateTimeFormat.format(log.loggedAt.toLocal()),
                style: const TextStyle(color: Color(0xFF9AA3B2)),
              ),
            ],
          ),
          if (log.bodyFatPercentage != null) ...[
            const SizedBox(height: 8),
            Text(
              'Body fat: ${log.bodyFatPercentage!.toStringAsFixed(1)}%',
              style: const TextStyle(color: Color(0xFFE2E8F0)),
            ),
          ],
          if ((log.hydrationNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Hydration: ${log.hydrationNote}',
              style: const TextStyle(color: Color(0xFF8BD9F2)),
            ),
          ],
          if ((log.comments ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              log.comments!,
              style: const TextStyle(color: Color(0xFFB9C2D2), height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}

class AthleteSnapshotCard extends StatelessWidget {
  const AthleteSnapshotCard({
    super.key,
    required this.snapshot,
    this.onTap,
  });

  final AthleteWeightSnapshot snapshot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141922),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snapshot.athleteName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (snapshot.teamGroup != null) snapshot.teamGroup,
                          if (snapshot.gradeLabel != null)
                            'Grade ${snapshot.gradeLabel}',
                        ].join('  •  '),
                        style: const TextStyle(color: Color(0xFF96A0B5)),
                      ),
                    ],
                  ),
                ),
                WeightStatusChip(status: snapshot.status),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _pill('Current', _displayWeight(snapshot.currentWeight)),
                _pill('Target', _displayWeight(snapshot.targetWeightClass)),
                _pill('Reachable', _displayWeight(snapshot.projectedClass)),
                _pill(
                  'Log',
                  snapshot.latestLogAt != null
                      ? _dateFormat.format(snapshot.latestLogAt!.toLocal())
                      : 'Missing',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              snapshot.statusSummary,
              style: const TextStyle(
                color: Color(0xFFE7ECF5),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            if ((snapshot.warningMessage ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                snapshot.warningMessage!,
                style: const TextStyle(color: Color(0xFFFFC6A1), height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2430),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFFCFD8E7),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _displayWeight(double? weight) {
    if (weight == null) {
      return '--';
    }
    return '${weight.toStringAsFixed(1)}';
  }
}

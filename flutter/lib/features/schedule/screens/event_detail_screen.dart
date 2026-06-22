import 'package:flutter/material.dart';

import '../models/schedule_models.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({
    super.key,
    required this.event,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
  });

  final ScheduleEventItem event;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(event.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  schoolPrimaryColor.withOpacity(0.5),
                  schoolAccentColor.withOpacity(0.18),
                  const Color(0xFF131A23),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chip(scheduleEventTypeLabel(event.eventType)),
                const SizedBox(height: 12),
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${_dateLabel(event.startsAt)} • ${_timeLabel(event.startsAt)} - ${_timeLabel(event.endsAt)}',
                  style: const TextStyle(
                    color: Color(0xFFD7E0EF),
                    fontSize: 15,
                  ),
                ),
                if (event.location != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    event.location!,
                    style: const TextStyle(
                      color: Color(0xFFEAF1FF),
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _section(
            'Event Notes',
            event.notes ?? event.description ?? 'No extra notes yet.',
          ),
          if (event.checklist.isNotEmpty) ...[
            const SizedBox(height: 16),
            _checklistSection(),
          ],
          if (event.busDepartureNote != null || event.weighInNote != null) ...[
            const SizedBox(height: 16),
            _logisticsSection(),
          ],
          if (event.practicePlan != null) ...[
            const SizedBox(height: 16),
            _practiceSection(),
          ],
        ],
      ),
    );
  }

  Widget _checklistSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gear / Checklist',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...event.checklist.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: schoolAccentColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(color: Color(0xFFD7E0EF)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logisticsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Logistics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (event.busDepartureNote != null) ...[
            const SizedBox(height: 12),
            Text(
              'Bus: ${event.busDepartureNote}',
              style: const TextStyle(color: Color(0xFFD7E0EF), height: 1.45),
            ),
          ],
          if (event.weighInNote != null) ...[
            const SizedBox(height: 10),
            Text(
              'Weigh-In: ${event.weighInNote}',
              style: const TextStyle(color: Color(0xFFD7E0EF), height: 1.45),
            ),
          ],
        ],
      ),
    );
  }

  Widget _practiceSection() {
    final practice = event.practicePlan!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Practice Plan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${practice.totalDurationMinutes} min • ${practice.totalBlockCount} blocks',
            style: const TextStyle(color: Color(0xFF97A1B4)),
          ),
          const SizedBox(height: 14),
          ...practice.blocks.map(
            (block) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: schoolPrimaryColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${block.durationMinutes}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          block.title ??
                              practiceBlockTypeLabel(block.blockType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          practiceBlockTypeLabel(block.blockType),
                          style: const TextStyle(color: Color(0xFF97A1B4)),
                        ),
                        if ((block.notes ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            block.notes!,
                            style: const TextStyle(
                              color: Color(0xFFD7E0EF),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(color: Color(0xFFD7E0EF), height: 1.5),
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration() => BoxDecoration(
    color: const Color(0xFF121821),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.white10),
  );

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _dateLabel(DateTime value) =>
      '${_weekday(value.weekday)}, ${_month(value.month)} ${value.day}';

  String _timeLabel(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final meridiem = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $meridiem';
  }

  String _weekday(int day) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];

  String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}

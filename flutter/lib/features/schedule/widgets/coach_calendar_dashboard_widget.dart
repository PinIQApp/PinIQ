import 'package:flutter/material.dart';

import '../models/schedule_models.dart';

class CoachCalendarDashboardWidget extends StatelessWidget {
  const CoachCalendarDashboardWidget({
    super.key,
    required this.events,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
    this.onQuickAddEvent,
    this.onQuickAddPractice,
  });

  final List<ScheduleEventItem> events;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;
  final VoidCallback? onQuickAddEvent;
  final VoidCallback? onQuickAddPractice;

  @override
  Widget build(BuildContext context) {
    final upcomingWeek = events
        .where((event) {
          final now = DateTime.now();
          return !event.startsAt.isBefore(now) &&
              event.startsAt.isBefore(now.add(const Duration(days: 7)));
        })
        .take(5)
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            schoolPrimaryColor.withOpacity(0.35),
            const Color(0xFF121821),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coach Calendar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upcoming week at a glance, with fast entry points for room planning.',
            style: TextStyle(color: Color(0xFFD7E0EF), height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onQuickAddEvent,
                  style: FilledButton.styleFrom(
                    backgroundColor: schoolAccentColor,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Quick Add Event'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onQuickAddPractice,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: const Text('Quick Add Practice'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (upcomingWeek.isEmpty)
            const Text(
              'No events scheduled in the next week.',
              style: TextStyle(color: Color(0xFF97A1B4)),
            )
          else
            ...upcomingWeek.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F151D),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: schoolAccentColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            '${event.startsAt.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${scheduleEventTypeLabel(event.eventType)} • ${_weekday(event.startsAt.weekday)} ${_timeLabel(event.startsAt)}',
                              style: const TextStyle(color: Color(0xFFD7E0EF)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _weekday(int day) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];

  String _timeLabel(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final meridiem = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $meridiem';
  }
}

import 'package:flutter/material.dart';

import '../models/schedule_models.dart';
import '../services/schedule_api_service.dart';
import 'event_detail_screen.dart';

class TeamScheduleScreen extends StatefulWidget {
  const TeamScheduleScreen({
    super.key,
    required this.api,
    required this.teamId,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
  });

  final ScheduleApiService api;
  final int teamId;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;

  @override
  State<TeamScheduleScreen> createState() => _TeamScheduleScreenState();
}

class _TeamScheduleScreenState extends State<TeamScheduleScreen>
    with SingleTickerProviderStateMixin {
  ScheduleEventType? _selectedFilter;
  late Future<TeamScheduleBundle> _scheduleFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    _scheduleFuture = widget.api.fetchTeamSchedule(
      teamId: widget.teamId,
      eventType: _selectedFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Team Schedule'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: widget.schoolAccentColor,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF97A1B4),
          tabs: const [
            Tab(text: 'Month'),
            Tab(text: 'Week'),
            Tab(text: 'List'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await _scheduleFuture;
        },
        child: FutureBuilder<TeamScheduleBundle>(
          future: _scheduleFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
              );
            }

            final bundle = snapshot.data!;
            final upcoming = bundle.events
                .where((event) => !event.startsAt.isBefore(DateTime.now()))
                .toList();
            final weekEvents = upcoming.take(7).toList();

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    children: [
                      _header(bundle),
                      const SizedBox(height: 16),
                      _filters(),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _monthView(bundle.events),
                            _weekView(weekEvents),
                            _listView(bundle.events),
                          ],
                        ),
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

  Widget _header(TeamScheduleBundle bundle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.schoolPrimaryColor.withOpacity(0.45),
            widget.schoolAccentColor.withOpacity(0.18),
            const Color(0xFF121821),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WrestleTech Team Calendar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visible as ${bundle.visibleAs.replaceAll('_', ' ')}. ${bundle.summary.upcomingWeekCount} items in the next week.',
            style: const TextStyle(color: Color(0xFFD7E0EF), height: 1.45),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statPill('Events', '${bundle.summary.totalEvents}'),
              _statPill('Practices', '${bundle.summary.practiceCount}'),
              _statPill('Competition', '${bundle.summary.competitionCount}'),
              _statPill('Travel', '${bundle.summary.travelCount}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    final items = <ScheduleEventType?>[
      null,
      ScheduleEventType.practice,
      ScheduleEventType.dualMeet,
      ScheduleEventType.tournament,
      ScheduleEventType.travel,
      ScheduleEventType.teamMeeting,
      ScheduleEventType.fundraiser,
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final value = items[index];
          final selected = value == _selectedFilter;
          return ChoiceChip(
            selected: selected,
            label: Text(value == null ? 'All' : scheduleEventTypeLabel(value)),
            backgroundColor: const Color(0xFF121821),
            selectedColor: widget.schoolAccentColor,
            side: const BorderSide(color: Colors.white10),
            labelStyle: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w700,
            ),
            onSelected: (_) {
              setState(() {
                _selectedFilter = value;
                _reload();
              });
            },
          );
        },
      ),
    );
  }

  Widget _monthView(List<ScheduleEventItem> events) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leading = firstDay.weekday - 1;
    final cells =
        List<int?>.generate(leading, (_) => null) +
        List<int?>.generate(daysInMonth, (index) => index + 1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_month(now.month)} ${now.year}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${events.length} scheduled items',
                style: const TextStyle(color: Color(0xFF97A1B4)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeekdayLabel('M'),
              _WeekdayLabel('T'),
              _WeekdayLabel('W'),
              _WeekdayLabel('T'),
              _WeekdayLabel('F'),
              _WeekdayLabel('S'),
              _WeekdayLabel('S'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cells.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final day = cells[index];
                if (day == null) {
                  return const SizedBox.shrink();
                }
                final dayEvents = events
                    .where(
                      (event) =>
                          event.startsAt.year == now.year &&
                          event.startsAt.month == now.month &&
                          event.startsAt.day == day,
                    )
                    .toList();
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E141C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: day == now.day
                          ? widget.schoolAccentColor
                          : Colors.white10,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$day',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...dayEvents
                          .take(3)
                          .map(
                            (event) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: GestureDetector(
                                onTap: () => _openEvent(event),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _eventColor(
                                      event.eventType,
                                    ).withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    event.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _eventColor(event.eventType),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekView(List<ScheduleEventItem> events) {
    if (events.isEmpty) {
      return _emptyState('No upcoming events in the next 7 days.');
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: ListView.separated(
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final event = events[index];
          return _eventCard(event, compact: false);
        },
      ),
    );
  }

  Widget _listView(List<ScheduleEventItem> events) {
    if (events.isEmpty) {
      return _emptyState('No events match the current filter.');
    }
    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _eventCard(events[index], compact: true),
    );
  }

  Widget _eventCard(ScheduleEventItem event, {required bool compact}) {
    return InkWell(
      onTap: () => _openEvent(event),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _panelDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 54 : 62,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: _eventColor(event.eventType).withOpacity(0.18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Text(
                    _month(event.startsAt.month).substring(0, 3).toUpperCase(),
                    style: TextStyle(
                      color: _eventColor(event.eventType),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${event.startsAt.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          scheduleEventTypeLabel(event.eventType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_weekday(event.startsAt.weekday)}, ${_timeLabel(event.startsAt)} - ${_timeLabel(event.endsAt)}',
                    style: const TextStyle(color: Color(0xFF97A1B4)),
                  ),
                  if (event.location != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      event.location!,
                      style: const TextStyle(color: Color(0xFFD7E0EF)),
                    ),
                  ],
                  if ((event.notes ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.notes!,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _emptyState(String label) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _panelDecoration(),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFF97A1B4)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _statPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD7E0EF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _eventColor(ScheduleEventType type) {
    switch (type) {
      case ScheduleEventType.practice:
        return widget.schoolAccentColor;
      case ScheduleEventType.dualMeet:
        return const Color(0xFF5DD39E);
      case ScheduleEventType.tournament:
        return const Color(0xFF7AB8FF);
      case ScheduleEventType.travel:
        return const Color(0xFFF4A261);
      case ScheduleEventType.teamMeeting:
        return const Color(0xFFB8C0FF);
      case ScheduleEventType.fundraiser:
        return const Color(0xFFFF8FAB);
    }
  }

  BoxDecoration _panelDecoration() => BoxDecoration(
    color: const Color(0xFF121821),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white10),
  );

  void _openEvent(ScheduleEventItem event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          event: event,
          schoolPrimaryColor: widget.schoolPrimaryColor,
          schoolAccentColor: widget.schoolAccentColor,
        ),
      ),
    );
  }

  String _timeLabel(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final meridiem = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $meridiem';
  }

  String _weekday(int day) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];

  String _month(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF97A1B4),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

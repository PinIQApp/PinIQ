class WatchFeatureCardModel {
  const WatchFeatureCardModel({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.note,
    required this.lane,
  });

  final String title;
  final String subtitle;
  final String value;
  final String note;
  final String lane;
}

class WatchReminderModel {
  const WatchReminderModel({
    required this.title,
    required this.timeLabel,
    required this.kind,
    required this.note,
  });

  final String title;
  final String timeLabel;
  final String kind;
  final String note;
}

class WatchCompanionProfile {
  const WatchCompanionProfile({
    required this.role,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.metrics,
    required this.reminders,
    required this.quickActions,
    required this.syncItems,
  });

  final String role;
  final String heroTitle;
  final String heroSubtitle;
  final List<WatchFeatureCardModel> metrics;
  final List<WatchReminderModel> reminders;
  final List<String> quickActions;
  final List<String> syncItems;
}

Map<String, WatchCompanionProfile> seedWatchProfiles() {
  return const {
    'coach': WatchCompanionProfile(
      role: 'coach',
      heroTitle: 'Coach wrist command',
      heroSubtitle:
          'Unread threads, next mat call, roster alerts, and quick staff replies without opening the full app.',
      metrics: [
        WatchFeatureCardModel(
          title: 'Unread messages',
          subtitle: 'parent-visible + staff',
          value: '6',
          note: 'Most urgent on practice and event days.',
          lane: 'Messaging',
        ),
        WatchFeatureCardModel(
          title: 'Tournament queue',
          subtitle: 'next event window',
          value: '2:15 PM',
          note: 'Bluegrass Spring Open weigh-in reminder.',
          lane: 'Tournament',
        ),
        WatchFeatureCardModel(
          title: 'Athlete alerts',
          subtitle: 'weight + approval flags',
          value: '4',
          note: 'Use wrist alerts for high-priority review only.',
          lane: 'Safety',
        ),
        WatchFeatureCardModel(
          title: 'Quick replies',
          subtitle: 'preset response pack',
          value: 'Live',
          note: 'Travel, check-in, arrival, and roster updates.',
          lane: 'Communication',
        ),
        WatchFeatureCardModel(
          title: 'Hydration nudges',
          subtitle: 'team-safe reminders',
          value: '3 today',
          note: 'Push water reminders before practice, weigh-ins, and long tournament blocks.',
          lane: 'Hydration',
        ),
      ],
      reminders: [
        WatchReminderModel(
          title: 'Weigh-in countdown',
          timeLabel: '11:30 AM',
          kind: 'Tournament',
          note: 'Nudge coaches before mat assignments go live.',
        ),
        WatchReminderModel(
          title: 'Water reminder',
          timeLabel: '1:15 PM',
          kind: 'Hydration',
          note: 'Prompt athletes and staff to drink water before the afternoon room session.',
        ),
        WatchReminderModel(
          title: 'Parent-visible follow-up',
          timeLabel: '3:45 PM',
          kind: 'Messaging',
          note: 'Reply to overnight family questions quickly.',
        ),
      ],
      quickActions: [
        'Reply with preset update',
        'Mark athlete as arrived',
        'Open bracket alert summary',
        'Send hydration reminder',
      ],
      syncItems: [
        'Push unread message counts to complications',
        'Sync tournament schedule changes instantly',
        'Mirror coach-safe alerts only',
      ],
    ),
    'athlete': WatchCompanionProfile(
      role: 'athlete',
      heroTitle: 'Athlete daily companion',
      heroSubtitle:
          'Heart rate, steps, hydration nudges, weigh-in countdowns, and quick glance training reminders.',
      metrics: [
        WatchFeatureCardModel(
          title: 'Heart rate',
          subtitle: 'live recovery lane',
          value: '128 bpm',
          note: 'Useful during practice blocks and cooldown.',
          lane: 'Health',
        ),
        WatchFeatureCardModel(
          title: 'Steps',
          subtitle: 'daily movement',
          value: '9,842',
          note: 'Track baseline workload and recovery days.',
          lane: 'Health',
        ),
        WatchFeatureCardModel(
          title: 'Next weigh-in',
          subtitle: 'countdown window',
          value: '18 hrs',
          note: 'Hydration reminders stay coach-safe and timed.',
          lane: 'Weight',
        ),
        WatchFeatureCardModel(
          title: 'Next event',
          subtitle: 'mat + report time',
          value: 'Sat 7:00 AM',
          note: 'Show tournament check-in and mat assignment updates.',
          lane: 'Tournament',
        ),
        WatchFeatureCardModel(
          title: 'Hydration',
          subtitle: 'daily water rhythm',
          value: '5 reminders',
          note: 'Simple drink-water prompts should support performance, not push unsafe cuts.',
          lane: 'Hydration',
        ),
      ],
      reminders: [
        WatchReminderModel(
          title: 'Hydration check',
          timeLabel: '1:00 PM',
          kind: 'Nutrition',
          note: 'Keep reminders simple and safe, never aggressive cut prompts.',
        ),
        WatchReminderModel(
          title: 'Practice check-in',
          timeLabel: '4:00 PM',
          kind: 'Practice',
          note: 'Tap once to mark arrival and open workout mode.',
        ),
        WatchReminderModel(
          title: 'Drink water',
          timeLabel: '6:30 PM',
          kind: 'Hydration',
          note: 'Keep post-practice recovery simple with a clear water reminder on the wrist.',
        ),
      ],
      quickActions: [
        'Log practice arrival',
        'Open weigh-in countdown',
        'View next tournament block',
        'Send coach quick reply',
        'Mark water reminder complete',
      ],
      syncItems: [
        'Read Apple Health heart-rate data',
        'Track steps and active minutes',
        'Mirror safe reminders from phone plan',
        'Sync hydration reminders from the nutrition lane',
      ],
    ),
    'parent': WatchCompanionProfile(
      role: 'parent',
      heroTitle: 'Parent glance view',
      heroSubtitle:
          'See key schedule reminders, arrival prompts, and clean program updates without opening long threads.',
      metrics: [
        WatchFeatureCardModel(
          title: 'Unread updates',
          subtitle: 'team + parent lane',
          value: '3',
          note: 'Announcements and parent-visible threads only.',
          lane: 'Messaging',
        ),
        WatchFeatureCardModel(
          title: 'Next event',
          subtitle: 'arrival + venue',
          value: 'Fri 6:30 PM',
          note: 'Wrist reminder for departure and check-in.',
          lane: 'Schedule',
        ),
        WatchFeatureCardModel(
          title: 'Athlete status',
          subtitle: 'shared summary',
          value: 'On track',
          note: 'No sensitive data, only approved visibility.',
          lane: 'Visibility',
        ),
        WatchFeatureCardModel(
          title: 'Quick confirm',
          subtitle: 'RSVP + arrival',
          value: 'Enabled',
          note: 'Parents can confirm event intent with one tap.',
          lane: 'Events',
        ),
        WatchFeatureCardModel(
          title: 'Hydration reminder',
          subtitle: 'family support',
          value: 'On',
          note: 'Parents can get coach-approved water reminders without seeing sensitive cut details.',
          lane: 'Hydration',
        ),
      ],
      reminders: [
        WatchReminderModel(
          title: 'Travel reminder',
          timeLabel: '5:30 PM',
          kind: 'Event',
          note: 'Show departure timing and destination notes.',
        ),
        WatchReminderModel(
          title: 'Parent update digest',
          timeLabel: '8:00 PM',
          kind: 'Messaging',
          note: 'Bundle coach-approved updates into one wrist summary.',
        ),
        WatchReminderModel(
          title: 'Water check',
          timeLabel: '2:00 PM',
          kind: 'Hydration',
          note: 'A simple prompt to help families support safe hydration habits on school and event days.',
        ),
      ],
      quickActions: [
        'Confirm arrival',
        'Open event note',
        'Read team update',
        'Reply with preset answer',
        'Send drink water reminder',
      ],
      syncItems: [
        'Mirror approved parent-visible threads only',
        'Push schedule changes to wrist notifications',
        'Keep athlete-sensitive data off the watch by default',
        'Allow coach-approved hydration prompts only',
      ],
    ),
  };
}

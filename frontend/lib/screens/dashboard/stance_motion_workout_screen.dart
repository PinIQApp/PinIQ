import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/workout_voice_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/subpage_header.dart';

class StanceMotionWorkoutScreen extends StatefulWidget {
  const StanceMotionWorkoutScreen({
    super.key,
    this.title = 'Stance + motion',
    this.subtitle = 'Pick a round length and react to random callouts.',
    this.startCue = 'Stance and motion',
    this.cues = const ['Shot', 'Sprawl', 'Down block', 'Sweep, circle, snap'],
    this.allowCueSelection = false,
    this.durationOptions = const [1, 2, 3],
    this.initialMinutes = 1,
    this.intervalOptions,
    this.initialCueIntervalSeconds,
    this.intervalLabel = 'Time between callouts',
    this.cueListLabel = 'Callouts',
  });

  final String title;
  final String subtitle;
  final String startCue;
  final List<String> cues;
  final bool allowCueSelection;
  final List<int> durationOptions;
  final int initialMinutes;
  final List<int>? intervalOptions;
  final int? initialCueIntervalSeconds;
  final String intervalLabel;
  final String cueListLabel;

  @override
  State<StanceMotionWorkoutScreen> createState() =>
      _StanceMotionWorkoutScreenState();
}

class _StanceMotionWorkoutScreenState extends State<StanceMotionWorkoutScreen> {
  final _random = Random();
  Timer? _timer;
  late int _selectedMinutes;
  late int _remainingSeconds;
  late int? _selectedCueIntervalSeconds;
  late Set<String> _selectedCues;
  int _nextCueSeconds = 3;
  bool _isRunning = false;
  String _currentCue = 'Ready';
  String? _lastCue;

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.initialMinutes;
    _remainingSeconds = _selectedMinutes * 60;
    _selectedCueIntervalSeconds = widget.initialCueIntervalSeconds;
    _selectedCues = widget.cues.toSet();
  }

  @override
  void dispose() {
    _timer?.cancel();
    stopWorkoutCue();
    super.dispose();
  }

  void _selectMinutes(int minutes) {
    if (_isRunning) return;
    setState(() {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _currentCue = 'Ready';
      _lastCue = null;
    });
  }

  void _selectCueInterval(int seconds) {
    if (_isRunning) return;
    setState(() => _selectedCueIntervalSeconds = seconds);
  }

  void _toggleCue(String cue) {
    if (_isRunning) return;
    setState(() {
      if (_selectedCues.contains(cue)) {
        _selectedCues.remove(cue);
      } else {
        _selectedCues.add(cue);
      }
      _lastCue = null;
    });
  }

  void _startWorkout() {
    if (_activeCues.isEmpty) return;
    _timer?.cancel();
    stopWorkoutCue();
    setState(() {
      _remainingSeconds = _selectedMinutes * 60;
      _nextCueSeconds = 2;
      _isRunning = true;
      _currentCue = widget.startCue;
      _lastCue = null;
    });
    speakWorkoutCue(widget.startCue);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _pauseWorkout() {
    _timer?.cancel();
    stopWorkoutCue();
    setState(() => _isRunning = false);
  }

  void _resetWorkout() {
    _timer?.cancel();
    stopWorkoutCue();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedMinutes * 60;
      _nextCueSeconds = 3;
      _currentCue = 'Ready';
      _lastCue = null;
    });
  }

  void _tick() {
    if (!mounted) return;
    if (_remainingSeconds <= 1) {
      _timer?.cancel();
      stopWorkoutCue();
      setState(() {
        _isRunning = false;
        _remainingSeconds = 0;
        _currentCue = 'Done';
      });
      speakWorkoutCue('Done');
      return;
    }

    setState(() {
      _remainingSeconds -= 1;
      _nextCueSeconds -= 1;
      if (_nextCueSeconds <= 0) {
        _currentCue = _nextCue();
        _lastCue = _currentCue;
        _nextCueSeconds = _selectedCueIntervalSeconds ?? 3 + _random.nextInt(4);
        speakWorkoutCue(_currentCue);
      }
    });
  }

  String _nextCue() {
    final cues = _activeCues;
    final available =
        cues.where((cue) => cue != _lastCue).toList(growable: false);
    if (available.isEmpty) return cues.first;
    return available[_random.nextInt(available.length)];
  }

  List<String> get _activeCues => widget.allowCueSelection
      ? widget.cues.where(_selectedCues.contains).toList(growable: false)
      : widget.cues;

  String get _timeLabel {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            SubpageHeader(
              title: widget.title,
              subtitle: widget.subtitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            _WorkoutPanel(
              currentCue: _currentCue,
              timeLabel: _timeLabel,
              isRunning: _isRunning,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Round length', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final minutes in widget.durationOptions)
                  SizedBox(
                    width: 108,
                    child: _DurationButton(
                      minutes: minutes,
                      selected: _selectedMinutes == minutes,
                      enabled: !_isRunning,
                      onTap: () => _selectMinutes(minutes),
                    ),
                  ),
              ],
            ),
            if (widget.intervalOptions != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(widget.intervalLabel, style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final seconds in widget.intervalOptions!)
                    _IntervalButton(
                      seconds: seconds,
                      selected: _selectedCueIntervalSeconds == seconds,
                      enabled: !_isRunning,
                      onTap: () => _selectCueInterval(seconds),
                    ),
                ],
              ),
            ],
            if (widget.allowCueSelection) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(widget.cueListLabel, style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppSpacing.md),
              _CueSelector(
                cues: widget.cues,
                selectedCues: _selectedCues,
                enabled: !_isRunning,
                onToggle: _toggleCue,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (_isRunning)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pauseWorkout,
                      icon: const Icon(Icons.pause_rounded),
                      label: const Text('Pause'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetWorkout,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Reset'),
                    ),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _activeCues.isEmpty ? null : _startWorkout,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  _remainingSeconds == 0 ? 'Run it again' : 'Start workout',
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            _CueList(cues: _activeCues),
          ],
        ),
      ),
    );
  }
}

class _WorkoutPanel extends StatelessWidget {
  const _WorkoutPanel({
    required this.currentCue,
    required this.timeLabel,
    required this.isRunning,
  });

  final String currentCue;
  final String timeLabel;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF14243A),
            Color(0xFF0A141F),
            Color(0xFF122B22),
          ],
          stops: [0, 0.58, 1],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.68)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: (isRunning ? AppColors.success : AppColors.textMuted)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
            ),
            child: Text(
              isRunning ? 'Live round' : 'Waiting',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              currentCue,
              key: ValueKey(currentCue),
              textAlign: TextAlign.center,
              style: AppTextStyles.pageTitle.copyWith(
                color: currentCue == 'Done' ? AppColors.success : accent,
                fontSize: 44,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            timeLabel,
            style: AppTextStyles.statNumber.copyWith(fontSize: 54),
          ),
        ],
      ),
    );
  }
}

class _IntervalButton extends StatelessWidget {
  const _IntervalButton({
    required this.seconds,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final int seconds;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      label: Text('${seconds}s'),
      selected: selected,
      onSelected: enabled ? (_) => onTap() : null,
      selectedColor: accent.withValues(alpha: 0.18),
    );
  }
}

class _CueSelector extends StatelessWidget {
  const _CueSelector({
    required this.cues,
    required this.selectedCues,
    required this.enabled,
    required this.onToggle,
  });

  final List<String> cues;
  final Set<String> selectedCues;
  final bool enabled;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final cue in cues)
          FilterChip(
            label: Text(cue),
            selected: selectedCues.contains(cue),
            onSelected: enabled ? (_) => onToggle(cue) : null,
          ),
      ],
    );
  }
}

class _DurationButton extends StatelessWidget {
  const _DurationButton({
    required this.minutes,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final int minutes;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onTap : null,
      child: Ink(
        height: 72,
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.18)
              : AppColors.surface.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.62)
                : AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Center(
          child: Text(
            '$minutes min',
            style: AppTextStyles.cardTitle.copyWith(
              color: enabled ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _CueList extends StatelessWidget {
  const _CueList({required this.cues});

  final List<String> cues;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final cue in cues)
          Chip(
            avatar: const Icon(Icons.bolt_rounded, size: 16),
            label: Text(cue),
          ),
      ],
    );
  }
}

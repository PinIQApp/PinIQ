import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/ai_replay_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';

class AiReplayAnalysisScreen extends StatefulWidget {
  const AiReplayAnalysisScreen({super.key});

  @override
  State<AiReplayAnalysisScreen> createState() => _AiReplayAnalysisScreenState();
}

class _AiReplayAnalysisScreenState extends State<AiReplayAnalysisScreen> {
  final _athleteController = TextEditingController();
  final _opponentController = TextEditingController();
  final _eventController = TextEditingController();
  final _weightClassController = TextEditingController();
  final _filmSourceController = TextEditingController();
  final _focusController = TextEditingController();
  final _coachSummaryController = TextEditingController();
  final _athletePlanController = TextEditingController();
  final _parentSummaryController = TextEditingController();
  final _clipTimeController = TextEditingController();
  final _clipLabelController = TextEditingController();
  final _clipNoteController = TextEditingController();
  final ImagePicker _filmPicker = ImagePicker();

  XFile? _pickedFilm;
  String _clipLane = 'Neutral control';
  bool _isAnalyzing = false;
  String? _loadedReviewId;
  List<AiReplayFilmFindingModel> _latestFilmFindings = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.watch<AppState>();
    final review = appState.selectedReplayReview;
    if (review != null && review.id != _loadedReviewId) {
      _loadedReviewId = review.id;
      _loadReview(review);
    }
  }

  @override
  void dispose() {
    _athleteController.dispose();
    _opponentController.dispose();
    _eventController.dispose();
    _weightClassController.dispose();
    _filmSourceController.dispose();
    _focusController.dispose();
    _coachSummaryController.dispose();
    _athletePlanController.dispose();
    _parentSummaryController.dispose();
    _clipTimeController.dispose();
    _clipLabelController.dispose();
    _clipNoteController.dispose();
    super.dispose();
  }

  void _loadReview(AiReplayReviewModel review) {
    _athleteController.text = review.athleteName;
    _opponentController.text = review.opponentName;
    _eventController.text = review.eventLabel;
    _weightClassController.text = review.weightClass;
    _filmSourceController.text = review.filmSource;
    _focusController.text = review.focus;
    _coachSummaryController.text = review.coachSummary;
    _athletePlanController.text = review.athleteActionPlan;
    _parentSummaryController.text = review.parentSummary;
    _pickedFilm = null;
    _latestFilmFindings = const [];
  }

  AiReplayReviewModel _buildUpdatedReview(AiReplayReviewModel base,
      {List<AiReplayClipModel>? clips}) {
    return base.copyWith(
      title:
          'Review vs. ${_opponentController.text.trim().isEmpty ? 'Opponent' : _opponentController.text.trim()}',
      eventLabel: _eventController.text.trim(),
      athleteName: _athleteController.text.trim(),
      opponentName: _opponentController.text.trim(),
      weightClass: _weightClassController.text.trim(),
      filmSource: _filmSourceController.text.trim(),
      focus: _focusController.text.trim(),
      coachSummary: _coachSummaryController.text.trim(),
      athleteActionPlan: _athletePlanController.text.trim(),
      parentSummary: _parentSummaryController.text.trim(),
      clips: clips,
      updatedAtLabel: 'Updated just now',
    );
  }

  void _saveReview() {
    final appState = context.read<AppState>();
    final selected = appState.selectedReplayReview;
    if (selected == null) return;
    appState
        .saveReplayReview(_buildUpdatedReview(selected, clips: selected.clips));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Replay review saved.')),
    );
  }

  Future<void> _attachFilm() async {
    final appState = context.read<AppState>();
    final selected = appState.selectedReplayReview;
    if (selected == null) return;
    final picked = await _filmPicker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    if (!mounted) return;
    _pickedFilm = picked;
    _filmSourceController.text =
        picked.name.isNotEmpty ? picked.name : picked.path.split('/').last;
    appState
        .saveReplayReview(_buildUpdatedReview(selected, clips: selected.clips));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Film added. Run AI film study next.')),
    );
  }

  Future<void> _runFilmStudy() async {
    final appState = context.read<AppState>();
    final selected = appState.selectedReplayReview;
    if (selected == null) return;
    if (_filmSourceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add match film before running study.')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);
    if (_pickedFilm != null && appState.token != null) {
      try {
        final study = await appState.api.analyzeReplayFilm(
          token: appState.token!,
          fileName: _pickedFilm!.name.isNotEmpty
              ? _pickedFilm!.name
              : _filmSourceController.text.trim(),
          bytes: await _pickedFilm!.readAsBytes(),
        );
        if (!mounted) return;

        final clips = study.findings
            .map(
              (finding) => AiReplayClipModel(
                id: 'ai-${DateTime.now().microsecondsSinceEpoch}-${finding.title.hashCode}',
                timecode: finding.timecode ?? 'AI finding',
                label: finding.title,
                note:
                    'Right: ${finding.right} Wrong: ${finding.wrong} Fix: ${finding.fix}',
                lane: 'AI film study',
              ),
            )
            .toList();

        _focusController.text = study.findings.isEmpty
            ? 'Coach-reviewed film study'
            : study.findings.first.title;
        _coachSummaryController.text = study.coachSummary;
        _athletePlanController.text = study.athleteActionPlan;
        _parentSummaryController.text = study.parentSummary;
        _latestFilmFindings = study.findings;

        appState.saveReplayReview(_buildUpdatedReview(
          selected,
          clips: clips,
        ));
        setState(() => _isAnalyzing = false);

        final modeLabel = study.analysisMode == 'openai_vision'
            ? 'AI vision study generated.'
            : 'Beta film study generated. Add OpenAI key for frame-level vision.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(modeLabel)),
        );
        return;
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    final clips = selected.clips.isEmpty
        ? _seedFilmStudyClips()
        : [
            ...selected.clips,
            AiReplayClipModel(
              id: 'study-${DateTime.now().millisecondsSinceEpoch}',
              timecode: 'Coach review',
              label: 'Pattern found',
              note:
                  'The same habit shows up across the marked clips. Fix this before adding more offense.',
              lane: _clipLane,
            ),
          ];

    final findings = _filmStudyFindings(clips);
    _latestFilmFindings = const [];
    _focusController.text = findings.first.title;
    _coachSummaryController.text =
        '${_athleteLabel(selected)} needs the most work on ${findings.first.title.toLowerCase()}. ${findings.first.problem}';
    _athletePlanController.text = findings
        .map((finding) => '${finding.fix} Drill: ${finding.drill}')
        .join('\n');
    _parentSummaryController.text =
        '${_athleteLabel(selected)} has clear coachable habits on film. The next practices will focus on ${findings.take(2).map((item) => item.title.toLowerCase()).join(' and ')}.';

    appState.saveReplayReview(_buildUpdatedReview(
      selected,
      clips: clips,
    ));
    setState(() => _isAnalyzing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI film study generated.')),
    );
  }

  String _athleteLabel(AiReplayReviewModel selected) {
    return _athleteController.text.trim().isEmpty
        ? selected.athleteName
        : _athleteController.text.trim();
  }

  List<AiReplayClipModel> _seedFilmStudyClips() {
    return [
      AiReplayClipModel(
        id: 'auto-clip-entry-${DateTime.now().millisecondsSinceEpoch}',
        timecode: '0:42',
        label: 'Entry without angle',
        note:
            'Shot starts from too far away and the athlete reaches before moving the feet.',
        lane: 'Neutral control',
      ),
      AiReplayClipModel(
        id: 'auto-clip-finish-${DateTime.now().millisecondsSinceEpoch}',
        timecode: '2:16',
        label: 'Finish stalls',
        note:
            'Head and hips stop moving after contact, which lets the opponent square up.',
        lane: 'Finishes + conversions',
      ),
      AiReplayClipModel(
        id: 'auto-clip-pace-${DateTime.now().millisecondsSinceEpoch}',
        timecode: '5:08',
        label: 'Late-period drift',
        note:
            'Hands drop and stance rises late in the period, giving away easy pressure.',
        lane: 'Defense + pace',
      ),
    ];
  }

  void _addClip() {
    final appState = context.read<AppState>();
    final selected = appState.selectedReplayReview;
    if (selected == null) return;
    final timecode = _clipTimeController.text.trim();
    final label = _clipLabelController.text.trim();
    final note = _clipNoteController.text.trim();
    if (timecode.isEmpty || label.isEmpty || note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add a time, label, and note before saving a clip.')),
      );
      return;
    }

    final clip = AiReplayClipModel(
      id: 'clip-${DateTime.now().millisecondsSinceEpoch}',
      timecode: timecode,
      label: label,
      note: note,
      lane: _clipLane,
    );

    appState.saveReplayReview(
      _buildUpdatedReview(
        selected,
        clips: [clip, ...selected.clips],
      ),
    );

    _clipTimeController.clear();
    _clipLabelController.clear();
    _clipNoteController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Clip marker added to replay review.')),
    );
  }

  void _generateCoachSafeOutput() {
    final appState = context.read<AppState>();
    final selected = appState.selectedReplayReview;
    if (selected == null) return;

    final athlete = _athleteController.text.trim().isEmpty
        ? selected.athleteName
        : _athleteController.text.trim();
    final opponent = _opponentController.text.trim().isEmpty
        ? selected.opponentName
        : _opponentController.text.trim();
    final focus = _focusController.text.trim();

    final clipCount = selected.clips.length;
    _coachSummaryController.text =
        '$athlete had repeatable scoring chances against $opponent. Based on $clipCount marked clip${clipCount == 1 ? '' : 's'}, the next coaching priority is ${focus.isEmpty ? 'one clean setup, one clean finish, and better end-of-period discipline' : focus}.';
    _athletePlanController.text =
        'Watch the best clip twice, drill the corrected sequence for 20 quality reps, then finish practice with one live go focused only on that situation.';
    _parentSummaryController.text =
        '$athlete showed strong effort and clear scoring potential. Coaches are focusing on one specific technical habit before the next competition.';

    appState
        .saveReplayReview(_buildUpdatedReview(selected, clips: selected.clips));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final review = appState.selectedReplayReview;
    final reviews = appState.replayReviews;
    final isWide = MediaQuery.of(context).size.width >= 1120;

    if (review == null) {
      return const Center(child: Text('No replay reviews yet.'));
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SubpageHeader(
          title: 'AI Replay Analysis',
          subtitle:
              'Beta film study: mark clips, organize coaching notes, and generate coach-reviewed action plans.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReplayBetaNotice(clipCount: review.clips.length),
        const SizedBox(height: AppSpacing.lg),
        _ReplaySummaryRow(
            reviewCount: reviews.length, clipCount: review.clips.length),
        const SizedBox(height: AppSpacing.xl),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _buildWorkspace(review)),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                  flex: 3,
                  child: _ReviewQueuePanel(
                    reviews: reviews,
                    selectedId: review.id,
                    onSelected: (value) =>
                        context.read<AppState>().selectReplayReview(value),
                  )),
            ],
          )
        else ...[
          _buildWorkspace(review),
          const SizedBox(height: AppSpacing.lg),
          _ReviewQueuePanel(
            reviews: reviews,
            selectedId: review.id,
            onSelected: (value) =>
                context.read<AppState>().selectReplayReview(value),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildWorkspace(AiReplayReviewModel review) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Replay lab',
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
                  ),
                  OutlinedButton.icon(
                    onPressed: _attachFilm,
                    icon: const Icon(Icons.video_call_rounded),
                    label: const Text('Add film'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _isAnalyzing ? null : _runFilmStudy,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.psychology_alt_rounded),
                    label: Text(_isAnalyzing ? 'Studying...' : 'Run study'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: _saveReview,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save review'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Turn match film into saved coach reviews, athlete corrections, and parent-safe recaps. During beta, the coach marks the clips and approves every output.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: AppColors.brandedGradient(
                    primary: const Color(0xFF2563EB),
                    secondary: AppColors.surfaceElevated,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReplayPill(label: review.eventLabel),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      review.title,
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${review.athleteName} • ${review.weightClass} • ${review.updatedAtLabel}',
                      style: AppTextStyles.bodyStrong
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_circle_fill_rounded,
                            size: 72,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(review.filmSource,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Film upload parser coming after beta feedback',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _FilmMistakePanel(
                findings: _latestFilmFindings.isEmpty
                    ? _filmStudyFindings(review.clips)
                    : _filmFindingsFromAi(_latestFilmFindings),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Match setup'),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _ReplayField(
                      label: 'Athlete',
                      width: 240,
                      child: TextField(controller: _athleteController)),
                  _ReplayField(
                      label: 'Opponent',
                      width: 240,
                      child: TextField(controller: _opponentController)),
                  _ReplayField(
                      label: 'Event',
                      width: 260,
                      child: TextField(controller: _eventController)),
                  _ReplayField(
                      label: 'Weight class',
                      width: 180,
                      child: TextField(controller: _weightClassController)),
                  _ReplayField(
                      label: 'Film source',
                      width: 340,
                      child: TextField(controller: _filmSourceController)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _ReplayField(
                label: 'Primary coaching focus',
                child: TextField(
                  controller: _focusController,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Clip markers', style: AppTextStyles.cardTitle),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _addClip,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add clip'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Mark the exact moments the assistant should use for breakdown and follow-up notes.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _ReplayField(
                      label: 'Time',
                      width: 120,
                      child: TextField(controller: _clipTimeController)),
                  _ReplayField(
                      label: 'Label',
                      width: 220,
                      child: TextField(controller: _clipLabelController)),
                  _ReplayField(
                    label: 'Lane',
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: _clipLane,
                      items: const [
                        DropdownMenuItem(
                            value: 'Neutral control',
                            child: Text('Neutral control')),
                        DropdownMenuItem(
                            value: 'Finishes + conversions',
                            child: Text('Finishes + conversions')),
                        DropdownMenuItem(
                            value: 'Defense + pace',
                            child: Text('Defense + pace')),
                        DropdownMenuItem(
                            value: 'Mat returns + top ride',
                            child: Text('Mat returns + top ride')),
                        DropdownMenuItem(
                            value: 'Bottom escape',
                            child: Text('Bottom escape')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _clipLane = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ReplayField(
                label: 'Clip note',
                child: TextField(
                  controller: _clipNoteController,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...review.clips.map(
                (clip) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ReplayClipCard(clip: clip),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Coach output', style: AppTextStyles.cardTitle),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _generateCoachSafeOutput,
                    icon: const Icon(Icons.auto_fix_high_rounded),
                    label: const Text('Generate first pass'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Keep the review tight: one coach summary, one athlete action plan, and one parent-safe recap.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.md),
              _ReplayField(
                label: 'Coach summary',
                child: TextField(
                  controller: _coachSummaryController,
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ReplayField(
                label: 'Athlete action plan',
                child: TextField(
                  controller: _athletePlanController,
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ReplayField(
                label: 'Parent-safe summary',
                child: TextField(
                  controller: _parentSummaryController,
                  maxLines: 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReplaySummaryRow extends StatelessWidget {
  const _ReplaySummaryRow({
    required this.reviewCount,
    required this.clipCount,
  });

  final int reviewCount;
  final int clipCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _MetricCard(
            label: 'Saved reviews',
            value: '$reviewCount',
            note: 'coach replay files',
            color: const Color(0xFF38BDF8)),
        _MetricCard(
            label: 'Clip markers',
            value: '$clipCount',
            note: 'on selected review',
            color: const Color(0xFFF59E0B)),
        const _MetricCard(
            label: 'Parent-safe',
            value: 'Ready',
            note: 'clean recap lane',
            color: Color(0xFF10B981)),
        const _MetricCard(
            label: 'Mode',
            value: 'Beta',
            note: 'coach-marked clips',
            color: Color(0xFF6366F1)),
      ],
    );
  }
}

class _FilmFinding {
  const _FilmFinding({
    required this.title,
    required this.right,
    required this.problem,
    required this.fix,
    required this.drill,
    required this.color,
  });

  final String title;
  final String right;
  final String problem;
  final String fix;
  final String drill;
  final Color color;
}

List<_FilmFinding> _filmFindingsFromAi(
    List<AiReplayFilmFindingModel> findings) {
  return findings
      .map(
        (finding) => _FilmFinding(
          title: finding.title,
          right: finding.right,
          problem: finding.wrong,
          fix: finding.fix,
          drill: finding.drill,
          color: finding.confidence >= 0.7
              ? const Color(0xFF14B8A6)
              : const Color(0xFFF59E0B),
        ),
      )
      .take(6)
      .toList();
}

List<_FilmFinding> _filmStudyFindings(List<AiReplayClipModel> clips) {
  final text = clips
      .map((clip) => '${clip.lane} ${clip.label} ${clip.note}')
      .join(' ')
      .toLowerCase();

  final findings = <_FilmFinding>[];
  if (text.contains('entry') ||
      text.contains('neutral') ||
      text.contains('shot') ||
      text.contains('single')) {
    findings.add(
      const _FilmFinding(
        title: 'Attacking from too far away',
        right:
            'The athlete is willing to initiate offense and create scoring chances.',
        problem:
            'The first shot is happening before the feet and hands create a clean angle.',
        fix:
            'Move the opponent first, close distance, then attack with the head and trail leg moving through.',
        drill: 'Motion to fake to single, 5 sets of 5 clean entries each side.',
        color: Color(0xFF38BDF8),
      ),
    );
  }
  if (text.contains('finish') ||
      text.contains('conversion') ||
      text.contains('hips') ||
      text.contains('square')) {
    findings.add(
      const _FilmFinding(
        title: 'Stopping after contact',
        right:
            'The athlete can get to the leg and start a real scoring sequence.',
        problem:
            'The attack gets to a leg, then the hips stop and the opponent has time to square up.',
        fix:
            'Pick one immediate finish and commit before the opponent settles hips.',
        drill:
            'Single-leg shelf, cut-corner, and run-the-pipe chain, 12 reps each.',
        color: Color(0xFFF59E0B),
      ),
    );
  }
  if (text.contains('pace') ||
      text.contains('late') ||
      text.contains('period') ||
      text.contains('defense')) {
    findings.add(
      const _FilmFinding(
        title: 'Stance fading late',
        right: 'The athlete keeps wrestling into the later exchanges.',
        problem:
            'The athlete gets taller and slower late, which makes defense reactive instead of ready.',
        fix:
            'Reset stance after every exchange and win the next hand touch before backing up.',
        drill:
            '30-second stance-motion go, sprawl on call, shot on call, 6 rounds.',
        color: Color(0xFF14B8A6),
      ),
    );
  }
  if (text.contains('top') ||
      text.contains('ride') ||
      text.contains('mat return')) {
    findings.add(
      const _FilmFinding(
        title: 'Loose top pressure',
        right:
            'The athlete is staying engaged from top and looking for control.',
        problem:
            'Top control is not staying connected through the hips, so returns and rides get extended.',
        fix:
            'Keep chest pressure connected and return before the opponent builds full height.',
        drill:
            'Mat return chain from tripod, 10 clean returns then 20-second ride.',
        color: Color(0xFF8B5CF6),
      ),
    );
  }
  if (text.contains('bottom') || text.contains('escape')) {
    findings.add(
      const _FilmFinding(
        title: 'Slow first move on bottom',
        right:
            'The athlete is identifying bottom as a position that can be improved quickly.',
        problem:
            'The first move is delayed, which lets the top wrestler settle pressure.',
        fix:
            'Explode on the whistle, clear wrist control, and get hips away immediately.',
        drill:
            'Whistle stand-up to hand control, 15 reps with a partner return.',
        color: Color(0xFFEF4444),
      ),
    );
  }

  if (findings.isEmpty) {
    findings.addAll(
      const [
        _FilmFinding(
          title: 'Needs clip markers',
          right: 'The film is attached and ready to organize.',
          problem:
              'The film is attached, but the assistant needs clips or coach notes to find the strongest patterns.',
          fix:
              'Add 2-3 timecoded moments where points were scored, missed, or given up.',
          drill:
              'Mark one neutral clip, one defense clip, and one late-match clip.',
          color: Color(0xFF6366F1),
        ),
      ],
    );
  }

  return findings.take(4).toList();
}

class _FilmMistakePanel extends StatelessWidget {
  const _FilmMistakePanel({required this.findings});

  final List<_FilmFinding> findings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.report_problem_outlined,
                  color: Color(0xFFF59E0B)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'What the film says to fix',
                  style: AppTextStyles.cardTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The study turns uploaded film and marked clips into direct corrections the athlete can drill.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final finding in findings) ...[
            _FilmFindingCard(finding: finding),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _FilmFindingCard extends StatelessWidget {
  const _FilmFindingCard({required this.finding});

  final _FilmFinding finding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: finding.color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            finding.title,
            style: AppTextStyles.bodyStrong.copyWith(color: finding.color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Right: ${finding.right}', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.xs),
          Text('Wrong: ${finding.problem}', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.xs),
          Text('Fix: ${finding.fix}', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Drill: ${finding.drill}',
            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ReplayBetaNotice extends StatelessWidget {
  const _ReplayBetaNotice({required this.clipCount});

  final int clipCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: Color(0xFF8B5CF6)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coach-reviewed beta workflow',
                    style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'AI Replay is a structured film-study assistant right now. Coaches mark the important moments, generate a first pass, then edit before sharing.',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _ReplayPill(label: '$clipCount clips marked'),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.note,
    required this.color,
  });

  final String label;
  final String value;
  final String note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: AppTextStyles.cardTitle.copyWith(color: color)),
            const SizedBox(height: AppSpacing.xxs),
            Text(note, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _ReviewQueuePanel extends StatelessWidget {
  const _ReviewQueuePanel({
    required this.reviews,
    required this.selectedId,
    required this.onSelected,
  });

  final List<AiReplayReviewModel> reviews;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review queue', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Jump between saved match reviews instead of rebuilding film notes from scratch.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...reviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onSelected(review.id),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: review.id == selectedId
                        ? AppColors.surfaceElevated
                        : AppColors.surface.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: review.id == selectedId
                          ? const Color(0xFF2563EB).withValues(alpha: 0.4)
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              review.athleteName,
                              style: AppTextStyles.bodyStrong,
                            ),
                          ),
                          _ReplayPill(label: review.status),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${review.eventLabel} • ${review.weightClass}',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        review.focus,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayField extends StatelessWidget {
  const _ReplayField({
    required this.label,
    required this.child,
    this.width,
  });

  final String label;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _ReplayClipCard extends StatelessWidget {
  const _ReplayClipCard({required this.clip});

  final AiReplayClipModel clip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ReplayPill(label: clip.timecode),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: Text(clip.label, style: AppTextStyles.bodyStrong)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(clip.lane, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xxs),
          Text(clip.note,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ReplayPill extends StatelessWidget {
  const _ReplayPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../application/challenge_service.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/strings/challenge_strings.dart';
import '../../../core/theme/level_colors.dart';
import '../../../domain/entities/challenge.dart';
import '../../../domain/enums.dart';
import '../../../domain/rules/challenge_rules.dart';
import '../../../domain/rules/vn_calendar.dart';
import '../../utils/formatters.dart';

/// Thẻ thử thách tuần (+ lịch sử & streak nếu [showHistory]).
/// Dùng ở Trang chủ (không lịch sử) và Báo cáo (có lịch sử).
class ChallengeSection extends StatefulWidget {
  const ChallengeSection({super.key, this.showHistory = false});

  final bool showHistory;

  @override
  State<ChallengeSection> createState() => _ChallengeSectionState();
}

class _ChallengeSectionState extends State<ChallengeSection> {
  final _service = sl<ChallengeService>();
  late final Stream<ChallengeViewState> _stream = _service.watchState();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChallengeViewState>(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
        }
        final state = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCard(context, state),
            if (widget.showHistory) ...[
              const SizedBox(height: 16),
              _HistoryCard(state: state),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, ChallengeViewState state) {
    final current = state.current;
    if (current == null) {
      return _ProposalCard(
        proposal: state.proposal,
        onAccept: (target) => _service.accept(
          state.proposal,
          target: target,
          currentProgress: ChallengeRules.progressFor(state.proposal.type, state.currentStats),
        ),
        onSkip: () => _service.skip(state.proposal),
      );
    }
    if (current.status == ChallengeStatus.cancelled) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: const Text(ChallengeStrings.skippedThisWeek),
          trailing: TextButton(
            onPressed: () => _service.accept(
              ChallengeProposal(current.type, current.target),
              currentProgress: ChallengeRules.progressFor(current.type, state.currentStats),
            ),
            child: const Text(ChallengeStrings.takeAgain),
          ),
        ),
      );
    }
    return _ActiveCard(
      challenge: current,
      progress: state.liveProgress,
      streak: state.streak,
      onEditTarget: () async {
        final target = await showTargetDialog(context, current.type, current.target);
        if (target != null) _service.updateTarget(current, target);
      },
    );
  }
}

/// Hộp thoại chỉnh mục tiêu (con số) của thử thách.
Future<int?> showTargetDialog(BuildContext context, ChallengeType type, int initial) {
  var value = initial;
  final min = type.isMaxType ? 0 : 1;
  return showDialog<int>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text(ChallengeStrings.editTarget),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ChallengeStrings.title(type, value), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(
                  onPressed: value > min ? () => setState(() => value--) : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 56,
                  child: Text('$value',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
                IconButton.outlined(
                  onPressed: value < 21 ? () => setState(() => value++) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, value),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    ),
  );
}

class _ProposalCard extends StatefulWidget {
  const _ProposalCard({required this.proposal, required this.onAccept, required this.onSkip});

  final ChallengeProposal proposal;
  final ValueChanged<int> onAccept;
  final VoidCallback onSkip;

  @override
  State<_ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends State<_ProposalCard> {
  late int _target = widget.proposal.target;

  @override
  void didUpdateWidget(covariant _ProposalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proposal != widget.proposal) _target = widget.proposal.target;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = widget.proposal.type;
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(ChallengeStrings.newChallenge, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(ChallengeStrings.newChallengeHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Text(
              ChallengeStrings.title(type, _target),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final target = await showTargetDialog(context, type, _target);
                    if (target != null) setState(() => _target = target);
                  },
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text(ChallengeStrings.editTarget),
                ),
                const Spacer(),
                TextButton(onPressed: widget.onSkip, child: const Text(ChallengeStrings.skip)),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: () => widget.onAccept(_target),
                  child: const Text(ChallengeStrings.accept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({
    required this.challenge,
    required this.progress,
    required this.streak,
    required this.onEditTarget,
  });

  final Challenge challenge;
  final int progress;
  final int streak;
  final VoidCallback onEditTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = challenge.type;
    final target = challenge.target;
    final onTrack = ChallengeRules.isOnTrack(type, target, progress);
    final ratio = target == 0 ? (progress == 0 ? 0.0 : 1.0) : (progress / target).clamp(0.0, 1.0);
    // Loại "tối đa" vượt mục tiêu -> màu cam (không dùng đỏ).
    final caution = type.isMaxType && !onTrack;
    final barColor = caution
        ? LevelColors.colorsOf(LevelTone.caution, theme.brightness).foreground
        : theme.colorScheme.primary;
    final message = type.isMaxType
        ? (onTrack ? ChallengeStrings.onTrackMax : ChallengeStrings.overMax)
        : (onTrack ? ChallengeStrings.reachedMin : ChallengeStrings.keepGoingMin);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(ChallengeStrings.weeklyChallenge, style: theme.textTheme.titleSmall),
                ),
                if (streak > 0)
                  Chip(
                    avatar: const Icon(Icons.local_fire_department, size: 18),
                    label: Text(ChallengeStrings.streak(streak)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ChallengeStrings.title(type, target),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                color: barColor,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${ChallengeStrings.progress(type, progress, target)} • $message',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (challenge.status == ChallengeStatus.active)
                  IconButton(
                    tooltip: ChallengeStrings.editTarget,
                    icon: const Icon(Icons.tune, size: 20),
                    onPressed: onEditTarget,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.state});

  final ChallengeViewState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ChallengeStrings.history, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.local_fire_department, size: 18, color: theme.colorScheme.secondary),
                const SizedBox(width: 6),
                Expanded(child: Text(ChallengeStrings.streakHeadline(state.streak))),
              ],
            ),
            const Divider(height: 24),
            if (state.history.isEmpty)
              Text(ChallengeStrings.noHistory, style: theme.textTheme.bodySmall)
            else
              for (final c in state.history.take(8)) _HistoryRow(challenge: c),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = VnCalendar.parseDateKey(challenge.weekStart);
    final end = start.add(const Duration(days: 6));
    final tone = switch (challenge.status) {
      ChallengeStatus.completed => LevelTone.good,
      ChallengeStatus.failed => LevelTone.neutral,
      _ => null,
    };
    final colors = tone == null ? null : LevelColors.colorsOf(tone, theme.brightness);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ChallengeStrings.title(challenge.type, challenge.target)),
                Text(
                  '${Formatters.shortDate(start)} – ${Formatters.shortDate(end)} • '
                  '${ChallengeStrings.progress(challenge.type, challenge.progress, challenge.target)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors?.background ?? theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              ChallengeStrings.status(challenge.status),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors?.foreground ?? theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

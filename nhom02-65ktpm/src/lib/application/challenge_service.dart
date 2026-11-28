import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/entities/challenge.dart';
import '../domain/enums.dart';
import '../domain/repositories/challenge_repository.dart';
import '../domain/repositories/meal_repository.dart';
import '../domain/rules/challenge_rules.dart';
import '../domain/rules/vn_calendar.dart';
import '../domain/rules/weekly_stats.dart';
import 'build_weekly_report.dart';
import 'session_service.dart';

/// Trạng thái hiển thị thẻ thử thách (Trang chủ, Báo cáo).
class ChallengeViewState {
  const ChallengeViewState({
    required this.weekKey,
    required this.current,
    required this.liveProgress,
    required this.proposal,
    required this.streak,
    required this.history,
    required this.currentStats,
  });

  final String weekKey;

  /// Thử thách của tuần này (null = chưa có -> hiện đề xuất).
  final Challenge? current;

  /// Tiến độ tính trực tiếp từ nhật ký (realtime, kể cả từ thiết bị khác).
  final int liveProgress;

  /// Đề xuất cho tuần này (dựa trên tuần trước nếu đủ dữ liệu).
  final ChallengeProposal proposal;
  final int streak;

  /// Các thử thách của những tuần trước, mới nhất trước.
  final List<Challenge> history;

  /// Thống kê tuần này (để tính tiến độ ban đầu khi nhận thử thách).
  final WeeklyStats currentStats;
}

/// Đề xuất, nhận, bỏ qua, chốt kết quả thử thách tuần.
class ChallengeService {
  ChallengeService(this._challenges, this._meals, this._report, this._session);

  final ChallengeRepository _challenges;
  final MealRepository _meals;
  final BuildWeeklyReport _report;
  final SessionService _session;
  bool _finalizedThisSession = false;

  static String weekKeyOf(DateTime now) => VnCalendar.dateKey(VnCalendar.weekStartOf(now));

  /// Gộp 2 nguồn realtime: danh sách thử thách + báo cáo tuần (từ nhật ký).
  Stream<ChallengeViewState> watchState() {
    late final StreamController<ChallengeViewState> controller;
    StreamSubscription<List<Challenge>>? challengeSub;
    StreamSubscription<WeeklyReport>? reportSub;
    List<Challenge>? challenges;
    WeeklyReport? report;

    void emit() {
      if (challenges != null && report != null) {
        controller.add(_buildState(challenges!, report!));
      }
    }

    controller = StreamController<ChallengeViewState>(
      onListen: () {
        if (!_finalizedThisSession) {
          _finalizedThisSession = true;
          unawaited(finalizePastWeeks());
        }
        challengeSub = _challenges.watchChallenges(_session.uid).listen(
          (v) {
            challenges = v;
            emit();
          },
          onError: controller.addError,
        );
        reportSub = _report.watch().listen(
          (v) {
            report = v;
            emit();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await challengeSub?.cancel();
        await reportSub?.cancel();
      },
    );
    return controller.stream;
  }

  ChallengeViewState _buildState(List<Challenge> challenges, WeeklyReport report) {
    final weekKey = VnCalendar.dateKey(report.current.weekStart);
    final current = challenges.where((c) => c.weekStart == weekKey).firstOrNull;
    return ChallengeViewState(
      weekKey: weekKey,
      current: current,
      liveProgress:
          current == null ? 0 : ChallengeRules.progressFor(current.type, report.current),
      proposal: ChallengeRules.propose(
        lastWeek: report.previous,
        lastWeekSufficient: report.previousSufficient,
        goal: _session.goal,
      ),
      streak: ChallengeRules.streak(challenges, currentWeekStart: weekKey),
      history: challenges.where((c) => c.weekStart.compareTo(weekKey) < 0).toList(),
      currentStats: report.current,
    );
  }

  /// Nhận thử thách (có thể chỉnh [target]). Mỗi tuần tối đa 1 thử thách.
  void accept(ChallengeProposal proposal, {int? target, required int currentProgress}) {
    final weekKey = weekKeyOf(DateTime.now());
    _challenges.saveChallenge(
      _session.uid,
      Challenge(
        id: weekKey,
        type: proposal.type,
        weekStart: weekKey,
        target: target ?? proposal.target,
        progress: currentProgress,
        status: ChallengeStatus.active,
      ),
    );
  }

  /// Bỏ qua: lưu trạng thái cancelled để không hỏi lại trong tuần này.
  void skip(ChallengeProposal proposal) {
    final weekKey = weekKeyOf(DateTime.now());
    _challenges.saveChallenge(
      _session.uid,
      Challenge(
        id: weekKey,
        type: proposal.type,
        weekStart: weekKey,
        target: proposal.target,
        status: ChallengeStatus.cancelled,
      ),
    );
  }

  void updateTarget(Challenge challenge, int target) {
    _challenges.saveChallenge(_session.uid, challenge.copyWith(target: target));
  }

  /// Chốt kết quả các thử thách còn `active` của những tuần đã kết thúc.
  Future<void> finalizePastWeeks({DateTime? now}) async {
    try {
      final uid = _session.uid;
      final currentKey = weekKeyOf(now ?? DateTime.now());
      final all = await _challenges.getChallenges(uid);
      for (final c in all) {
        if (c.status != ChallengeStatus.active || c.weekStart.compareTo(currentKey) >= 0) {
          continue;
        }
        final weekStart = VnCalendar.parseDateKey(c.weekStart);
        final range = VnCalendar.weekRangeUtc(weekStart);
        final meals = await _meals.getMealsBetween(uid, range.start, range.end);
        final progress = ChallengeRules.progressFor(c.type, WeeklyStats.compute(meals, weekStart));
        _challenges.saveChallenge(
          uid,
          c.copyWith(
            progress: progress,
            status: ChallengeRules.evaluate(c.type, c.target, progress),
          ),
        );
      }
    } catch (e) {
      debugPrint('Finalize challenges failed: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/challenge.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/challenge_repository.dart';
import 'firestore_converters.dart';
import 'firestore_paths.dart';

/// Thử thách tuần `users/{uid}/challenges/{weekStart}`.
///
/// Dùng chính `week_start` ("yyyy-MM-dd") làm id document, nên mỗi tuần chỉ
/// có tối đa 1 thử thách, kể cả khi 2 thiết bị cùng tạo.
class FirestoreChallengeRepository implements ChallengeRepository {
  FirestoreChallengeRepository(this._paths);

  final FirestorePaths _paths;

  Query<Map<String, dynamic>> _recent(String uid) =>
      _paths.challenges(uid).orderBy('week_start', descending: true).limit(52);

  @override
  Stream<List<Challenge>> watchChallenges(String uid) => _recent(uid)
      .snapshots()
      .map((snap) => snap.docs.map((d) => _fromMap(d.id, d.data())).toList());

  @override
  Future<List<Challenge>> getChallenges(String uid) async {
    final snap = await _recent(uid).get();
    return snap.docs.map((d) => _fromMap(d.id, d.data())).toList();
  }

  @override
  String saveChallenge(String uid, Challenge challenge) {
    final id = challenge.id ?? challenge.weekStart;
    final data = <String, dynamic>{
      'type': challenge.type.value,
      'week_start': challenge.weekStart,
      'target': challenge.target,
      'progress': challenge.progress,
      'status': challenge.status.value,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (challenge.createdAt == null) data['created_at'] = FieldValue.serverTimestamp();
    FirestoreConverters.fireAndForget(
      _paths.challenges(uid).doc(id).set(data, SetOptions(merge: true)),
      'saveChallenge',
    );
    return id;
  }

  Challenge _fromMap(String id, Map<String, dynamic> m) => Challenge(
        id: id,
        type: parseWire(ChallengeType.values, m['type'], ChallengeType.vegMeals),
        weekStart: (m['week_start'] as String?) ?? id,
        target: FirestoreConverters.toInt(m['target']),
        progress: FirestoreConverters.toInt(m['progress']),
        status: parseWire(ChallengeStatus.values, m['status'], ChallengeStatus.active),
        createdAt: FirestoreConverters.toDateTime(m['created_at']),
        updatedAt: FirestoreConverters.toDateTime(m['updated_at']),
      );
}

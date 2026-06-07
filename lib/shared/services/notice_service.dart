import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/notice.dart';

class NoticeService {
  final FirebaseFirestore _firestore;

  NoticeService(this._firestore);

  /// Streams active notices for a given role in a school, ordered by date.
  Stream<List<Notice>> getNoticesForRole(String schoolId, String role) {
    return _firestore
        .collection(FirebaseConstants.kColNotices)
        .where('schoolId', isEqualTo: schoolId)
        .where('isActive', isEqualTo: true)
        .where('targetRoles', arrayContains: role)
        .snapshots()
        .map((snapshot) {
          final notices = snapshot.docs.map((doc) => Notice.fromFirestore(doc)).toList();
          // Client-side sorting as compound queries with array-contains require index creation
          notices.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return notices;
        });
  }

  /// Creates a new notice announcement in Firestore.
  Future<void> createNotice(Notice notice) async {
    try {
      final docRef = notice.noticeId.isEmpty
          ? _firestore.collection(FirebaseConstants.kColNotices).doc()
          : _firestore.collection(FirebaseConstants.kColNotices).doc(notice.noticeId);

      final noticeToSave = notice.noticeId.isEmpty
          ? notice.copyWith(noticeId: docRef.id)
          : notice;

      await docRef.set(noticeToSave.toMap());
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for [NoticeService] enabling dependency injection.
final noticeServiceProvider = Provider<NoticeService>((ref) {
  return NoticeService(FirebaseFirestore.instance);
});

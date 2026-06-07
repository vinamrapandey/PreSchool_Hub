import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/activity_post.dart';

class ActivityService {
  final FirebaseFirestore _firestore;

  ActivityService(this._firestore);

  /// Streams activity updates published to a specific class, ordered by time.
  Stream<List<ActivityPost>> getActivitiesByClass(String schoolId, String classId) {
    return _firestore
        .collection(FirebaseConstants.kColActivities)
        .where('schoolId', isEqualTo: schoolId)
        .where('classId', isEqualTo: classId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityPost.fromFirestore(doc))
            .toList());
  }

  /// Posts a new activity update/message to Firestore.
  Future<void> postActivity(ActivityPost post) async {
    try {
      final docRef = post.postId.isEmpty
          ? _firestore.collection(FirebaseConstants.kColActivities).doc()
          : _firestore.collection(FirebaseConstants.kColActivities).doc(post.postId);
          
      final postToSave = post.postId.isEmpty
          ? post.copyWith(postId: docRef.id)
          : post;

      await docRef.set(postToSave.toMap());
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for [ActivityService] enabling dependency injection.
final activityServiceProvider = Provider<ActivityService>((ref) {
  return ActivityService(FirebaseFirestore.instance);
});

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class UserProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('userProfiles').doc(user.uid).get();
      if (doc.exists) {
        return UserProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user profile: $e');
      return null;
    }
  }

  /// Get user profile by UID
  Future<UserProfile?> getUserProfileByUid(String uid) async {
    try {
      final doc = await _firestore.collection('userProfiles').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  /// Create new profile (call after registration)
  Future<void> createUserProfile(String uid, String email, {String displayName = ''}) async {
    try {
      final userProfile = UserProfile(
        uid: uid,
        email: email,
        displayName: displayName.isEmpty ? email.split('@').first : displayName,
        greenPoints: 0,
        level: 1,
        reportCount: 0,
        itemsSorted: 0,
        badges: [],
        preferences: {
          'notificationsEnabled': true,
          'darkMode': false,
          'language': 'en',
          'fontSize': 'normal',
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('userProfiles').doc(uid).set(userProfile.toJson());
      debugPrint('User profile created for $uid');
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  /// Update specific profile fields
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = DateTime.now();
      await _firestore.collection('userProfiles').doc(uid).update(data);
      debugPrint('User profile updated for $uid');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Award green points with transaction
  Future<void> awardPoints(int points, {String reason = 'Action completed'}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('userProfiles').doc(user.uid);
        final snapshot = await transaction.get(userRef);

        if (!snapshot.exists) {
          throw Exception('User profile not found');
        }

        final currentPoints = snapshot.get('greenPoints') as int? ?? 0;
        final newPoints = currentPoints + points;
        final newLevel = (newPoints ~/ 100) + 1;

        transaction.update(userRef, {
          'greenPoints': newPoints,
          'level': newLevel,
          'updatedAt': DateTime.now(),
        });
      });

      debugPrint('Awarded $points points to ${user.uid}');
    } catch (e) {
      debugPrint('Error awarding points: $e');
      rethrow;
    }
  }

  /// Increment report count
  Future<void> incrementReportCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('userProfiles').doc(user.uid).update({
        'reportCount': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      debugPrint('Error incrementing report count: $e');
    }
  }

  /// Increment items sorted count
  Future<void> incrementItemsSorted(int count) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('userProfiles').doc(user.uid).update({
        'itemsSorted': FieldValue.increment(count),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      debugPrint('Error incrementing items sorted: $e');
    }
  }

  /// Add badge to user
  Future<void> addBadge(String badgeName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('userProfiles').doc(user.uid).update({
        'badges': FieldValue.arrayUnion([badgeName]),
        'updatedAt': DateTime.now(),
      });

      debugPrint('Badge added: $badgeName');
    } catch (e) {
      debugPrint('Error adding badge: $e');
    }
  }

  /// Update user preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('userProfiles').doc(user.uid).update({
        'preferences': preferences,
        'updatedAt': DateTime.now(),
      });

      debugPrint('Preferences updated');
    } catch (e) {
      debugPrint('Error updating preferences: $e');
      rethrow;
    }
  }

  /// Get leaderboard (top users by greenPoints)
  Future<List<UserProfile>> getLeaderboard({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('userProfiles')
          .orderBy('greenPoints', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => UserProfile.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }

  /// Stream user profile updates
  Stream<UserProfile?> userProfileStream(String uid) {
    return _firestore
        .collection('userProfiles')
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.exists ? UserProfile.fromJson(snapshot.data()!) : null)
        .handleError((e) {
      debugPrint('Error in userProfileStream: $e');
      return null;
    });
  }

  /// Stream leaderboard updates
  Stream<List<UserProfile>> leaderboardStream({int limit = 50}) {
    return _firestore
        .collection('userProfiles')
        .orderBy('greenPoints', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserProfile.fromJson(doc.data())).toList())
        .handleError((e) {
      debugPrint('Error in leaderboardStream: $e');
      return [];
    });
  }

  /// Get user rank among all users
  Future<int?> getUserRank(String uid) async {
    try {
      final userProfile = await getUserProfileByUid(uid);
      if (userProfile == null) return null;

      final snapshot = await _firestore
          .collection('userProfiles')
          .where('greenPoints', isGreaterThan: userProfile.greenPoints)
          .count()
          .get();

      return (snapshot.count ?? 0) + 1;
    } catch (e) {
      debugPrint('Error getting user rank: $e');
      return null;
    }
  }

  /// Get total number of users
  Future<int> getTotalUsersCount() async {
    try {
      final snapshot = await _firestore.collection('userProfiles').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting total users count: $e');
      return 0;
    }
  }
}

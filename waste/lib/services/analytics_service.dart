import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/analytics.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get analytics summary for specified date range
  Future<AnalyticsSummary> getAnalyticsSummary({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      // Query reports in date range
      final reportsQuery = await _firestore
          .collection('reports')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .get();

      final reports = reportsQuery.docs;
      final totalReports = reports.length;

      // Count by status
      int pending = 0, completed = 0, rejected = 0;
      final statusBreakdown = <String, int>{};

      for (var doc in reports) {
        final status = doc.data()['status'] as String? ?? 'pending';
        statusBreakdown[status] = (statusBreakdown[status] ?? 0) + 1;

        if (status == 'pending')
          pending++;
        else if (status == 'completed' || status == 'resolved')
          completed++;
        else if (status == 'rejected')
          rejected++;
      }

      final completionRate = totalReports > 0
          ? (completed / totalReports * 100)
          : 0.0;

      // Get user stats
      final usersQuery = await _firestore.collection('userProfiles').get();
      int totalPoints = 0, totalItems = 0;
      for (var doc in usersQuery.docs) {
        totalPoints += (doc.data()['greenPoints'] as int? ?? 0);
        totalItems += (doc.data()['itemsSorted'] as int? ?? 0);
      }

      // Generate daily metrics
      final dailyMetrics = await _generateDailyMetrics(days);

      return AnalyticsSummary(
        totalReports: totalReports,
        pendingReports: pending,
        completedReports: completed,
        rejectedReports: rejected,
        completionRate: completionRate,
        totalGreenPoints: totalPoints,
        totalItemsSorted: totalItems,
        activeUsers: usersQuery.docs.length,
        statusBreakdown: statusBreakdown,
        dailyMetrics: dailyMetrics,
      );
    } catch (e) {
      debugPrint('Error getting analytics: $e');
      return AnalyticsSummary.empty();
    }
  }

  /// Generate daily metrics for chart
  Future<List<DailyMetric>> _generateDailyMetrics(int days) async {
    final metrics = <DailyMetric>[];
    final now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final nextDay = date.add(const Duration(days: 1));

      final reportsSnapshot = await _firestore
          .collection('reports')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
          .where('createdAt', isLessThan: Timestamp.fromDate(nextDay))
          .get();

      metrics.add(
        DailyMetric(
          date: date,
          reportCount: reportsSnapshot.docs.length,
          pointsEarned: 0, // Can be calculated from user activity if needed
          itemsSorted: 0,
        ),
      );
    }

    return metrics;
  }

  /// Add comment to report
  Future<void> addComment({
    required String reportId,
    required String text,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user profile for display name
      final profileDoc = await _firestore
          .collection('userProfiles')
          .doc(user.uid)
          .get();
      final displayName =
          profileDoc.data()?['displayName'] as String? ??
          user.email?.split('@').first ??
          'Unknown';

      final commentId = _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .doc()
          .id;

      final comment = ReportComment(
        id: commentId,
        reportId: reportId,
        userId: user.uid,
        userDisplayName: displayName,
        text: text,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .doc(commentId)
          .set(comment.toJson());

      debugPrint('Comment added to report $reportId');
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  /// Get comments for a report
  Stream<List<ReportComment>> getCommentsStream(String reportId) {
    return _firestore
        .collection('reports')
        .doc(reportId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReportComment.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Update report status and add timeline event
  Future<void> updateReportStatus({
    required String reportId,
    required String newStatus,
    String? note,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current report to check if status is locked
      final reportDoc = await _firestore
          .collection('reports')
          .doc(reportId)
          .get();
      final statusLocked = reportDoc.data()?['statusLocked'] as bool? ?? false;

      // If status is locked (driver already set late/early/ontime), don't allow changes
      if (statusLocked) {
        throw Exception('Status is locked and cannot be changed');
      }

      // Update report status
      await _firestore.collection('reports').doc(reportId).update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
        // Lock status if driver sets late/early/ontime
        'statusLocked': [
          'late',
          'early',
          'ontime',
        ].contains(newStatus.toLowerCase()),
      });

      // Add timeline event
      final event = TimelineEvent(
        status: newStatus,
        timestamp: DateTime.now(),
        note: note,
        updatedBy: user.uid,
      );

      await _firestore
          .collection('reports')
          .doc(reportId)
          .collection('timeline')
          .add(event.toJson());

      debugPrint('Report $reportId status updated to $newStatus');
    } catch (e) {
      debugPrint('Error updating report status: $e');
      rethrow;
    }
  }

  /// Get timeline events for a report
  Stream<List<TimelineEvent>> getTimelineStream(String reportId) {
    return _firestore
        .collection('reports')
        .doc(reportId)
        .collection('timeline')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TimelineEvent.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Toggle like on a comment
  Future<void> toggleCommentLike({
    required String reportId,
    required String commentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final commentRef = _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .doc(commentId);

      final commentDoc = await commentRef.get();
      if (!commentDoc.exists) throw Exception('Comment not found');

      final likedBy = List<String>.from(commentDoc.data()?['likedBy'] ?? []);

      if (likedBy.contains(user.uid)) {
        // Unlike
        likedBy.remove(user.uid);
      } else {
        // Like
        likedBy.add(user.uid);
      }

      await commentRef.update({'likedBy': likedBy});
      debugPrint('Comment like toggled');
    } catch (e) {
      debugPrint('Error toggling comment like: $e');
      rethrow;
    }
  }

  /// Add a reply to a comment
  Future<void> addReply({
    required String reportId,
    required String parentCommentId,
    required String text,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user profile for display name
      final profileDoc = await _firestore
          .collection('userProfiles')
          .doc(user.uid)
          .get();
      final displayName =
          profileDoc.data()?['displayName'] as String? ??
          user.email?.split('@').first ??
          'Unknown';

      final commentId = _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .doc()
          .id;

      final reply = ReportComment(
        id: commentId,
        reportId: reportId,
        userId: user.uid,
        userDisplayName: displayName,
        text: text,
        createdAt: DateTime.now(),
        parentCommentId: parentCommentId,
      );

      await _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .doc(commentId)
          .set(reply.toJson());

      debugPrint('Reply added to comment $parentCommentId');
    } catch (e) {
      debugPrint('Error adding reply: $e');
      rethrow;
    }
  }

  /// Get replies for a specific comment
  Stream<List<ReportComment>> getRepliesStream(
    String reportId,
    String parentCommentId,
  ) {
    return _firestore
        .collection('reports')
        .doc(reportId)
        .collection('comments')
        .where('parentCommentId', isEqualTo: parentCommentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReportComment.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Get top-level comments only (no replies)
  Stream<List<ReportComment>> getTopLevelCommentsStream(String reportId) {
    return _firestore
        .collection('reports')
        .doc(reportId)
        .collection('comments')
        .where('parentCommentId', isNull: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReportComment.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Get current user's personal analytics
  Future<Map<String, dynamic>> getUserAnalytics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final reportsQuery = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: user.uid)
          .get();

      final profileDoc = await _firestore
          .collection('userProfiles')
          .doc(user.uid)
          .get();
      final profileData = profileDoc.data() ?? {};

      return {
        'totalReports': reportsQuery.docs.length,
        'greenPoints': profileData['greenPoints'] ?? 0,
        'itemsSorted': profileData['itemsSorted'] ?? 0,
        'level': profileData['level'] ?? 1,
      };
    } catch (e) {
      debugPrint('Error getting user analytics: $e');
      return {};
    }
  }
}

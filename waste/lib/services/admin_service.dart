import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if current user is admin
  Future<bool> isUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final role = userDoc.data()?['role'] as String?;
      return role == 'admin' || role == 'Admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Get all users with their profiles and stats
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final users = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        users.add({
          'uid': doc.id,
          'email': data['email'],
          'displayName': data['displayName'] ?? 'Unknown',
          'role': data['role'] ?? 'resident',
          'joinedDate': data['createdAt'],
          'greenPoints': data['greenPoints'] ?? 0,
          'isVerified': data['verified'] ?? false,
        });
      }

      return users..sort((a, b) => (b['joinedDate'] as Timestamp?)?.compareTo(a['joinedDate'] as Timestamp? ?? Timestamp.now()) ?? 0);
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  /// Get admin dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Count users
      final usersSnap = await _firestore.collection('users').count().get();
      final totalUsers = usersSnap.count ?? 0;

      // Count reports
      final reportsSnap = await _firestore.collection('reports').count().get();
      final totalReports = reportsSnap.count ?? 0;

      // Count today's reports
      final todayReportsSnap = await _firestore
          .collection('reports')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(today))
          .count()
          .get();
      final todayReports = todayReportsSnap.count ?? 0;

      // Count completed reports
      final completedSnap = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'completed')
          .count()
          .get();
      final completedReports = completedSnap.count ?? 0;

      // Get completion rate
      final completionRate = totalReports > 0 ? (completedReports / totalReports * 100).toStringAsFixed(1) : '0.0';

      // Get total green points awarded
      final usersQuery = await _firestore.collection('users').get();
      int totalGreenPoints = 0;
      for (final doc in usersQuery.docs) {
        totalGreenPoints += (doc.data()['greenPoints'] as int?) ?? 0;
      }

      // Get active drivers (those who posted in last 7 days)
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final activeDriversSnap = await _firestore
          .collection('trucks')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .count()
          .get();
      final activeDrivers = activeDriversSnap.count ?? 0;

      return {
        'totalUsers': totalUsers,
        'totalReports': totalReports,
        'todayReports': todayReports,
        'completedReports': completedReports,
        'completionRate': completionRate,
        'totalGreenPoints': totalGreenPoints,
        'activeDrivers': activeDrivers,
      };
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return {
        'totalUsers': 0,
        'totalReports': 0,
        'todayReports': 0,
        'completedReports': 0,
        'completionRate': '0.0',
        'totalGreenPoints': 0,
        'activeDrivers': 0,
      };
    }
  }

  /// Get recent reports (limit 20)
  Future<List<Map<String, dynamic>>> getRecentReports({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'issueType': data['issueType'],
          'location': data['location'],
          'userId': data['userId'],
          'status': data['status'],
          'timestamp': data['timestamp'],
          'issue': data['issue']?.toString().substring(0, 50) ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error fetching recent reports: $e');
      return [];
    }
  }

  /// Get report status distribution
  Future<Map<String, int>> getReportStatusDistribution() async {
    try {
      final snapshot = await _firestore.collection('reports').get();
      final distribution = <String, int>{};

      for (final doc in snapshot.docs) {
        final status = (doc.data()['status'] as String?) ?? 'pending';
        distribution[status] = (distribution[status] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      print('Error fetching status distribution: $e');
      return {};
    }
  }

  /// Get reports by date range
  Stream<QuerySnapshot> getReportsByDateRange(DateTime start, DateTime end) {
    return _firestore
        .collection('reports')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end.add(const Duration(days: 1))))
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}

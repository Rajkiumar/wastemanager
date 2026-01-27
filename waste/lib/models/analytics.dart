import 'package:cloud_firestore/cloud_firestore.dart';

/// Analytics data model for dashboard KPIs and trends
class AnalyticsSummary {
  final int totalReports;
  final int pendingReports;
  final int completedReports;
  final int rejectedReports;
  final double completionRate;
  final int totalGreenPoints;
  final int totalItemsSorted;
  final int activeUsers;
  final Map<String, int> statusBreakdown;
  final List<DailyMetric> dailyMetrics;

  AnalyticsSummary({
    required this.totalReports,
    required this.pendingReports,
    required this.completedReports,
    required this.rejectedReports,
    required this.completionRate,
    required this.totalGreenPoints,
    required this.totalItemsSorted,
    required this.activeUsers,
    required this.statusBreakdown,
    required this.dailyMetrics,
  });

  factory AnalyticsSummary.empty() {
    return AnalyticsSummary(
      totalReports: 0,
      pendingReports: 0,
      completedReports: 0,
      rejectedReports: 0,
      completionRate: 0.0,
      totalGreenPoints: 0,
      totalItemsSorted: 0,
      activeUsers: 0,
      statusBreakdown: {},
      dailyMetrics: [],
    );
  }
}

/// Daily metrics for trend charts
class DailyMetric {
  final DateTime date;
  final int reportCount;
  final int pointsEarned;
  final int itemsSorted;

  DailyMetric({
    required this.date,
    required this.reportCount,
    required this.pointsEarned,
    required this.itemsSorted,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'reportCount': reportCount,
      'pointsEarned': pointsEarned,
      'itemsSorted': itemsSorted,
    };
  }

  factory DailyMetric.fromJson(Map<String, dynamic> json) {
    return DailyMetric(
      date: (json['date'] as Timestamp).toDate(),
      reportCount: json['reportCount'] as int? ?? 0,
      pointsEarned: json['pointsEarned'] as int? ?? 0,
      itemsSorted: json['itemsSorted'] as int? ?? 0,
    );
  }
}

/// Comment model for reports
class ReportComment {
  final String id;
  final String reportId;
  final String userId;
  final String userDisplayName;
  final String text;
  final DateTime createdAt;

  ReportComment({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.userDisplayName,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReportComment.fromJson(Map<String, dynamic> json) {
    return ReportComment(
      id: json['id'] as String,
      reportId: json['reportId'] as String,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String? ?? 'Unknown User',
      text: json['text'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }
}

/// Timeline event for report status changes
class TimelineEvent {
  final String status;
  final DateTime timestamp;
  final String? note;
  final String? updatedBy;

  TimelineEvent({
    required this.status,
    required this.timestamp,
    this.note,
    this.updatedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
      'updatedBy': updatedBy,
    };
  }

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      status: json['status'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      note: json['note'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final int greenPoints;
  final int level;
  final int reportCount;
  final int itemsSorted;
  final List<String> badges;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.greenPoints = 0,
    this.level = 1,
    this.reportCount = 0,
    this.itemsSorted = 0,
    this.badges = const [],
    this.preferences = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate level based on green points
  int calculateLevel() {
    return (greenPoints ~/ 100) + 1;
  }

  /// Get progress towards next level (0.0 - 1.0)
  double getProgressToNextLevel() {
    final pointsInCurrentLevel = greenPoints % 100;
    return pointsInCurrentLevel / 100.0;
  }

  /// Get points needed for next level
  int getPointsNeededForNextLevel() {
    final pointsInCurrentLevel = greenPoints % 100;
    return 100 - pointsInCurrentLevel;
  }

  /// Check if user has specific badge
  bool hasBadge(String badgeName) {
    return badges.contains(badgeName);
  }

  /// Get user rank based on points (used for leaderboard)
  String getRank() {
    if (greenPoints >= 1000) return 'Waste Warrior';
    if (greenPoints >= 500) return 'Eco Hero';
    if (greenPoints >= 200) return 'Green Champion';
    if (greenPoints >= 100) return 'Recycling Expert';
    return 'Eco Starter';
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'greenPoints': greenPoints,
      'level': level,
      'reportCount': reportCount,
      'itemsSorted': itemsSorted,
      'badges': badges,
      'preferences': preferences,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create from Firestore JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      greenPoints: json['greenPoints'] ?? 0,
      level: json['level'] ?? 1,
      reportCount: json['reportCount'] ?? 0,
      itemsSorted: json['itemsSorted'] ?? 0,
      badges: List<String>.from(json['badges'] ?? []),
      preferences: json['preferences'] ?? {},
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  UserProfile copyWith({
    String? displayName,
    int? greenPoints,
    int? level,
    int? reportCount,
    int? itemsSorted,
    List<String>? badges,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      greenPoints: greenPoints ?? this.greenPoints,
      level: level ?? this.level,
      reportCount: reportCount ?? this.reportCount,
      itemsSorted: itemsSorted ?? this.itemsSorted,
      badges: badges ?? this.badges,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserProfile(uid: $uid, email: $email, displayName: $displayName, greenPoints: $greenPoints, level: $level)';
  }
}

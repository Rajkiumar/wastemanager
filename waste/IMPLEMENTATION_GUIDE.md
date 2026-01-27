# WasteWise Connect - Systematic Implementation Guide

This guide breaks down the implementation into manageable phases with step-by-step instructions.

---

## 📋 Phase 1: User Profiles & Leaderboard (Weeks 1-2)

### Task 1.1: Create User Profile Model
**File:** `lib/models/user_profile.dart`

```dart
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

  // Firestore toMap/fromMap methods
  // JsonSerializable or manual implementation
}
```

**Firestore Structure:**
```
userProfiles/{uid}
├── email: string
├── displayName: string
├── greenPoints: number (default: 0)
├── level: number (calculated from greenPoints)
├── reportCount: number
├── itemsSorted: number
├── badges: array
├── preferences: object
│   ├── notificationsEnabled: boolean
│   ├── darkMode: boolean
│   ├── language: string (en/es/fr)
│   └── fontSize: string (normal/large/xlarge)
├── createdAt: timestamp
└── updatedAt: timestamp
```

**Steps:**
1. Create the Dart model class
2. Add `toJson()` and `fromJson()` methods
3. Add helper methods: `calculateLevel()`, `hasAchievement(badge)`

---

### Task 1.2: Create User Profile Service
**File:** `lib/services/user_profile_service.dart`

```dart
class UserProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    final doc = await _firestore.collection('userProfiles').doc(user.uid).get();
    return doc.exists ? UserProfile.fromJson(doc.data()!) : null;
  }

  // Create new profile (call after registration)
  Future<void> createUserProfile(String uid, String email) async {
    // Implementation
  }

  // Update profile fields
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    // Implementation
  }

  // Get leaderboard (top 10 by greenPoints)
  Future<List<UserProfile>> getLeaderboard({int limit = 10}) async {
    // Implementation
  }

  // Award points with transaction
  Future<void> awardPoints(int points, String reason) async {
    // Implementation
  }

  // Stream user profile updates
  Stream<UserProfile?> userProfileStream(String uid) {
    return _firestore.collection('userProfiles').doc(uid).snapshots()
        .map((doc) => doc.exists ? UserProfile.fromJson(doc.data()!) : null);
  }
}
```

**Steps:**
1. Implement CRUD methods
2. Add transaction support for atomic point updates
3. Create stream listeners for real-time updates
4. Add error handling and logging

---

### Task 1.3: Create User Profile Screen
**File:** `lib/screens/profile_screen.dart`

**Layout:**
```
[Header with user avatar]
├── Profile Stats Card
│   ├── Green Points (large number)
│   ├── Level & Progress Bar
│   ├── Reports Submitted
│   └── Items Sorted
├── Badges & Achievements Section
├── Recent Activity
└── Edit Profile / Settings button
```

**Steps:**
1. Use `StreamBuilder` to fetch user profile
2. Display stats with cards and progress indicators
3. Show badges grid
4. Add "Edit Profile" and "Settings" buttons

---

### Task 1.4: Create Settings Tab in Profile
**File:** `lib/screens/settings_screen.dart`

**Features:**
- Toggle notifications
- Toggle dark mode
- Language selection (English, Spanish, French)
- Font size (Normal, Large, XLarge)
- Account management (email, password reset)
- Privacy settings
- Logout button

**Implementation:**
```dart
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserProfileService _profileService;

  @override
  void initState() {
    super.initState();
    _profileService = UserProfileService();
  }

  // Toggle methods
  Future<void> _toggleNotifications(bool value) async {
    // Update preference in Firestore
  }

  Future<void> _toggleDarkMode(bool value) async {
    // Update and apply theme
  }

  // Language selection
  Future<void> _setLanguage(String code) async {
    // Update preference and change locale
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Notification toggle
          // Dark mode toggle
          // Language dropdown
          // Font size selector
          // Account section
          // Logout button
        ],
      ),
    );
  }
}
```

---

### Task 1.5: Create Leaderboard Tab
**File:** `lib/tabs/leaderboard_tab.dart`

**Features:**
- List of top users by Green Points
- User rank, avatar, name, points, level
- Filter buttons: All Time / This Month / This Week
- Search functionality (optional)

**Firestore Query:**
```dart
_firestore
  .collection('userProfiles')
  .orderBy('greenPoints', descending: true)
  .limit(50)
  .snapshots()
```

**Implementation:**
```dart
class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  String _selectedFilter = 'All Time'; // All Time, Month, Week

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Leaderboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All Time', child: Text('All Time')),
              const PopupMenuItem(value: 'Month', child: Text('This Month')),
              const PopupMenuItem(value: 'Week', child: Text('This Week')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getLeaderboardStream(),
        builder: (context, snapshot) {
          // Build leaderboard list
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getLeaderboardStream() {
    // Filter based on selectedFilter and return appropriate stream
  }
}
```

---

### Task 1.6: Integrate Profile & Leaderboard into Main Shell
**File:** `lib/main_shell.dart`

**Changes:**
1. Add profile and leaderboard to navigation destinations
2. Add new screens to the screens list
3. Update tab titles and icons

```dart
final screens = <Widget>[
  TrackerTab(userRole: widget.role),
  const ScheduleTab(),
  const ReportTab(),
  const EducationTab(),
  const LeaderboardTab(),      // NEW
  const ProfileScreen(),         // NEW
];

const destinations = [
  NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Tracker'),
  NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Schedule'),
  NavigationDestination(icon: Icon(Icons.report), label: 'Reports'),
  NavigationDestination(icon: Icon(Icons.school), label: 'Education'),
  NavigationDestination(icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
  NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
];
```

---

## 🔧 Implementation Checklist for Phase 1

- [ ] Create `lib/models/` folder and `user_profile.dart`
- [ ] Create `lib/services/user_profile_service.dart`
- [ ] Create `lib/screens/profile_screen.dart`
- [ ] Create `lib/screens/settings_screen.dart`
- [ ] Create `lib/tabs/leaderboard_tab.dart`
- [ ] Update `lib/main_shell.dart` with new tabs
- [ ] Update Firestore security rules to allow profile reads/writes
- [ ] Test: Create user → View profile → Update settings → Check leaderboard
- [ ] Test: Award points from Education tab → See profile update in real-time
- [ ] Update `pubspec.yaml` if using any new packages

---

## 📂 Expected Folder Structure After Phase 1

```
lib/
├── models/
│   └── user_profile.dart          [NEW]
├── services/
│   ├── user_profile_service.dart  [NEW]
│   └── auth_service.dart          [EXISTING]
├── screens/
│   ├── profile_screen.dart        [NEW]
│   └── settings_screen.dart       [NEW]
├── tabs/
│   ├── leaderboard_tab.dart       [NEW]
│   └── ...other tabs
├── features/
│   └── auth/
│       └── login_screen.dart      [EXISTING]
└── main_shell.dart                [UPDATED]
```

---

## 🚀 Next Steps After Phase 1

Once Phase 1 is complete:
1. Update `README.md` with new features
2. Start Phase 2 (Analytics + Enhanced Reports)
3. Gather user feedback on profile/leaderboard UI
4. Optimize Firestore queries if needed

---

## 💡 Tips for Implementation

1. **Firestore Rules:** Update security rules to allow authenticated users to read all profiles but only modify their own
2. **Real-time Updates:** Use `StreamBuilder` for live stat updates
3. **Performance:** Index Firestore on `greenPoints` for leaderboard sorting
4. **Error Handling:** Wrap all Firestore calls in try-catch blocks
5. **Testing:** Create test accounts and verify:
   - Profile creation on registration
   - Points update when actions occur
   - Leaderboard ordering
   - Settings persistence

---

## Questions to Consider

1. Should profiles have profile pictures? (Add image upload to Firebase Storage)
2. Should achievements auto-unlock or be manually awarded?
3. Should leaderboard show real names or usernames?
4. Time-based leaderboard: Weekly/Monthly reset or cumulative?


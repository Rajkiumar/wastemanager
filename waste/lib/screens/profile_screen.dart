import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile.dart';
import '../features/auth/login_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfileService _profileService;

  @override
  void initState() {
    super.initState();
    _profileService = UserProfileService();
  }

  Future<void> _createMissingProfile(User user) async {
    try {
      await _profileService.createUserProfile(
        user.uid,
        user.email ?? '',
        displayName: user.displayName ?? '',
      );
      // Trigger rebuild by setting state after a delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error creating profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(
          child: Text('Please log in to view your profile'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _profileService.userProfileStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data;
          if (profile == null) {
            // Auto-create profile for existing users without one
            return FutureBuilder(
              future: _createMissingProfile(user),
              builder: (context, createSnapshot) {
                if (createSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Setting up your profile...'),
                      ],
                    ),
                  );
                }
                return const Center(child: Text('Profile created! Please refresh.'));
              },
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Header
                _buildProfileHeader(profile),
                const SizedBox(height: 24),

                // Stats Cards
                _buildStatsSection(profile),
                const SizedBox(height: 24),

                // Rank & Level
                _buildRankSection(profile),
                const SizedBox(height: 24),

                // Quick Info
                _buildQuickInfo(profile),
                const SizedBox(height: 24),

                // Badges Section
                _buildBadgesSection(profile),
                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green.shade200,
              child: Text(
                profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.green,
                child: IconButton(
                  icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(currentProfile: profile),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          profile.displayName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          profile.email,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user, size: 16, color: Colors.green.shade700),
              const SizedBox(width: 4),
              Text(
                'Verified Member',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(UserProfile profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard(
          icon: Icons.star,
          label: 'Green Points',
          value: profile.greenPoints.toString(),
          color: Colors.amber,
        ),
        _buildStatCard(
          icon: Icons.assignment,
          label: 'Reports',
          value: profile.reportCount.toString(),
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.recycling,
          label: 'Items Sorted',
          value: profile.itemsSorted.toString(),
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankSection(UserProfile profile) {
    final progressToNextLevel = profile.getProgressToNextLevel();
    final pointsNeeded = profile.getPointsNeededForNextLevel();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.getRank(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Level ${profile.level}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pointsNeeded pts to next',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressToNextLevel,
                minHeight: 12,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(Colors.green.shade400),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progressToNextLevel * 100).toStringAsFixed(1)}% progress',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfo(UserProfile profile) {
    final daysSinceJoined = DateTime.now().difference(profile.createdAt).inDays;
    final avgPointsPerDay = daysSinceJoined > 0 ? (profile.greenPoints / daysSinceJoined).toStringAsFixed(1) : '0';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Stats',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today, 'Member for', '$daysSinceJoined days'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.trending_up, 'Avg points/day', avgPointsPerDay),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.eco,
              'Total impact',
              '${profile.greenPoints + profile.itemsSorted} actions',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.green),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBadgesSection(UserProfile profile) {
    final earnedBadges = profile.badges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (earnedBadges.isEmpty)
          Center(
            child: Text(
              'No badges earned yet. Keep sorting waste to earn achievements!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: earnedBadges.map((badge) => _buildBadgeCard(badge, true)).toList(),
          ),
      ],
    );
  }

  Widget _buildBadgeCard(String badgeName, bool earned) {
    final badgeEmoji = {
      'Eco Starter': '🌱',
      'Green Champion': '🏆',
      'Waste Warrior': '⚔️',
      'Recycling Expert': '♻️',
    };

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: earned ? Colors.amber.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: earned ? Colors.amber : Colors.grey,
              width: 2,
            ),
          ),
          child: Text(
            badgeEmoji[badgeName] ?? '🎖️',
            style: const TextStyle(fontSize: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          badgeName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: earned ? Colors.black : Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          icon: const Icon(Icons.settings),
          label: const Text('Settings'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            }
          },
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}

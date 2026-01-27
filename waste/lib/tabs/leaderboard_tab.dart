import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile.dart';

class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  late UserProfileService _profileService;
  String _selectedFilter = 'All Time';

  @override
  void initState() {
    super.initState();
    _profileService = UserProfileService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Leaderboard'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'All Time',
                child: Row(
                  children: [
                    Icon(
                      _selectedFilter == 'All Time' ? Icons.check : Icons.radio_button_unchecked,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text('All Time'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Month',
                child: Row(
                  children: [
                    Icon(
                      _selectedFilter == 'Month' ? Icons.check : Icons.radio_button_unchecked,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text('This Month'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Week',
                child: Row(
                  children: [
                    Icon(
                      _selectedFilter == 'Week' ? Icons.check : Icons.radio_button_unchecked,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text('This Week'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'How to get on the leaderboard',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Earn green points by submitting reports, sorting items, and completing education tasks. '
                            'Consistent participation boosts your rank!',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserProfile>>(
              stream: _profileService.leaderboardStream(limit: 100),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.leaderboard, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No users on leaderboard yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                final users = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final rank = index + 1;
                    final isTopThree = rank <= 3;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Card(
                        elevation: isTopThree ? 4 : 1,
                        child: ListTile(
                          leading: _buildRankBadge(rank),
                          title: Text(
                            user.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(user.getRank()),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Level ${user.level}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                user.greenPoints.toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Text(
                                'points',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color backgroundColor;
    Color textColor;
    String emoji = '';

    if (rank == 1) {
      backgroundColor = Colors.amber.shade300;
      textColor = Colors.black;
      emoji = '🥇';
    } else if (rank == 2) {
      backgroundColor = Colors.grey.shade300;
      textColor = Colors.black;
      emoji = '🥈';
    } else if (rank == 3) {
      backgroundColor = Colors.orange.shade200;
      textColor = Colors.black;
      emoji = '🥉';
    } else {
      backgroundColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
      emoji = '';
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: emoji.isNotEmpty
            ? Text(emoji, style: const TextStyle(fontSize: 20))
            : Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
      ),
    );
  }
}

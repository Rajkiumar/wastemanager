import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_profile_service.dart';

class EducationTab extends StatefulWidget {
  const EducationTab({super.key});

  @override
  State<EducationTab> createState() => _EducationTabState();
}

class _EducationTabState extends State<EducationTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Map<String, Map<String, dynamic>> _sortingGuide = {
    // Organic Waste
    'Food scraps': {'bin': 'Organic', 'color': Colors.green, 'icon': Icons.eco, 'points': 5},
    'Fruit peels': {'bin': 'Organic', 'color': Colors.green, 'icon': Icons.eco, 'points': 5},
    'Vegetable waste': {'bin': 'Organic', 'color': Colors.green, 'icon': Icons.eco, 'points': 5},
    'Coffee grounds': {'bin': 'Organic', 'color': Colors.green, 'icon': Icons.eco, 'points': 5},
    'Tea bags': {'bin': 'Organic', 'color': Colors.green, 'icon': Icons.eco, 'points': 5},
    'Yard waste': {'bin': 'Organic', 'color': Colors.green, 'icon': Icons.eco, 'points': 5},
    'Leaves': {'bin': 'Organic', 'color': Colors.green, 'icon': Icons.eco, 'points': 5},
    
    // Plastic & Metal
    'Plastic bottles': {'bin': 'Plastic & Metal', 'color': Colors.yellow.shade700, 'icon': Icons.recycling, 'points': 10},
    'Plastic containers': {'bin': 'Plastic & Metal', 'color': Colors.yellow.shade700, 'icon': Icons.recycling, 'points': 10},
    'Aluminum cans': {'bin': 'Plastic & Metal', 'color': Colors.yellow.shade700, 'icon': Icons.recycling, 'points': 10},
    'Metal cans': {'bin': 'Plastic & Metal', 'color': Colors.yellow.shade700, 'icon': Icons.recycling, 'points': 10},
    'Plastic bags': {'bin': 'Plastic & Metal', 'color': Colors.yellow.shade700, 'icon': Icons.recycling, 'points': 10},
    'Food wrappers': {'bin': 'Plastic & Metal', 'color': Colors.yellow.shade700, 'icon': Icons.recycling, 'points': 10},
    
    // Paper & Cardboard
    'Newspapers': {'bin': 'Paper & Cardboard', 'color': Colors.blue, 'icon': Icons.description, 'points': 8},
    'Magazines': {'bin': 'Paper & Cardboard', 'color': Colors.blue, 'icon': Icons.description, 'points': 8},
    'Cardboard boxes': {'bin': 'Paper & Cardboard', 'color': Colors.blue, 'icon': Icons.description, 'points': 8},
    'Paper bags': {'bin': 'Paper & Cardboard', 'color': Colors.blue, 'icon': Icons.description, 'points': 8},
    'Office paper': {'bin': 'Paper & Cardboard', 'color': Colors.blue, 'icon': Icons.description, 'points': 8},
    'Pizza boxes': {'bin': 'Paper & Cardboard', 'color': Colors.blue, 'icon': Icons.description, 'points': 8, 'note': 'Only if not greasy'},
    'Envelopes': {'bin': 'Paper & Cardboard', 'color': Colors.blue, 'icon': Icons.description, 'points': 8},
    
    // Glass & Electronics
    'Glass bottles': {'bin': 'Glass & Electronics', 'color': Colors.purple, 'icon': Icons.electrical_services, 'points': 12},
    'Glass jars': {'bin': 'Glass & Electronics', 'color': Colors.purple, 'icon': Icons.electrical_services, 'points': 12},
    'Light bulbs': {'bin': 'Glass & Electronics', 'color': Colors.purple, 'icon': Icons.electrical_services, 'points': 12},
    'Batteries': {'bin': 'Glass & Electronics', 'color': Colors.purple, 'icon': Icons.electrical_services, 'points': 15},
    'Electronics': {'bin': 'Glass & Electronics', 'color': Colors.purple, 'icon': Icons.electrical_services, 'points': 15},
    'Phone chargers': {'bin': 'Glass & Electronics', 'color': Colors.purple, 'icon': Icons.electrical_services, 'points': 15},
    'Old phones': {'bin': 'Glass & Electronics', 'color': Colors.purple, 'icon': Icons.electrical_services, 'points': 20},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, Map<String, dynamic>>> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return _sortingGuide.entries.toList();
    }
    return _sortingGuide.entries
        .where((entry) =>
            entry.key.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            entry.value['bin'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _awardPoints(int points) async {
    try {
      await UserProfileService().awardPoints(points, reason: 'Waste sorting learned');
    } catch (e) {
      debugPrint('Error awarding points: $e');
    }
  }

  void _showItemDetails(String itemName, Map<String, dynamic> details) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: details['color'],
              child: Icon(details['icon'], size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              itemName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: details['color'].withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                details['bin'],
                style: TextStyle(
                  color: details['color'],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (details['note'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        details['note'],
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _awardPoints(details['points']);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Earned ${details['points']} Green Points! 🎉'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.stars),
                label: Text('Earn ${details['points']} Points'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Education Hub'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Sorting Guide'),
            Tab(icon: Icon(Icons.emoji_events), text: 'My Points'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSortingGuide(),
          _buildGamification(),
        ],
      ),
    );
  }

  Widget _buildSortingGuide() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search items... (e.g., "pizza box")',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        
        // Category Chips
        if (_searchQuery.isEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCategoryChip('All', Colors.grey),
                _buildCategoryChip('Organic', Colors.green),
                _buildCategoryChip('Plastic', Colors.yellow.shade700),
                _buildCategoryChip('Paper', Colors.blue),
                _buildCategoryChip('Glass', Colors.purple),
              ],
            ),
          ),
        
        const SizedBox(height: 8),
        
        // Items List
        Expanded(
          child: _filteredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No items found',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try a different search term',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final entry = _filteredItems[index];
                    final itemName = entry.key;
                    final details = entry.value;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: details['color'],
                          child: Icon(details['icon'], color: Colors.white),
                        ),
                        title: Text(
                          itemName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(details['bin']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars, size: 16, color: Colors.amber.shade700),
                            const SizedBox(width: 4),
                            Text(
                              '+${details['points']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showItemDetails(itemName, details),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        backgroundColor: color.withOpacity(0.1),
        selectedColor: color.withOpacity(0.3),
        checkmarkColor: color,
        selected: false,
        onSelected: (selected) {
          setState(() {
            _searchQuery = selected ? label : '';
            _searchController.text = _searchQuery;
          });
        },
      ),
    );
  }

  Widget _buildGamification() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Please log in to track your points'),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        int greenPoints = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          greenPoints = snapshot.data!.get('greenPoints') ?? 0;
        }

        final level = (greenPoints / 100).floor() + 1;
        final pointsToNextLevel = (level * 100) - greenPoints;
        final progress = (greenPoints % 100) / 100;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Points Card
              Card(
                elevation: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events, size: 60, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        '$greenPoints',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Green Points',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Level $level',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Progress to Next Level
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progress to Next Level',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation(Colors.green.shade600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$pointsToNextLevel points to Level ${level + 1}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // How to Earn Points
              const Text(
                'How to Earn Points',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildPointsInfo('Search sorting guide', '5-20 points per item', Icons.search),
              _buildPointsInfo('Report issues', '25 points per report', Icons.report),
              _buildPointsInfo('Complete challenges', '50-100 points', Icons.card_giftcard),
              
              const SizedBox(height: 20),
              
              // Achievements
              const Text(
                'Achievements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildAchievement('First Steps', 'Earn your first 50 points', greenPoints >= 50),
              _buildAchievement('Eco Warrior', 'Reach 100 points', greenPoints >= 100),
              _buildAchievement('Green Champion', 'Reach 500 points', greenPoints >= 500),
              _buildAchievement('Sustainability Master', 'Reach 1000 points', greenPoints >= 1000),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPointsInfo(String title, String points, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(icon, color: Colors.green.shade700),
        ),
        title: Text(title),
        trailing: Text(
          points,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildAchievement(String title, String description, bool unlocked) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          unlocked ? Icons.check_circle : Icons.lock,
          color: unlocked ? Colors.green : Colors.grey,
          size: 32,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: unlocked ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(description),
      ),
    );
  }
}

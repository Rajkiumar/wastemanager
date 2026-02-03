import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Overview Stats
            _buildStatsSection(),
            const SizedBox(height: 24),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTabButton('Analytics', 0),
                  const SizedBox(width: 8),
                  _buildTabButton('Reports', 1),
                  const SizedBox(width: 8),
                  _buildTabButton('Users', 2),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            if (_selectedTabIndex == 0) _buildAnalyticsTab(),
            if (_selectedTabIndex == 1) _buildReportsTab(),
            if (_selectedTabIndex == 2) _buildUsersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => _selectedTabIndex = index),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.grey.shade200,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          elevation: isSelected ? 4 : 0,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildStatsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _adminService.getDashboardStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        final stats = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildStatCard('Total Users', stats['totalUsers'].toString(), Colors.blue, Icons.people),
              _buildStatCard('Total Reports', stats['totalReports'].toString(), Colors.orange, Icons.description),
              _buildStatCard('Today\'s Reports', stats['todayReports'].toString(), Colors.green, Icons.today),
              _buildStatCard('Completed', stats['completedReports'].toString(), Colors.teal, Icons.check_circle),
              _buildStatCard('Completion %', '${stats['completionRate']}%', Colors.purple, Icons.trending_up),
              _buildStatCard('Green Points', stats['totalGreenPoints'].toString(), Colors.lime, Icons.star),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Status Distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, int>>(
            future: _adminService.getReportStatusDistribution(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final distribution = snapshot.data!;
              if (distribution.isEmpty) {
                return const Text('No reports yet');
              }

              return Column(
                children: distribution.entries.map((entry) {
                  final status = entry.key;
                  final count = entry.value;
                  final percentage =
                      distribution.values.reduce((a, b) => a + b) > 0
                          ? (count / distribution.values.reduce((a, b) => a + b) * 100)
                              .toStringAsFixed(1)
                          : '0';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              status.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text('$count ($percentage%)'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: double.parse(percentage) / 100,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getStatusColor(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _adminService.getRecentReports(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }

          final reports = snapshot.data!;
          if (reports.isEmpty) {
            return const Center(child: Text('No reports yet'));
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final timestamp = report['timestamp'] as Timestamp?;
              final timeText = timestamp != null
                  ? '${timestamp.toDate().month}/${timestamp.toDate().day} ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                  : 'N/A';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(report['status']),
                    child: Icon(
                      _getStatusIcon(report['status']),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  title: Text(report['issueType'] ?? 'Unknown'),
                  subtitle: Text(
                    '${report['location'] ?? 'Unknown'} • $timeText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(report['status']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report['status']?.toString().toUpperCase() ?? 'N/A',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(report['status']),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUsersTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _adminService.getAllUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }

          final users = snapshot.data!;
          if (users.isEmpty) {
            return const Center(child: Text('No users yet'));
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final joinDate = user['joinedDate'] as Timestamp?;
              final joinText = joinDate != null
                  ? '${joinDate.toDate().month}/${joinDate.toDate().day}/${joinDate.toDate().year}'
                  : 'N/A';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade200,
                    child: Text(
                      (user['displayName'] as String?)?.characters.first.toUpperCase() ?? '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(user['displayName'] ?? 'Unknown'),
                  subtitle: Text(
                    '${user['role']?.toString().toUpperCase() ?? 'RESIDENT'} • Joined $joinText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${user['greenPoints']} pts',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (user['isVerified'] == true)
                        const Icon(Icons.verified, size: 16, color: Colors.blue),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'completed':
      case 'resolved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}

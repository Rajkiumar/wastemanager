import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/report_detail_screen.dart';
import '../services/user_profile_service.dart';

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _issueController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final UserProfileService _profileService = UserProfileService();
  String _issueType = 'Missed Collection';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _issueController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_issueController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty) {
      _showSnack('Please fill in all required fields.');
      return;
    }

    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('reports').add({
        'issue': _issueController.text,
        'location': _locationController.text,
        'issueType': _issueType,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending',
        'userId': user?.uid ?? 'anonymous',
        'userEmail': user?.email ?? 'anonymous',
      });

      _issueController.clear();
      _locationController.clear();
      setState(() {
        _issueType = 'Missed Collection';
      });

      // Update user profile stats
      await _profileService.incrementReportCount();
      await _profileService.awardPoints(25, reason: 'Submitted a report');

      _showSnack('Report submitted successfully! +25 points');
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.schedule;
      case 'In Progress':
        return Icons.engineering;
      case 'Resolved':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'New Report'),
            Tab(icon: Icon(Icons.public), text: 'All Reports'),
            Tab(icon: Icon(Icons.person), text: 'My Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildReportForm(), _buildAllReports(), _buildMyReports()],
      ),
    );
  }

  Widget _buildReportForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report an Issue',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Help us keep the community clean by reporting issues.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Issue Type Dropdown
          DropdownButtonFormField<String>(
            value: _issueType,
            decoration: const InputDecoration(
              labelText: 'Issue Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items:
                [
                      'Missed Collection',
                      'Overflowing Bin',
                      'Illegal Dumping',
                      'Damaged Bin',
                      'Other',
                    ]
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _issueType = value);
              }
            },
          ),
          const SizedBox(height: 16),

          // Location Field
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location *',
              hintText: 'Street name or address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 16),

          // Issue Description
          TextField(
            controller: _issueController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description *',
              hintText: 'Describe the issue in detail...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSending ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Submit Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReports() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view your reports'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        return _buildReportsList(snapshot, isMyReports: true);
      },
    );
  }

  Widget _buildAllReports() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (context, snapshot) {
        return _buildReportsList(snapshot, isMyReports: false);
      },
    );
  }

  Widget _buildReportsList(
    AsyncSnapshot<QuerySnapshot> snapshot, {
    required bool isMyReports,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error loading reports',
              style: TextStyle(fontSize: 18, color: Colors.red.shade600),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '${snapshot.error}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              isMyReports ? 'No reports yet' : 'No community reports yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              isMyReports
                  ? 'Your submitted reports will appear here'
                  : 'Be the first to submit a report!',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Sort documents by timestamp (newest first) client-side
    final docs = snapshot.data!.docs.toList();
    docs.sort((a, b) {
      final aTimestamp =
          (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
      final bTimestamp =
          (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
      if (aTimestamp == null && bTimestamp == null) return 0;
      if (aTimestamp == null) return 1;
      if (bTimestamp == null) return -1;
      return bTimestamp.compareTo(aTimestamp);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'Pending';
        final timestamp = data['timestamp'] as Timestamp?;
        final imageUrl = data['imageUrl'] as String?;
        final userEmail = data['userEmail'] as String? ?? 'Anonymous';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ReportDetailScreen(reportId: doc.id, reportData: data),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(status),
                    child: Icon(_getStatusIcon(status), color: Colors.white),
                  ),
                  title: Text(
                    data['issueType'] ?? 'Issue',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['location'] ?? ''),
                      if (!isMyReports)
                        Text(
                          'By: ${userEmail.split('@').first}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['issue'] ?? '',
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (timestamp != null)
                            Expanded(
                              child: Text(
                                'Submitted: ${timestamp.toDate().toString().substring(0, 16)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          Icon(
                            Icons.comment_outlined,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'View & Comment',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

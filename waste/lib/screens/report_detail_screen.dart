import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/analytics_service.dart';
import '../models/analytics.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> reportData;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
    required this.reportData,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Check if user is driver or admin (for now, simplified)
      // In production, you'd check user roles from Firestore
      setState(() {
        _userRole = 'resident'; // Default to resident
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmittingComment = true);

    try {
      await _analyticsService.addComment(
        reportId: widget.reportId,
        text: _commentController.text.trim(),
      );

      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: $e')),
      );
    } finally {
      setState(() => _isSubmittingComment = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _analyticsService.updateReportStatus(
        reportId: widget.reportId,
        newStatus: newStatus,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showStatusDialog() {
    final currentStatus = widget.reportData['status'] ?? 'pending';
    final statusLocked = widget.reportData['statusLocked'] as bool? ?? false;

    if (statusLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status is locked and cannot be changed'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select driver status:'),
            const SizedBox(height: 16),
            _buildStatusOption('early', 'Early - Arrived before scheduled time', Colors.green),
            _buildStatusOption('ontime', 'On Time - Arrived as scheduled', Colors.blue),
            _buildStatusOption('late', 'Late - Delayed pickup', Colors.orange),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String status, String description, Color color) {
    return ListTile(
      leading: Icon(Icons.circle, color: color),
      title: Text(status.toUpperCase()),
      subtitle: Text(description),
      onTap: () {
        Navigator.pop(context);
        _updateStatus(status);
      },
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
      case 'early':
        return Colors.green;
      case 'ontime':
        return Colors.blue;
      case 'late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.reportData['status'] ?? 'pending';
    final statusLocked = widget.reportData['statusLocked'] as bool? ?? false;
    final imageUrl = widget.reportData['imageUrl'] as String?;
    final timestamp = widget.reportData['timestamp'] as Timestamp?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!statusLocked)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showStatusDialog,
              tooltip: 'Update Status',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _getStatusColor(status).withOpacity(0.1),
              child: Row(
                children: [
                  Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                        if (statusLocked)
                          Text(
                            '🔒 Status locked by driver',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Report Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.category, 'Type', widget.reportData['issueType'] ?? 'N/A'),
                  _buildDetailRow(Icons.location_on, 'Location', widget.reportData['location'] ?? 'N/A'),
                  if (timestamp != null)
                    _buildDetailRow(
                      Icons.access_time,
                      'Submitted',
                      timestamp.toDate().toString().substring(0, 16),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.reportData['issue'] ?? 'No description'),
                ],
              ),
            ),

            // Image if exists
            if (imageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Timeline Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Timeline',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildTimelineSection(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Comments Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildCommentsSection(),
                  const SizedBox(height: 16),
                  _buildCommentInput(),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return StreamBuilder<List<TimelineEvent>>(
      stream: _analyticsService.getTimelineStream(widget.reportId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No timeline events yet',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.map((event) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  Icons.circle,
                  size: 12,
                  color: _getStatusColor(event.status),
                ),
                title: Text(event.status.toUpperCase()),
                subtitle: Text(
                  event.timestamp.toString().substring(0, 16),
                ),
                trailing: event.note != null
                    ? Tooltip(
                        message: event.note!,
                        child: const Icon(Icons.info_outline, size: 18),
                      )
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCommentsSection() {
    return StreamBuilder<List<ReportComment>>(
      stream: _analyticsService.getCommentsStream(widget.reportId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No comments yet. Be the first to comment!',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.map((comment) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.green.shade200,
                          child: Text(
                            comment.userDisplayName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.userDisplayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                comment.createdAt.toString().substring(0, 16),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(comment.text),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: null,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _isSubmittingComment ? null : _addComment,
          icon: _isSubmittingComment
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          style: IconButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
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
      case 'early':
        return Icons.fast_forward;
      case 'ontime':
        return Icons.access_time;
      case 'late':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }
}

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
  final TextEditingController _replyController = TextEditingController();
  bool _isSubmittingComment = false;
  String? _replyingToCommentId;
  String? _replyingToUserName;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding comment: $e')));
    } finally {
      setState(() => _isSubmittingComment = false);
    }
  }

  Future<void> _addReply(String parentCommentId) async {
    if (_replyController.text.trim().isEmpty) return;

    try {
      await _analyticsService.addReply(
        reportId: widget.reportId,
        parentCommentId: parentCommentId,
        text: _replyController.text.trim(),
      );

      _replyController.clear();
      setState(() {
        _replyingToCommentId = null;
        _replyingToUserName = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reply added successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding reply: $e')));
    }
  }

  Future<void> _toggleLike(String commentId) async {
    try {
      await _analyticsService.toggleCommentLike(
        reportId: widget.reportId,
        commentId: commentId,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _analyticsService.updateReportStatus(
        reportId: widget.reportId,
        newStatus: newStatus,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _showStatusDialog() {
    final statusLocked = widget.reportData['statusLocked'] as bool? ?? false;

    if (statusLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status is locked and cannot be changed')),
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
            _buildStatusOption(
              'early',
              'Early - Arrived before scheduled time',
              Colors.green,
            ),
            _buildStatusOption(
              'ontime',
              'On Time - Arrived as scheduled',
              Colors.blue,
            ),
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
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
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
                  _buildDetailRow(
                    Icons.category,
                    'Type',
                    widget.reportData['issueType'] ?? 'N/A',
                  ),
                  _buildDetailRow(
                    Icons.location_on,
                    'Location',
                    widget.reportData['location'] ?? 'N/A',
                  ),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
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
                subtitle: Text(event.timestamp.toString().substring(0, 16)),
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
    // Get only top-level comments (no replies)
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .collection('comments')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

        // Filter top-level comments and sort by createdAt
        final allComments = snapshot.data!.docs
            .map(
              (doc) =>
                  ReportComment.fromJson(doc.data() as Map<String, dynamic>),
            )
            .toList();

        final topLevelComments =
            allComments.where((c) => c.parentCommentId == null).toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        final repliesMap = <String, List<ReportComment>>{};
        for (final comment in allComments.where(
          (c) => c.parentCommentId != null,
        )) {
          repliesMap
              .putIfAbsent(comment.parentCommentId!, () => [])
              .add(comment);
        }
        // Sort replies
        for (final replies in repliesMap.values) {
          replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        }

        return Column(
          children: topLevelComments.map((comment) {
            final replies = repliesMap[comment.id] ?? [];
            return _buildCommentCard(comment, replies);
          }).toList(),
        );
      },
    );
  }

  Widget _buildCommentCard(ReportComment comment, List<ReportComment> replies) {
    final isLiked = comment.isLikedBy(_currentUserId);
    final isReplying = _replyingToCommentId == comment.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comment header
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.green.shade200,
                  child: Text(
                    comment.userDisplayName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
                        _formatTimeAgo(comment.createdAt),
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
            const SizedBox(height: 10),

            // Comment text
            Text(comment.text, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 10),

            // Action buttons (like, reply)
            Row(
              children: [
                // Like button
                InkWell(
                  onTap: () => _toggleLike(comment.id),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${comment.likeCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isLiked ? Colors.red : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Reply button
                InkWell(
                  onTap: () {
                    setState(() {
                      if (_replyingToCommentId == comment.id) {
                        _replyingToCommentId = null;
                        _replyingToUserName = null;
                      } else {
                        _replyingToCommentId = comment.id;
                        _replyingToUserName = comment.userDisplayName;
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.reply,
                          size: 18,
                          color: isReplying ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            color: isReplying ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Reply count
                if (replies.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Text(
                    '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),

            // Reply input
            if (isReplying) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Replying to ${comment.userDisplayName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            decoration: InputDecoration(
                              hintText: 'Write a reply...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                            maxLines: null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _addReply(comment.id),
                          icon: const Icon(Icons.send, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Replies
            if (replies.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.only(left: 20),
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade300, width: 2),
                  ),
                ),
                child: Column(
                  children: replies
                      .map((reply) => _buildReplyItem(reply))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyItem(ReportComment reply) {
    final isLiked = reply.isLikedBy(_currentUserId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.blue.shade200,
                child: Text(
                  reply.userDisplayName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.userDisplayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(reply.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(reply.text, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _toggleLike(reply.id),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 14,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${reply.likeCount}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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

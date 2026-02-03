import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TrackerRange { day, week, month }

class TrackerTab extends StatefulWidget {
  final String userRole;
  const TrackerTab({super.key, required this.userRole});

  @override
  State<TrackerTab> createState() => _TrackerTabState();
}

class _TrackerTabState extends State<TrackerTab> {
  TrackerRange _selectedRange = TrackerRange.day; // Drivers can change, residents fixed to day (24h)

  bool get _isDriver => widget.userRole == 'Truck Driver';

  void _showDriverForm(BuildContext context) {
    final areaController = TextEditingController();
    String status = 'On Time';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Post Live Update', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: areaController, decoration: const InputDecoration(labelText: 'Area Name')),
            DropdownButtonFormField<String>(
              value: status,
              items: ['On Time', 'Early', 'Late']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => status = val!,
              decoration: const InputDecoration(labelText: 'Current Status'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final now = DateTime.now();
                await FirebaseFirestore.instance.collection('trucks').add({
                  'neighborhood': areaController.text,
                  'status': status,
                  'eta': 'Updated ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
                  'timestamp': FieldValue.serverTimestamp(),
                  'updatedDate': DateFormat('MMMM d, yyyy').format(now),
                });
                Navigator.pop(context);
              },
              child: const Text('Update All Users'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Query<Map<String, dynamic>> _buildQuery() {
    final now = DateTime.now();

    // Residents always see last 24 hours; drivers can pick day/week/month.
    final range = _isDriver ? _selectedRange : TrackerRange.day;

    final start = switch (range) {
      TrackerRange.day => now.subtract(const Duration(days: 1)),
      TrackerRange.week => now.subtract(const Duration(days: 7)),
      TrackerRange.month => now.subtract(const Duration(days: 30)),
    };

    return FirebaseFirestore.instance
        .collection('trucks')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(start))
        .orderBy('timestamp', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _isDriver
          ? FloatingActionButton(onPressed: () => _showDriverForm(context), child: const Icon(Icons.add))
          : null,
      body: Column(
        children: [
          if (_isDriver)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text('Range:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  _RangeChip(
                    label: 'Day',
                    selected: _selectedRange == TrackerRange.day,
                    onTap: () => setState(() => _selectedRange = TrackerRange.day),
                  ),
                  _RangeChip(
                    label: 'Week',
                    selected: _selectedRange == TrackerRange.week,
                    onTap: () => setState(() => _selectedRange = TrackerRange.week),
                  ),
                  _RangeChip(
                    label: 'Month',
                    selected: _selectedRange == TrackerRange.month,
                    onTap: () => setState(() => _selectedRange = TrackerRange.month),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.inbox, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No updates yet')
                      ],
                    ),
                  );
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data();
                    final timestamp = data['timestamp'] as Timestamp?;
                    final timeText = timestamp != null
                        ? '${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                        : (data['eta']?.toString() ?? '');
                    
                    // Get the date - either from stored field or from timestamp
                    String dateText = '';
                    if (data['updatedDate'] != null) {
                      dateText = data['updatedDate'] as String;
                    } else if (timestamp != null) {
                      dateText = DateFormat('MMMM d, yyyy').format(timestamp.toDate());
                    }

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: const Icon(Icons.local_shipping, color: Colors.green),
                        title: Text(data['neighborhood'] ?? 'Unknown area'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${data['status'] ?? 'Unknown'}'),
                            if (dateText.isNotEmpty)
                              Text(
                                'Updated: $dateText',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                        trailing: Text(
                          timeText,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        isThreeLine: dateText.isNotEmpty,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
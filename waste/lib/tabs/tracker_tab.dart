import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
                await FirebaseFirestore.instance.collection('trucks').add({
                  'neighborhood': areaController.text,
                  'status': status,
                  'eta': 'Updated ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  'timestamp': FieldValue.serverTimestamp(),
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
                        ? 'Updated ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                        : (data['eta']?.toString() ?? '');

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: const Icon(Icons.local_shipping, color: Colors.green),
                        title: Text(data['neighborhood'] ?? 'Unknown area'),
                        subtitle: Text('Status: ${data['status'] ?? 'Unknown'}'),
                        trailing: Text(timeText),
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
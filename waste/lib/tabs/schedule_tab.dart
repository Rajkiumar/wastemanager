import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<String, Map<String, dynamic>> _wasteSchedule = {
    'Monday': {'type': 'Organic', 'color': Colors.green, 'icon': Icons.eco},
    'Tuesday': {'type': 'Plastic & Metal', 'color': Colors.yellow.shade700, 'icon': Icons.recycling},
    'Wednesday': {'type': 'Organic', 'color': Colors.green, 'icon': Icons.eco},
    'Thursday': {'type': 'Paper & Cardboard', 'color': Colors.blue, 'icon': Icons.description},
    'Friday': {'type': 'Organic', 'color': Colors.green, 'icon': Icons.eco},
    'Saturday': {'type': 'Glass & Electronics', 'color': Colors.purple, 'icon': Icons.electrical_services},
    'Sunday': {'type': 'No Collection', 'color': Colors.grey, 'icon': Icons.block},
  };

  Map<String, dynamic>? _getWasteTypeForDay(DateTime day) {
    String dayName = DateFormat('EEEE').format(day);
    return _wasteSchedule[dayName];
  }

  Future<void> _toggleNotifications(bool enable) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'notifications_enabled': enable}, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enable 
              ? 'Notifications enabled! You\'ll receive reminders.' 
              : 'Notifications disabled.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating notifications: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Calendar Widget
          TableCalendar(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2040, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: const TextStyle(color: Colors.red),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final wasteInfo = _getWasteTypeForDay(date);
                if (wasteInfo != null && wasteInfo['type'] != 'No Collection') {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: wasteInfo['color'],
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const Divider(),
          
          // Notification Settings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                bool notificationsEnabled = false;
                if (snapshot.hasData && snapshot.data!.exists) {
                  notificationsEnabled = snapshot.data!.get('notifications_enabled') ?? false;
                }
                
                return Card(
                  child: SwitchListTile(
                    title: const Text('Reminder Notifications'),
                    subtitle: const Text('Get alerts the night before pickup'),
                    value: notificationsEnabled,
                    onChanged: _toggleNotifications,
                    secondary: const Icon(Icons.notifications_active, color: Colors.green),
                  ),
                );
              },
            ),
          ),

          // Selected Day Details
          if (_selectedDay != null) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Collection Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: _buildSelectedDayInfo(),
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Weekly Collection Schedule',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: _buildWeeklySchedule(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedDayInfo() {
    final wasteInfo = _getWasteTypeForDay(_selectedDay!);
    if (wasteInfo == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              wasteInfo['icon'],
              size: 60,
              color: wasteInfo['color'],
            ),
            const SizedBox(height: 16),
            Text(
              DateFormat('EEEE, MMMM d').format(_selectedDay!),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              wasteInfo['type'],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: wasteInfo['color'],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Collection Time:', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('7:00 AM - 9:00 AM'),
              ],
            ),
            const SizedBox(height: 8),
            if (wasteInfo['type'] != 'No Collection')
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Place your bin at the curb by 7:00 AM',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _wasteSchedule.length,
      itemBuilder: (context, index) {
        final entry = _wasteSchedule.entries.elementAt(index);
        final dayName = entry.key;
        final info = entry.value;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: info['color'],
              child: Icon(info['icon'], color: Colors.white),
            ),
            title: Text(
              dayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(info['type']),
            trailing: const Text(
              '7:00 AM',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}
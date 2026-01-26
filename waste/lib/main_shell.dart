import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'tabs/report_tab.dart';
import 'tabs/schedule_tab.dart';
import 'tabs/tracker_tab.dart';
import 'tabs/education_tab.dart';

class MainScreenShell extends StatefulWidget {
  const MainScreenShell({super.key, required this.role});

  final String role;

  @override
  State<MainScreenShell> createState() => _MainScreenShellState();
}

class _MainScreenShellState extends State<MainScreenShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      TrackerTab(userRole: widget.role),
      const ScheduleTab(),
      const ReportTab(),
      const EducationTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('WasteWise - ${widget.role} View'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Live Tracker'),
          NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.report), label: 'Report'),
          NavigationDestination(icon: Icon(Icons.school), label: 'Education'),
        ],
      ),
    );
  }
}
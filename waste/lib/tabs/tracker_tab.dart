import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TrackerTab extends StatelessWidget {
  final String userRole;
  const TrackerTab({super.key, required this.userRole});

  void _showDriverForm(BuildContext context) {
    final areaController = TextEditingController();
    String status = "On Time";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Post Live Update", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: areaController, decoration: const InputDecoration(labelText: "Area Name")),
            DropdownButtonFormField<String>(
              value: status,
              items: ["On Time", "Early", "Late"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => status = val!,
              decoration: const InputDecoration(labelText: "Current Status"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('trucks').add({
                  'neighborhood': areaController.text,
                  'status': status,
                  'eta': "Updated ${DateTime.now().hour}:${DateTime.now().minute}",
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              },
              child: const Text("Update All Users"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The Floating Action Button ONLY appears if logged in as Truck Driver
      floatingActionButton: userRole == "Truck Driver" 
          ? FloatingActionButton(onPressed: () => _showDriverForm(context), child: const Icon(Icons.add)) 
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('trucks').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.local_shipping, color: Colors.green),
                  title: Text(doc['neighborhood']),
                  subtitle: Text("Status: ${doc['status']}"),
                  trailing: Text(doc['eta']),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
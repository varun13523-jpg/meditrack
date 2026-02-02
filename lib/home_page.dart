import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Required for the instant test
import 'add_medicine_page.dart';
import 'notification_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Access the plugin directly for the instant test button
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediTrack Dashboard'),
        actions: [
          // 🔔 INSTANT TEST BUTTON: Fires a notification immediately
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.amber),
            onPressed: () async {
              const androidDetails = AndroidNotificationDetails(
                'meditrack_alerts',
                'Medicine Alerts',
                importance: Importance.max,
                priority: Priority.high,
              );

              await _notificationsPlugin.show(
                888,
                'Instant Test! 🔔',
                'If you see this, the notification system is working!',
                const NotificationDetails(android: androidDetails),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Instant test notification sent!'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicinePage()),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('medicines')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No medicines added yet 💊',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final medicines = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final data = medicines[index].data() as Map<String, dynamic>;
              final docId = medicines[index].id;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(
                    Icons.medication,
                    color: Colors.deepPurple,
                  ),
                  title: Text(
                    data['medicineName'] ?? 'No Name',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Dosage: ${data['dosage']}"),
                      Text("Time: ${data['time']}"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('medicines')
                          .doc(docId)
                          .delete();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

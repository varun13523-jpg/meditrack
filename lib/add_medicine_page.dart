import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final medicineController = TextEditingController();
  final dosageController = TextEditingController();
  TimeOfDay? selectedTime;
  bool loading = false;

  Future<void> addMedicine() async {
    if (medicineController.text.isEmpty ||
        dosageController.text.isEmpty ||
        selectedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final now = DateTime.now();

      // Combine today's date with selected time
      DateTime reminderTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      // If time already passed today, set for tomorrow
      if (reminderTime.isBefore(now)) {
        reminderTime = reminderTime.add(const Duration(days: 1));
      }

      // 1. Save to Firestore
      await FirebaseFirestore.instance.collection('medicines').add({
        'medicineName': medicineController.text.trim(),
        'dosage': dosageController.text.trim(),
        'time': selectedTime!.format(context),
        'userId': user!.uid,
        'createdAt': Timestamp.now(),
      });

      // 2. Schedule Notification
      await NotificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Medicine Reminder 💊',
        body: 'Time to take ${medicineController.text.trim()}',
        scheduledTime: reminderTime,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Medicine')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: medicineController,
              decoration: const InputDecoration(labelText: 'Medicine Name'),
            ),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(labelText: 'Dosage'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) setState(() => selectedTime = picked);
              },
              child: Text(
                selectedTime == null
                    ? 'Pick Time'
                    : 'Time: ${selectedTime!.format(context)}',
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: loading ? null : addMedicine,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Save Medicine'),
            ),
          ],
        ),
      ),
    );
  }
}

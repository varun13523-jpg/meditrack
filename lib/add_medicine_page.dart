import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final TextEditingController medicineController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();

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

      final reminderTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      // 🔹 Save to Firestore
      await FirebaseFirestore.instance.collection('medicines').add({
        'medicineName': medicineController.text.trim(),
        'dosage': dosageController.text.trim(),
        'time': selectedTime!.format(context),
        'userId': user!.uid,
        'createdAt': Timestamp.now(),
      });

      // 🔔 Schedule notification
      await NotificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Medicine Reminder 💊',
        body: 'Time to take ${medicineController.text.trim()}',
        time: reminderTime,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine added successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      // 🔥 FIXES INFINITE LOADING
      if (mounted) {
        setState(() => loading = false);
      }
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
            const SizedBox(height: 12),
            TextField(
              controller: dosageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Dosage'),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (picked != null) {
                  setState(() => selectedTime = picked);
                }
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

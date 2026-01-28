import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final TextEditingController medicineController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  bool loading = false;

  Future<void> addMedicine() async {
    if (medicineController.text.isEmpty ||
        dosageController.text.isEmpty ||
        timeController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => loading = true);

    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection('medicines').add({
      'medicineName': medicineController.text.trim(),
      'dosage': dosageController.text.trim(),
      'time': timeController.text.trim(),
      'frequency': 'daily',
      'active': true,
      'userId': user!.uid,
      'createdAt': Timestamp.now(),
    });

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Medicine added successfully")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Medicine")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: medicineController,
              decoration: const InputDecoration(labelText: "Medicine Name"),
            ),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(labelText: "Dosage"),
            ),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: "Time (08:00 AM)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : addMedicine,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Save Medicine"),
            ),
          ],
        ),
      ),
    );
  }
}

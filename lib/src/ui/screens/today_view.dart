import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class todayView extends StatefulWidget {
  const todayView({super.key});

  @override
  State<todayView> createState() => _todayViewState();
}

class _todayViewState extends State<todayView> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user.email!}',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            const Text(
              'This is the content of View 1.',
              style: TextStyle(fontSize: 18),
            ),
            // Add more content for View 1 here
          ],
        ),
      ),
    );
  }
}

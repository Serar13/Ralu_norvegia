import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_router.dart';

class ChooseOptionScreen extends StatelessWidget {
  final String userId;

  const ChooseOptionScreen({Key? key, required this.userId}) : super(key: key);

  Map<String, String?> get defaultPlan => {
    "Luni": "Dormitor",
    "Marti": "Bucătărie",
    "Miercuri": "Living",
    "Joi": "Baie",
    "Vineri": "Birou",
    "Sambata": "Dormitor copii",
    "Duminica": "relax",
  };


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Option'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Please choose an option:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select "Basic" for a standard setup or "Custom" to personalize your experience.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Navigate to Basic screen
                // Navigator.pushNamed(context, '/basic');
                GoRouter.of(context).go(ReviewChosePath, extra: {
                  'optionType': 'basic',
                  'weekPlan': defaultPlan,
                  'userId': userId,
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text(
                'Basic',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to Custom screen
                GoRouter.of(context).go(
                    RoomsHousePath,
                  extra: {
                    'userId': userId, // Include userId here
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Custom',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
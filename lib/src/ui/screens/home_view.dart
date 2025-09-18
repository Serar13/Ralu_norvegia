import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/ui/screens/calendar_view.dart';
import 'package:ralu_norvegia/src/ui/screens/daily_view.dart';
import 'package:ralu_norvegia/src/ui/screens/today_view.dart';

class homeView extends StatefulWidget {
  const homeView({super.key});

  @override
  State<homeView> createState() => _homeViewState();
}

class _homeViewState extends State<homeView> with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser!;
  late TabController _tabController;
  ValueNotifier<int> pointsNotifier = ValueNotifier<int>(0); // ValueNotifier to track points
  final ValueNotifier<DateTime?> _selectedDateNotifier = ValueNotifier<DateTime?>(null);
  ValueNotifier<int> streakNotifier = ValueNotifier<int>(0);

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        int points = doc.data()?['points'] ?? 0;
        int streak = doc.data()?['streakCount'] ?? 0;

        pointsNotifier.value = points; // Update the ValueNotifier
        streakNotifier.value = streak;
      } else {
        pointsNotifier.value = 0;
        streakNotifier.value = 0;
      }
    } catch (e) {
      print("Failed to load user data: $e");
    }
  }

  @override
  void initState() {
    _loadUserData();
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    pointsNotifier.dispose(); // Dispose of the ValueNotifier when not needed
    streakNotifier.dispose();
    _selectedDateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.info, color: AppColors.accent3,),
          onPressed: () {
            GoRouter.of(context).push(aboutPath);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0,  vertical: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
              decoration: BoxDecoration(
                color: AppColors.accent3,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.white, size: 16.0),
                  const SizedBox(width: 4.0),
                  ValueListenableBuilder<int>(
                    valueListenable: streakNotifier, // folosim streak-ul în loc de points
                    builder: (context, streak, _) {
                      return Text(
                        streak.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 16.0),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: AppColors.accent3),
            onPressed: () async {
              final picked = await Navigator.of(context).push<DateTime>(
                MaterialPageRoute(builder: (_) => const CalendarWeekView()),
              );
              if (picked != null) {
                _selectedDateNotifier.value = picked;
                // comută pe tab-ul Today
                _tabController.index = 0;
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: AppColors.accent3),
            onPressed: () {
              GoRouter.of(context).push(userProfilePath);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent3,
          labelColor: AppColors.accent3,
          unselectedLabelColor: AppColors.accent3.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Ukentlig'),
            Tab(text: 'Daglige gjøremål'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TodayView(selectedDateNotifier: _selectedDateNotifier),
          dailyView(pointsNotifier: pointsNotifier), // Pass the pointsNotifier to dailyView
        ],
      ),
    );
  }
}

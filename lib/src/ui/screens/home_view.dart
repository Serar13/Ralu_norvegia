import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/ui/screens/calendar_view.dart';
import 'package:ralu_norvegia/src/ui/screens/daily_view.dart';
import 'package:ralu_norvegia/src/ui/screens/today_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/streak_utils.dart';

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
  bool _pulse = false;
  bool isLoading = true;

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    // Load cached streak if exists
    final cachedStreak = prefs.getInt('lastStreak');
    if (cachedStreak != null) {
      streakNotifier.value = cachedStreak;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        int points = doc.data()?['points'] ?? 0;
        pointsNotifier.value = points;

        final streak = await calculateStreak(user.uid);
        streakNotifier.value = streak;
        await prefs.setInt('lastStreak', streak);
      } else {
        pointsNotifier.value = 0;
        streakNotifier.value = 0;
      }
    } catch (e) {
      print("Failed to load user data: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _tabController = TabController(length: 2, vsync: this);

    // animație "pulse" mai energică și random
    _startRandomPulse();
  }

  void _startRandomPulse() {
    Future.delayed(const Duration(seconds: 2), () async {
      while (mounted) {
        // Așteaptă o perioadă random între 3 și 7 secunde
        await Future.delayed(Duration(seconds: 3 + (4 * (0.5 + (0.5 - (DateTime.now().millisecond % 1000) / 1000))).toInt()));
        if (!mounted) break;

        // Pulse rapid, ca în desene animate
        for (int i = 0; i < 2; i++) {
          if (!mounted) return;
          setState(() => _pulse = true);
          await Future.delayed(const Duration(milliseconds: 150));
          setState(() => _pulse = false);
          await Future.delayed(const Duration(milliseconds: 150));
        }
      }
    });
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
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.info, color: AppColors.accentDark),
          onPressed: () {
            GoRouter.of(context).push(aboutPath);
          },
        ),
        title: Text(
          'Vaskmedmeg',
          style: TextStyle(
            color: AppColors.accentDark,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0,  vertical: 10.0),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: Dialog(
                      backgroundColor: AppColors.secondary.withOpacity(0.95),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(color: AppColors.accent3.withOpacity(0.6), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryBackground,
                                AppColors.primary.withOpacity(0.6)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department, color: AppColors.accent3, size: 60),
                              const SizedBox(height: 10),
                              const Text(
                                "🔥 Punctele tale",
                                style: TextStyle(
                                  fontSize: 24,
                                  color: AppColors.accent3,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Kanit',
                                ),
                              ),
                              const SizedBox(height: 10),
                              ValueListenableBuilder<int>(
                                valueListenable: pointsNotifier,
                                builder: (context, points, _) {
                                  return Text(
                                    "Ai $points puncte acum!",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: AppColors.accent3,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Continuă să faci activități zilnice pentru a câștiga mai multe puncte și a-ți crește streak-ul! 💪",
                                style: TextStyle(
                                  color: AppColors.primaryText2,
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => launchUrl(Uri.parse("https://ralu-norvegia.com")),
                                icon: const Icon(Icons.public, color: Colors.white),
                                label: const Text(
                                  "Vizitează site-ul nostru",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  "Închide",
                                  style: TextStyle(
                                    color: AppColors.accentDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: AnimatedScale(
                scale: _pulse ? 1.3 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.elasticOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
                  decoration: BoxDecoration(
                    color: AppColors.accent3,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent3.withOpacity(0.8),
                        blurRadius: _pulse ? 16 : 6,
                        spreadRadius: _pulse ? 3 : 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.white, size: 18.0),
                      const SizedBox(width: 4.0),
                      ValueListenableBuilder<int>(
                        valueListenable: streakNotifier,
                        builder: (context, streak, _) {
                          if (isLoading) {
                            return const Text(
                              "–",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17.0,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                          return Text(
                            streak.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17.0,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.orangeAccent,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: AppColors.accentDark),
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
            icon: const Icon(Icons.person, color: AppColors.accentDark),
            onPressed: () {
              GoRouter.of(context).push(userProfilePath);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.transparent,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent3,
              indicatorWeight: 3,
              labelColor: AppColors.accent3,
              unselectedLabelColor: AppColors.accentDark.withOpacity(0.5),
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(text: 'Ukentlig'),
                Tab(text: 'Daglige gjøremål'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TodayView(
            selectedDateNotifier: _selectedDateNotifier,
            streakNotifier: streakNotifier,
          ),
          dailyView(pointsNotifier: pointsNotifier), // Pass the pointsNotifier to dailyView
        ],
      ),
    );
  }
}

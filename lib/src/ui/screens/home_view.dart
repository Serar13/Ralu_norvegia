import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/ui/screens/calendar_view.dart';
import 'package:ralu_norvegia/src/ui/screens/daily_view.dart';
import 'package:ralu_norvegia/src/ui/screens/today_view.dart';
import 'package:ralu_norvegia/src/ui/screens/deep_cleaning_view.dart';
import 'package:ralu_norvegia/src/service/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/streak_utils.dart';

class homeView extends StatefulWidget {
  const homeView({super.key});

  @override
  State<homeView> createState() => _homeViewState();
}

class _homeViewState extends State<homeView> with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  ValueNotifier<int> pointsNotifier = ValueNotifier<int>(0); // ValueNotifier to track points
  final ValueNotifier<DateTime?> _selectedDateNotifier = ValueNotifier<DateTime?>(null);
  ValueNotifier<int> streakNotifier = ValueNotifier<int>(0);
  bool _pulse = false;
  bool isLoading = true;
  bool isGuest = false;
  bool _hasPulsedOnce = false;

  // Profile state
  String _activeProfileEmoji = '🧑';
  String _activeProfileName = '';
  bool _isActiveProfileAdmin = false;

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    // Load cached streak if exists
    final cachedStreak = prefs.getInt('lastStreak');
    if (cachedStreak != null) {
      streakNotifier.value = cachedStreak;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        int points = doc.data()?['points'] ?? 0;
        pointsNotifier.value = points;

        final streak = await calculateStreak(user!.uid);
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

  Future<void> initNotifications(BuildContext context) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          final snackBar = SnackBar(
            content: Text(message.notification!.title ?? 'Ny melding'),
            duration: const Duration(seconds: 3),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    () async {
      final prefs = await SharedPreferences.getInstance();
      isGuest = prefs.getBool('isGuest') ?? false;
      if (!isGuest && user != null) {
        _loadUserData();
        _loadActiveProfile();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSinglePulseOnce();
      if (!isGuest && user != null) {
        initNotifications(context);
      }
    });
  }

  void _showGuestLockDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ICON
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accent3.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 38,
                  color: AppColors.accent3,
                ),
              ),

              const SizedBox(height: 20),

              // TITLE
              const Text(
                'Krever konto',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentDark,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // DESCRIPTION
              const Text(
                'For å låse opp denne delen av appen og lagre fremgangen din, må du opprette en konto eller logge inn.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.primaryText2,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // PRIMARY CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    GoRouter.of(context).go(loginPath);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent3,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Logg inn / Opprett konto',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // SECONDARY CTA
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Ikke nå',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accentDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadActiveProfile() async {
    final emoji = await ProfileService.getActiveProfileEmoji();
    final name = await ProfileService.getActiveProfileName();
    final isAdmin = await ProfileService.isActiveProfileAdmin();
    if (mounted) {
      setState(() {
        _activeProfileEmoji = emoji ?? '🧑';
        _activeProfileName = name ?? '';
        _isActiveProfileAdmin = isAdmin;
      });
    }
  }

  void _startSinglePulseOnce() async {
    if (_hasPulsedOnce) return;
    _hasPulsedOnce = true;

    await Future.delayed(const Duration(seconds: 2));

    for (int i = 0; i < 2; i++) {
      if (!mounted) return;
      setState(() => _pulse = true);
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() => _pulse = false);
      await Future.delayed(const Duration(milliseconds: 150));
    }
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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Vaskmedmeg',
            style: TextStyle(
              color: AppColors.accentDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
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
                                "🔥 Poengene dine",
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
                                    "Du har $points poeng nå!",
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
                                "Fortsett å gjøre dine daglige oppgaver for å tjene flere poeng og øke streaken din! 💪",
                                style: TextStyle(
                                  color: AppColors.primaryText2,
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => launchUrl(Uri.parse("https://vaskmedmeg.no/")),
                                icon: const Icon(Icons.public, color: Colors.white),
                                label: const Text(
                                  "Besøk nettsiden vår",
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
                                  "Lukk",
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
              if (isGuest) {
                _showGuestLockDialog();
                return;
              }

              final picked = await Navigator.of(context).push<DateTime>(
                MaterialPageRoute(builder: (_) => const CalendarWeekView()),
              );
              if (picked != null) {
                _selectedDateNotifier.value = picked;
                _tabController.index = 0;
              }
            },
          ),
          if (_isActiveProfileAdmin)
            IconButton(
              icon: const Icon(Icons.assignment_ind_rounded, color: AppColors.accentDark),
              tooltip: 'Deleger oppgaver',
              onPressed: () {
                GoRouter.of(context).push(delegateTasksPath);
              },
            ),
          if (!_isActiveProfileAdmin && !isGuest)
            IconButton(
              icon: const Icon(Icons.task_alt_rounded, color: AppColors.accentDark),
              tooltip: 'Mine oppgaver',
              onPressed: () {
                GoRouter.of(context).push(myTasksPath);
              },
            ),
          GestureDetector(
            onTap: () {
              if (isGuest) {
                _showGuestLockDialog();
                return;
              }
              _showProfileMenu();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.accent3,
                child: Text(
                  _activeProfileEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
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
                Tab(text: 'Dyp rengjøring'),
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
          const DeepCleaningView(),
        ],
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.accent3.withOpacity(0.15),
              child: Text(
                _activeProfileEmoji,
                style: const TextStyle(fontSize: 36),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _activeProfileName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.accentDark,
              ),
            ),
            if (_isActiveProfileAdmin)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent3.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Administrator',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent3,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            _profileMenuItem(
              icon: Icons.swap_horiz_rounded,
              label: 'Bytt profil',
              onTap: () {
                Navigator.pop(context);
                GoRouter.of(context).go(profileSelectionPath);
              },
            ),
            _profileMenuItem(
              icon: Icons.person_outline,
              label: 'Brukerprofil',
              onTap: () {
                Navigator.pop(context);
                GoRouter.of(context).push(userProfilePath);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _profileMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent3),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.accentDark,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: AppColors.primaryBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

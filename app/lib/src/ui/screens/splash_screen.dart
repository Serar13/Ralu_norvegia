import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ralu_norvegia/src/service/profile_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  Future<void> _navigateAfterDelay(String path) async {
    if (_hasNavigated || !mounted) return;

    // verificăm dacă deja suntem pe RoomsSetup (venim din signup)
    final currentPath = GoRouterState.of(context).uri.toString();
    if (currentPath == RoomsSetupPath) return;

    _hasNavigated = true;

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) GoRouter.of(context).go(path);
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _checkFirstLaunch();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (_hasNavigated || !mounted) return;

    if (!hasSeenOnboarding) {
      _hasNavigated = true;
      await prefs.setBool('hasSeenOnboarding', true);
      if (mounted) {
        await Future.delayed(const Duration(seconds: 2));
        GoRouter.of(context).go(onboardingPath);
      }
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['hasCompletedSetup'] == true) {
          // Check if user has family profiles → go to profile selection
          final hasProfiles = await ProfileService.hasProfiles(user.uid);
          if (hasProfiles) {
            await _navigateAfterDelay(profileSelectionPath);
          } else {
            // First time: go to profile selection which will prompt to create first profile
            await _navigateAfterDelay(profileSelectionPath);
          }
        } else {
          await _navigateAfterDelay(RoomsSetupPath);
        }
      } else {
        await _navigateAfterDelay(welcomePath);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {

          }

          return Container(
            color: AppColors.primary,
            child: Center(
              child: Image.asset(
                'assets/aboutUs-removebg-preview.png',
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
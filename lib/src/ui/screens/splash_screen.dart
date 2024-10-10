import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Dacă există un utilizator autentificat, navighează la HomePage
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              Future.delayed(const Duration(seconds: 2), () {
                GoRouter.of(context).push(homePath);
              });
            } else {
              Future.delayed(const Duration(seconds: 2), () {
                GoRouter.of(context).push(welcomePath);
              });
            }
          }

          return Container(
            color: AppColors.primary,
            child: const Center(
              child: Text(
                "welcome",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

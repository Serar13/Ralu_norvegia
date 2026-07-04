import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/service/auth_service.dart';
import 'package:ralu_norvegia/src/service/profile_service.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({Key? key}) : super(key: key);

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> with SingleTickerProviderStateMixin {
  double _opacity = 0.0;
  bool _isFbLoading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  Future<void> _handlePostLogin(User? user) async {
    if (user == null) return;
    
    // Save in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', false);

    bool isSetupDone = false;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = userDoc.data();
      if (data != null) {
        isSetupDone = (data['hasCompletedSetup'] == true) || (data['setupDone'] == true);
      }

      // Migration check
      if (!isSetupDone) {
        final luniDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('weeklyTasks')
            .doc('Uke 1')
            .collection('days')
            .doc('Luni')
            .get();
        if (luniDoc.exists) {
          isSetupDone = true;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'setupDone': true, 'hasCompletedSetup': true}, SetOptions(merge: true));
        }
      }
    } catch (_) {}

    if (!mounted) return;
    if (isSetupDone) {
      await ProfileService.ensureAdminProfileExists(user.uid);
      if (mounted) context.go(profileSelectionPath);
    } else {
      context.go(RoomsSetupPath);
    }
  }

  Future<void> _loginWithFacebook() async {
    if (_isFbLoading) return;

    setState(() {
      _isFbLoading = true;
    });

    try {
      final userCredential = await AuthService.signInWithFacebook();
      if (userCredential != null) {
        await _handlePostLogin(userCredential.user);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Facebook login feilet: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFbLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryBackground,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                child: Text(
                  "La oss starte!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.accentDark,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "vaskmedmeg",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryText.withValues(alpha: 0.6),
                  fontSize: 34,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 60),
              GestureDetector(
                onTap: () {
                  GoRouter.of(context).push(singinPath);
                },
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.accent3],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent3.withValues(alpha: 0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Fortsett med e-post",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Divider "eller"
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.grey.withValues(alpha: 0.3),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "eller",
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.grey.withValues(alpha: 0.3),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Facebook Button
              GestureDetector(
                onTap: _loginWithFacebook,
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1877F2),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1877F2).withValues(alpha: 0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _isFbLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.facebook, color: Colors.white, size: 24),
                            SizedBox(width: 12),
                            Text(
                              "Fortsett med Facebook",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Har du allerede en konto?",
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      GoRouter.of(context).push(loginPath);
                    },
                    child: Text(
                      "Logg inn",
                      style: TextStyle(
                        color: AppColors.accent3,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

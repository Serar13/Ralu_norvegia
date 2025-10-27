import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/ui/widgets/validators.dart';
import 'package:ralu_norvegia/src/ui/widgets/widget_factory.dart';

class logInView extends StatefulWidget {
  const logInView({super.key});

  @override
  State<logInView> createState() => _logInViewState();
}

class _logInViewState extends State<logInView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool passToggle = true;
  bool _isLoading = false;
  final formFieldKey = GlobalKey<FormState>();

  get userId => "0";

  void togglePasswordVisibility() {
    setState(() {
      passToggle = !passToggle;
    });
  }

  Future<void> _logIn() async {
    if (formFieldKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_emailController.text == 'admin' && _passwordController.text == 'admin') {
          // Admin login: Navigate to admin page
          GoRouter.of(context).go(adminPath);
        } else {
          // Regular user login
          final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

          final User? user = userCredential.user;
          if (user != null) {
            await _postLoginRoute(); // migrare + lasă redirect-ul să decidă
          }
        }
      } on FirebaseAuthException catch (e) {
        // Display error message if login fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /*
  Future<void> _sendVerificationEmail(User user) async {
    try {
      await user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent. Please check your inbox (and spam).')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send verification email: $e')),
        );
      }
    }
  }

  Future<void> _resendVerificationWithCredentials() async {
    if ((_emailController.text).isEmpty || (_passwordController.text).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email and password first.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      final u = cred.user;
      if (u != null && !u.emailVerified) {
        await _sendVerificationEmail(u);
      } else if (u != null && u.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This email is already verified.')),
        );
      }
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to resend verification email.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  */


  Future<void> _postLoginRoute() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .get();
      final setupDone = (userDoc.data()?['setupDone'] == true);

      // Migrare: dacă userul are deja weeklyTasks (legacy) dar setupDone e fals, îl setăm true
      if (!setupDone) {
        final luniDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(u.uid)
            .collection('weeklyTasks')
            .doc('Uke 1')
            .collection('days')
            .doc('Luni')
            .get();
        if (luniDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(u.uid)
              .set({'setupDone': true}, SetOptions(merge: true));
        }
      }
    } catch (_) {
      // ignorăm erorile de migrare – redirect-ul tot va decide corect
    }

    if (!mounted) return;
    // Trimitem spre home; dacă setupDone e fals, redirect-ul din AppRouter te duce singur la RoomsSetup
    context.go(homePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: formFieldKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.accent3],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 60),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Log in to continue your clean streak",
                    style: TextStyle(
                      color: AppColors.primaryText2,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  WidgetFactory.makeInput(
                    label: "Email",
                    contex: context,
                    controller: _emailController,
                    validator: EmailValidator(),
                  ),
                  WidgetFactory.makeInputPassword(
                    label: "Password",
                    contex: context,
                    obscureText: passToggle,
                    passToggle: passToggle,
                    controller: _passwordController,
                    validator: PasswordValidator(),
                    togglePasswordVisibility: togglePasswordVisibility,
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : GestureDetector(
                          onTap: _logIn,
                          child: Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.accent3],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: AppColors.primaryText2),
                      ),
                      GestureDetector(
                        onTap: () => GoRouter.of(context).push(singinPath),
                        child: Text(
                          "Sign up",
                          style: TextStyle(
                            color: AppColors.accent3,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

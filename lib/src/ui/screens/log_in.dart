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
coment           // EMAIL VERIFICATION CHECK TEMPORARILY DISABLED – allow login regardless of verification state
          if (user != null) {
            await checkUserTasks(user.uid, context);
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


  Future<void> checkUserTasks(String userId, BuildContext context) async {
    try {
      print("Verific userId: $userId"); // Debugging
      final weeklyTasksRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('weeklyTasks');

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('weeklyTasks')
          .doc('Uke 1')
          .collection('days')
          .doc('Luni');

      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        print('Document exists: ${docSnapshot.data()}');
        GoRouter.of(context).go(homePath);
      } else {
        print('Document does not exist');
        GoRouter.of(context).go(ChooseOptionPath, extra: {'userId': userId});
      }
    } catch (e) {
      print("Eroare în checkUserTasks: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: MediaQuery.of(context).size.height,
              width: double.infinity,
              color: AppColors.primary,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3), // Shadow color
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 5), // Shadow offset
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 75,
                      backgroundColor: AppColors.secondaryBackground, // White background
                      child: Icon(
                        Icons.person,
                        size: 90,
                        color: AppColors.accent3, // Green color for icon
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: formFieldKey,
                      child: Column(
                        children: [
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                child: Text(
                                  "Forgot Password",
                                  style: TextStyle(
                                  decoration: TextDecoration.none,
                                    color: AppColors.accent3,
                                    fontSize: 16,
                                  ),
                                ),
                                onTap: () {
                                  GoRouter.of(context).push(forgotPasswordPagePath);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 25),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : WidgetFactory.buttonWithTextIcon(
                          "Login",
                          55,
                          double.infinity,
                          1.0,
                          AppColors.accent3,
                          Colors.white,
                          2,
                          Colors.white,
                          null,
                          _logIn, // Login function
                        ),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Do not have an account?",
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              child: Text(
                                "Sign in",
                                style: TextStyle(
                                  decoration: TextDecoration.none,
                                  color: AppColors.accent3,
                                  fontSize: 16,
                                ),
                              ),
                              onTap: () {
                                GoRouter.of(context).push(singinPath);
                                // GoRouter.of(context).go(ChooseOptionPath, extra: {'userId': userId});
                                // GoRouter.of(context).push(RoomsSetupPath);
                              },
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

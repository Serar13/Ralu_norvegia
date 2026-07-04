import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';

class waitingForVerificationEditView extends StatefulWidget {
  const waitingForVerificationEditView({super.key});

  @override
  State<waitingForVerificationEditView> createState() => _waitingForVerificationEditViewState();
}

class _waitingForVerificationEditViewState extends State<waitingForVerificationEditView> {
  bool _isEmailVerified = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();
  }

  Future<void> _checkEmailVerified() async {
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload(); // Refresh user state to check email verification
    setState(() {
      _isEmailVerified = user?.emailVerified ?? false;
    });

    if (_isEmailVerified) {
      _completeRegistration();
    }
  }

  Future<void> _completeRegistration() async {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    // Retrieve existing user details to update Firestore
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'email': user.email, // Ensure the updated email is stored in Firestore
      });
    }

    // Navigate to the home screen after completing registration
    GoRouter.of(context).go(homePath);
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification(); // Send email verification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification email sent. Please check your inbox.')),
      );
    } catch (e) {
      print('Error sending verification email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send verification email: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        backgroundColor: AppColors.primary,
      ),
      body: Center(
        child: _isEmailVerified
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Please verify your email to continue.'),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _resendVerificationEmail,
                          child: const Text('Resend Verification Email'),
                        ),
                ],
              ),
      ),
    );
  }
}

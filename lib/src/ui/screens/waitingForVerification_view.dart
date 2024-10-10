import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';

import '../../theme/app_colors.dart';

class waitingForVerificationView extends StatefulWidget {
  const waitingForVerificationView({super.key});

  @override
  State<waitingForVerificationView> createState() => _waitingForVerificationViewState();
}

class _waitingForVerificationViewState extends State<waitingForVerificationView> {
  bool _isEmailVerified = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();
  }

  Future<void> _checkEmailVerified() async {
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    setState(() {
      _isEmailVerified = user?.emailVerified ?? false;
    });

    if (_isEmailVerified) {
      _completeRegistration();
    }
  }

  Future<void> _completeRegistration() async {
    // Add user details to Firestore
    await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).set({
      'first name': 'First Name',
      'last name': 'Last Name',
      'email': 'Email',
      'phone number': 1234567890,
      'points': 0,
    });

    // Navigate to the home screen
    GoRouter.of(context).go(homePath);
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification email sent. Please check your inbox.')),
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
        title: Text('Email Verification'),
        backgroundColor: AppColors.primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isEmailVerified
                ? CircularProgressIndicator()
                : Column(
              children: [
                Text('Please verify your email to continue.'),
                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _resendVerificationEmail,
                  child: Text('Resend Verification Email'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
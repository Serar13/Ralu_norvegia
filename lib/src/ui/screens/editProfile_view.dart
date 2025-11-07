import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/ui/widgets/widget_factory.dart';

class EditProfileView extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileView({required this.userData, super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.userData['first name'] ?? '';
    _lastNameController.text = widget.userData['last name'] ?? '';
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Update first and last name in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'first name': _firstNameController.text,
          'last name': _lastNameController.text,
        });

        // Notify user of success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        // Navigate back to the profile screen
        GoRouter.of(context).pop();
      }
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: AppColors.accent3)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: AppColors.accent3),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            WidgetFactory.makeInput(
              label: "Fornavn",
              contex: context,
              controller: _firstNameController,
              validator: null,
            ),
            WidgetFactory.makeInput(
              label: "Etternavn",
              contex: context,
              controller: _lastNameController,
              validator: null,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : WidgetFactory.buttonWithTextIcon(
              "Lagre",
              55,
              double.infinity,
              1.0,
              AppColors.accent3,
              Colors.white,
              2,
              Colors.white,
              null,
              _saveProfile,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/ui/widgets/widget_factory.dart';

class userProfileView extends StatefulWidget {
  const userProfileView({super.key});

  @override
  State<userProfileView> createState() => _userProfileViewState();
}

class _userProfileViewState extends State<userProfileView> {
  final user = FirebaseAuth.instance.currentUser!;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to re-authenticate the user before deleting the account
  Future<void> _reauthenticateAndDelete() async {
    String email = user.email!;
    String? password; // You may need to get the password from the user.

    await showDialog(
      context: context,
      builder: (context) {
        TextEditingController passwordController = TextEditingController();

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [AppColors.primaryBackground, AppColors.secondaryBackground],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Bekreft passord",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.accent3,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Skriv inn passordet ditt",
                        hintStyle: TextStyle(color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            "Avbryt",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            password = passwordController.text;
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            "Bekreft",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (password == null || password!.isEmpty) {
      // If no password is entered, don't proceed.
      return;
    }

    // Re-authenticate the user
    try {
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: password!);
      await user.reauthenticateWithCredential(credential);

      // Once re-authenticated, proceed with account deletion
      _deleteAccount();
    } catch (e) {
      // Handle re-authentication failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Re-authentication failed: $e')),
      );
    }
  }

  // Function to delete the user's account
  void _deleteAccount() async {
    final confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        await user.delete();
        GoRouter.of(context).go(welcomePath);
      } catch (e) {
        print("Error deleting account: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }

  // Function to logout the user
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    GoRouter.of(context).go(welcomePath);
  }

  // Function to navigate to the edit profile screen
  void _editProfile() {
    GoRouter.of(context).push(editProfilePath, extra: userData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          "Brukerprofil",
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.secondary,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: AppColors.accent3),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryBackground,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 40,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                        child: isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.accent3,
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 75,
                                      backgroundColor: AppColors.secondaryBackground,
                                      child: Icon(
                                        Icons.person,
                                        size: 90,
                                        color: AppColors.accent3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Fornavn: ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.accent3,
                                            ),
                                          ),
                                          Text(
                                            userData?['first name'] ?? "Not available",
                                            style: const TextStyle(color: AppColors.primaryText),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Etternavn: ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.accent3,
                                            ),
                                          ),
                                          Text(
                                            userData?['last name'] ?? "Not available",
                                            style: const TextStyle(color: AppColors.primaryText),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'E-post: ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.accent3,
                                            ),
                                          ),
                                          Text(
                                            user.email ?? "",
                                            style: const TextStyle(color: AppColors.primaryText),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Telefonnummer: ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.accent3,
                                            ),
                                          ),
                                          Text(
                                            userData?['phone number']?.toString() ?? "Not available",
                                            style: const TextStyle(color: AppColors.primaryText),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 40),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      WidgetFactory.buttonWithTextIcon(
                                        "Rediger profil",
                                        55,
                                        MediaQuery.of(context).size.width,
                                        1,
                                        AppColors.accent3,
                                        AppColors.secondaryText,
                                        2,
                                        AppColors.secondaryText,
                                        null,
                                        _editProfile,
                                      ),
                                      const SizedBox(height: 15),
                                      WidgetFactory.buttonWithTextIcon(
                                        "Slett konto",
                                        55,
                                        MediaQuery.of(context).size.width,
                                        1,
                                        AppColors.accent3,
                                        AppColors.secondaryText,
                                        2,
                                        AppColors.secondaryText,
                                        null,
                                        _reauthenticateAndDelete,
                                      ),
                                      const SizedBox(height: 15),
                                      WidgetFactory.buttonWithTextIcon(
                                        "Logg ut",
                                        55,
                                        MediaQuery.of(context).size.width,
                                        1,
                                        AppColors.accent3,
                                        AppColors.secondaryText,
                                        2,
                                        AppColors.secondaryText,
                                        null,
                                        _logout,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

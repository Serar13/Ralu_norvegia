import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/ui/widgets/validators.dart';
import 'package:ralu_norvegia/src/ui/widgets/widget_factory.dart';

class singInView extends StatefulWidget {
  const singInView({super.key});

  @override
  State<singInView> createState() => _singInViewState();
}

class _singInViewState extends State<singInView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmpasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool passToggle = true;
  bool _isLoading = false;

  void togglePasswordVisibility() {
    setState(() {
      passToggle = !passToggle;
    });
  }

  Future<void> _register() async {
    if (formFieldKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create user account
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        addUserDetails(
          _firstNameController.text,
          _lastNameController.text,
          _emailController.text,
          int.parse(_phoneNumberController.text),
        );

        // Send verification email
        await userCredential.user?.sendEmailVerification();

        // Show a message to check their email
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please verify your email. Check your inbox.')),
        );

        // Log out user after sending email to prevent access
        await FirebaseAuth.instance.signOut();

        // Navigate to the login screen
        GoRouter.of(context).go(loginPath);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> addUserDetails(
      String firstName, String lastName, String email, int phoneNumber) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Store user details using the UID as the document ID
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'first name': firstName,
      'last name': lastName,
      'email': email,
      'phone number': phoneNumber,
      'points': 0,
    });

    // Initialize sub-collection "completedTasks" with all tasks set to false
    await _initializeCompletedTasksForUser(uid);
  }

  Future<void> _initializeCompletedTasksForUser(String uid) async {
    // Map of rooms and their tasks
    Map<String, List<String>> tasks = {
      'Baderom': [
        'bruk vindusnal på dusjdørene etter dusjing',
        'fei/støvsug/mopp gulvet',
        'sett ting tilbake på plass',
        'ta ut ting som ikke hører hjemme på badet',
        'tørk fort over speil, vask og toalett',
        'åpne vinduene i minst 10 minutter',
      ],
      'Kjøkken': [
        'bruk en glassklut på kokeplata',
        'fei/støvsug/mop gulvet',
        'rydd benkeplater',
        'spray overflater med hverdagsflasken',
        'ta ut søppel',
        'tøm oppvasken',
        'tørk overflater tørre etter vask',
        'åpne vinduene i minst 10 minutter',
      ],
      'Soverom': [
        're opp sengen',
        'ta ut skitne klær or håndklær',
        'ta ut ting som ikke hører hjemme på soverommet',
        'åpne vinduene i minst 10 minutter',
      ],
      'Stue og barnerom': [
        'rydd ting på plass',
        'tørk søl umiddelbart',
        'åpne vinduene i minst 10 minutter',
      ],
      'Inngang': [
        'bruk en håndhelt batteridrevet støvsuger på gulvet',
        'heng jakker or klær tilbake på plass',
        'sett sko tilbake på plass',
        'åpne vinduene i minst 10 minutter',
      ],
    };

    // Iterate over each room and task, and set the task to false (not completed)
    for (var room in tasks.keys) {
      final taskData = {
        for (var task in tasks[room]!) task: false
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('completedTasks')
          .doc(room)
          .set(taskData);
    }
  }

  final formFieldKey = GlobalKey<FormState>();
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
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 75,
                        backgroundColor: AppColors.secondaryBackground,
                        child: Icon(
                          Icons.person_add,
                          size: 90,
                          color: AppColors.accent3,
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
                              label: "First Name",
                              contex: context,
                              controller: _firstNameController,
                              validator: UserNameValidator(),
                            ),
                            WidgetFactory.makeInput(
                              label: "Last Name",
                              contex: context,
                              controller: _lastNameController,
                              validator: UserNameValidator(),
                            ),
                            WidgetFactory.makeInput(
                              label: "Email",
                              contex: context,
                              controller: _emailController,
                              validator: EmailValidator(),
                            ),
                            WidgetFactory.makeInput(
                              label: "Phone Number",
                              contex: context,
                              controller: _phoneNumberController,
                              validator: PhoneNumberValidator(),
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
                            WidgetFactory.makeInputPassword(
                              label: "Password verify",
                              contex: context,
                              obscureText: passToggle,
                              passToggle: passToggle,
                              controller: _confirmpasswordController,
                              validator: ConfirmPasswordValidator(_passwordController),
                              togglePasswordVisibility: togglePasswordVisibility,
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
                              ? CircularProgressIndicator()
                              : WidgetFactory.buttonWithTextIcon(
                            "Sign In",
                            55,
                            double.infinity,
                            1.0,
                            AppColors.accent3,
                            Colors.white,
                            2,
                            Colors.white,
                            null,
                            _register, // Funcția de înregistrare
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Do you have an account?",
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                child: Text(
                                  "Log in",
                                  style: TextStyle(
                                    decoration: TextDecoration.none,
                                    color: AppColors.accent3,
                                    fontSize: 16,
                                  ),
                                ),
                                onTap: () {
                                  GoRouter.of(context).push(loginPath);
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
        ));
  }
}

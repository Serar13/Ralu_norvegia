import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/ui/widgets/validators.dart';
import 'package:ralu_norvegia/src/ui/widgets/widget_factory.dart';
import '../../service/firestore_bootstrap.dart';

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

        final String userId = userCredential.user!.uid;
        print(userId);
        addUserDetails(
          _firstNameController.text,
          _lastNameController.text,
          _emailController.text,
          int.parse(_phoneNumberController.text),
        );

        // EMAIL VERIFICATION TEMPORARILY DISABLED
        // await userCredential.user?.sendEmailVerification();

        // Creează scheletul de Firestore (profil + colecții de bază)
        await FirestoreBootstrap.ensureUserSkeleton(
          uid: userId,
          email: _emailController.text,
        );

        // Mergem direct la RoomsSetup
        GoRouter.of(context).go(RoomsSetupPath);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        print(e.toString());
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
      'streakCount': 0,
      'lastActiveDay': null,
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
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 36.0),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
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
                      child: const Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Opprett konto",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Bli med i Vaskmedmeg og hold rengjøringsrekken din i live",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primaryText2,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  WidgetFactory.makeInput(
                    label: "Fornavn",
                    contex: context,
                    controller: _firstNameController,
                    validator: UserNameValidator(),
                  ),
                  WidgetFactory.makeInput(
                    label: "Etternavn",
                    contex: context,
                    controller: _lastNameController,
                    validator: UserNameValidator(),
                  ),
                  WidgetFactory.makeInput(
                    label: "E-post",
                    contex: context,
                    controller: _emailController,
                    validator: EmailValidator(),
                  ),
                  WidgetFactory.makeInput(
                    label: "Telefonnummer",
                    contex: context,
                    controller: _phoneNumberController,
                    validator: PhoneNumberValidator(),
                  ),
                  WidgetFactory.makeInputPassword(
                    label: "Passord",
                    contex: context,
                    obscureText: passToggle,
                    passToggle: passToggle,
                    controller: _passwordController,
                    validator: PasswordValidator(),
                    togglePasswordVisibility: togglePasswordVisibility,
                  ),
                  WidgetFactory.makeInputPassword(
                    label: "Bekreft passord",
                    contex: context,
                    obscureText: passToggle,
                    passToggle: passToggle,
                    controller: _confirmpasswordController,
                    validator: ConfirmPasswordValidator(_passwordController),
                    togglePasswordVisibility: togglePasswordVisibility,
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : GestureDetector(
                    onTap: _register,
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.accent3],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent3.withOpacity(0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "Registrer deg",
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
                        "Har du allerede en konto?",
                        style: TextStyle(color: AppColors.primaryText2),
                      ),
                      GestureDetector(
                        onTap: () => GoRouter.of(context).push(loginPath),
                        child: Text(
                          "Logg inn",
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


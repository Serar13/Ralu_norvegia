import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ralu_norvegia/firebase_options.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'l10n/app_localizations.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Handle background message
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "RaluNorvegia",
       localizationsDelegates: AppLocalizations.localizationsDelegates,
       supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: AppRouter().router,
    );
  }
}

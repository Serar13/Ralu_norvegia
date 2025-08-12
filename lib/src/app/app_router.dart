import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/app/app_routers.dart';
import 'package:ralu_norvegia/src/ui/screens/aboutUs_view.dart';
import 'package:ralu_norvegia/src/ui/screens/adminConsole_view.dart';
import 'package:ralu_norvegia/src/ui/screens/admin_view.dart';
import 'package:ralu_norvegia/src/ui/screens/editProfile_view.dart';
import 'package:ralu_norvegia/src/ui/screens/forgot_pw_view.dart';
import 'package:ralu_norvegia/src/ui/screens/home_view.dart';
import 'package:ralu_norvegia/src/ui/screens/log_in.dart';
import 'package:ralu_norvegia/src/ui/screens/roomsHouse_view.dart';
import 'package:ralu_norvegia/src/ui/screens/sing_in.dart';
import 'package:ralu_norvegia/src/ui/screens/splash_screen.dart';
import 'package:ralu_norvegia/src/ui/screens/userProfile_view.dart';
import 'package:ralu_norvegia/src/ui/screens/waintingForVerificationEdit.dart';
import 'package:ralu_norvegia/src/ui/screens/welcome_view.dart';

import '../ui/screens/choseOption_view.dart';
import '../ui/screens/review_chose.dart';
import '../ui/screens/roomsSetup_view.dart';
import '../ui/screens/waitingForVerification_view.dart';

const String loginPath = "/login";
const String singinPath = "/singin";
const String homePath = "/home";
const String aboutPath = "/about";
const String userProfilePath = "/userProfile";
const String forgotPasswordPagePath = "/forgotPasswordPage";
const String waitingVerificationPath = "/waitingVerification";
const String waitingVerificationEditPath = "/waitingVerificationEdit";
const String editProfilePath = "/editProfile";
const String splashPath = "/splash";
const String welcomePath = "/welcome";
const String adminPath = "/admin";
const String adminConsolePath = "/adminConsole";
const String RoomsHousePath = "/RoomsHouse";
const String ChooseOptionPath = "/ChooseOption";
const String ReviewChosePath = "/ReviewChose";
const String RoomsSetupPath = "/RoomsSetup";

final GlobalKey<NavigatorState> _rootNavigatorKey =
GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {

  final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: splashPath,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        name: AppRoutes.splashRoute,
        path: splashPath,
        pageBuilder: (context, state) =>
        const NoTransitionPage(
            child: SplashScreen()
        ),
      ),
       GoRoute(
          name: AppRoutes.loginRoute,
          path: loginPath,
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) =>
          const NoTransitionPage(
              child: logInView()
          ),
        ),
      GoRoute(
        name: AppRoutes.singinRoute,
        path: singinPath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
        const NoTransitionPage(
            child: singInView()
        ),
      ),
      GoRoute(
        name: AppRoutes.welcomeRoute,
        path: welcomePath,
        pageBuilder: (context, state) =>
            CustomTransitionPage(
              child: const WelcomeView(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // Define a fade transition
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
      ),
      GoRoute(
        name: AppRoutes.homeRoute,
        path: homePath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
        const NoTransitionPage(
            child: homeView()
        ),
      ),
      GoRoute(
        name: AppRoutes.adminRoute,
        path: adminPath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
        const NoTransitionPage(
            child: admin()
        ),
      ),
      GoRoute(
        name: AppRoutes.adminConsoleRoute,
        path: adminConsolePath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
        const NoTransitionPage(
            child: adminConsoleView()
        ),
      ),
      GoRoute(
        name: AppRoutes.aboutRoute,
        path: aboutPath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
        const NoTransitionPage(
            child: aboutUsView()
        ),
      ),
      GoRoute(
        name: AppRoutes.userProfileRoute,
        path: userProfilePath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
        const NoTransitionPage(
            child: userProfileView()
        ),
      ),
      GoRoute(
        name: AppRoutes.forgotPasswordPageRoute,
        path: forgotPasswordPagePath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
        const NoTransitionPage(
            child: ForgotPasswordPage()
        ),
      ),
      GoRoute(
        name: AppRoutes.waitingVerificationRoute,
        path: waitingVerificationPath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
        const NoTransitionPage(
            child: waitingForVerificationView()
        ),
      ),
      GoRoute(
        name: AppRoutes.waitingVerificationEditRoute,
        path: waitingVerificationEditPath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
        const NoTransitionPage(
            child: waitingForVerificationEditView()
        ),
      ),
      GoRoute(
        name: AppRoutes.RoomsHouseRoute,
        path: RoomsHousePath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          // Extract extra data
          final Map<String, dynamic> data = state.extra as Map<String, dynamic>;
          final String userId = data['userId'] as String;

          return NoTransitionPage(
            child: WeeklyPlanner(
              userId: userId, // Pass the userId to WeeklyPlanner
            ),
          );
        },
      ),
      GoRoute(
        name: AppRoutes.ChooseOptionRoute,
        path: ChooseOptionPath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          // Extract extra data
          final Map<String, dynamic> data = state.extra as Map<String, dynamic>;
          final String userId = data['userId'] as String;

          return NoTransitionPage(
            child: ChooseOptionScreen(
              userId: userId, // Pass the userId to the screen
            ),
          );
        },
      ),
      GoRoute(
        name: AppRoutes.ReviewChoseRoute,
        path: ReviewChosePath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final Map<String, dynamic>? data = state.extra as Map<String, dynamic>?;
          final String optionType = (data?['optionType'] as String?) ?? 'basic';
          final String userId = (data?['userId'] as String?) ?? '';

          return NoTransitionPage(
            child: ReviewChose(
              optionType: optionType,
              weekPlan: const {}, // legacy, nefolosit când venim cu planWeeks în extras
              userId: userId,
            ),
          );
        },
      ),
      GoRoute(
        name: AppRoutes.editProfileRoute,
        path: editProfilePath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final Map<String, dynamic> userData = state.extra as Map<String, dynamic>;
          return NoTransitionPage(
            child: EditProfileView(userData: userData),
          );
        },
      ),
      GoRoute(
        name: AppRoutes.RoomsSetupRoute,
        path: RoomsSetupPath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
        NoTransitionPage(
            child: RoomsSetupPage()
        ),
      ),
    ],
  );

}

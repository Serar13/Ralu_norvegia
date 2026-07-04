import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  /// Sign in with Facebook and map to Firebase Auth.
  ///
  /// Returns the logged-in [UserCredential], or `null` if the user cancelled the login.
  static Future<UserCredential?> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      switch (result.status) {
        case LoginStatus.success:
          // Retrieve the access token
          final AccessToken accessToken = result.accessToken!;
          
          // Create a credential from the token
          final OAuthCredential credential =
              FacebookAuthProvider.credential(accessToken.token);
          
          // Sign in to Firebase with the credential
          final UserCredential userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
              
          return userCredential;

        case LoginStatus.cancelled:
          // User cancelled the login flow
          return null;

        case LoginStatus.failed:
          // Login failed
          throw Exception(result.message ?? 'Facebook login failed.');

        case LoginStatus.operationInProgress:
          // Sign-in operation already in progress
          return null;
      }
    } catch (e) {
      throw Exception('Facebook Auth Error: $e');
    }
  }

  /// Sign out of both Firebase and Facebook Auth.
  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await FacebookAuth.instance.logOut();
  }
}

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
class AppStrings {

  static String welcome(BuildContext context) {
    return AppLocalizations.of(context)!.welcome;
  }
  static String userName(BuildContext context) {
    return AppLocalizations.of(context)!.userName;
  }
  static String passWord(BuildContext context) {
    return AppLocalizations.of(context)!.passWord;
  }
  static String userEmail(BuildContext context) {
    return AppLocalizations.of(context)!.userEmail;
  }
  static String userPhone(BuildContext context) {
    return AppLocalizations.of(context)!.userPhone;
  }
  static String passWordVerification(BuildContext context) {
    return AppLocalizations.of(context)!.passWordVerification;
  }
  static String restaurantName(BuildContext context) {
    return AppLocalizations.of(context)!.restaurantName;
  }
  static String comandaMinima(BuildContext context) {
    return AppLocalizations.of(context)!.comandaMinima;
  }
  static String timeOpen(BuildContext context) {
    return AppLocalizations.of(context)!.timeOpen;
  }
}
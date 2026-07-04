// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get app_title => 'Ralu';

  @override
  String list_item_done_ago(String when) {
    return 'done $when';
  }

  @override
  String get welcome => 'Velkomst til';

  @override
  String get userName => 'Username';

  @override
  String get passWord => 'Password';

  @override
  String get userEmail => 'User email';

  @override
  String get userPhone => 'User phone';

  @override
  String get passWordVerification => 'Password verify';

  @override
  String get restaurantName => 'Restaurant name';

  @override
  String get comandaMinima => 'Minimum price for order';

  @override
  String get timeOpen => 'Schedule';
}

import 'package:flutter/material.dart';

import 'functions.dart';

abstract class Validator{
  String? validate(String? value);
}
class EmailValidator extends Validator{
  @override
  String? validate(String? value){
    if(value == null || value.isEmpty) {
      return 'Email can not be empty.';
    } else {
      if (!isEmail(value)) {
        return 'Email is not valid.';
      }
    }
    return null;
  }
}

class UserNameValidator extends Validator {
  @override
  String? validate(String? value) {
    if(value == null || value.isEmpty) {
      return 'Username can not be empty';
    } else {
      if(value.length < 5 ) {
        return 'Username is to short';
      } else {
        if (!isUserNameValid(value)) {
          return 'Username should contain only alphanumeric characters.';
        }
      }
    }
    return null;
  }

  bool isUserNameValid(String value) {
    String pattern = r'^[a-zA-Z0-9_]+$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(value);
  }
}

class PasswordValidator extends Validator {
  @override
  String? validate(String? value) {
    if (value == null) {
      return 'Password is not valid.';
    }

    if (value.length < 7) {
      return 'Password is too short. It must be at least 7 characters long.';
    }

    int specialCharacterCount = 0;
    int uppercaseCharacterCount = 0;

    for (int i = 0; i < value.length; i++) {
      if (value[i].contains(RegExp(r'[!@#\$%^&*()_+{}[\]:;<>,.?~\\-]'))) {
        specialCharacterCount++;
      } else if (value[i].contains(RegExp(r'[A-Z]'))) {
        uppercaseCharacterCount++;
      }
    }

    if (specialCharacterCount < 1) {
      return 'Password needs at least one special character.';
    }

    if (uppercaseCharacterCount < 1) {
      return 'Password needs at least one uppercase character.';
    }

    return null;
  }
}
class ConfirmPasswordValidator extends Validator {
  final TextEditingController passwordController;

  ConfirmPasswordValidator(this.passwordController);

  @override
  String? validate(String? value) {
    print("Confirm Password: $value");
    print("Original Password: ${passwordController.text}");

    if (value == null || value.isEmpty) {
      return 'Password confirmation is required.';
    }

    if (value.trim() != passwordController.text.trim()) {
      return 'Passwords do not match.';
    }

    return null;
  }
}


class PhoneNumberValidator extends Validator {
  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required.';
    }
    String pattern = r'^[+0-9\- ]+$';
    RegExp regExp = RegExp(pattern);
    if (!regExp.hasMatch(value)) {
      return 'Invalid phone number format.';
    }

    return null;
  }
}

class RestaurantNameValidator extends Validator {
  @override
  String? validate(String? value) {
    if(value == null || value.trim().isEmpty) {
      return 'Restaurant name cannot be empty';
    } else {
      if(value.length < 6 ) {
        return 'Restaurant name is too short';
      } else {
        if (!isRestaurantNameValid(value)) {
          return 'Restaurant name should contain only alphanumeric characters and spaces.';
        }
      }
    }
    return null;
  }

  bool isRestaurantNameValid(String value) {
    String pattern = r'^[a-zA-Z0-9\s]+$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(value);
  }
}

class MinimumPriceValidator extends Validator {
  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Minimum price cannot be empty';
    } else {
      if (!isNumeric(value)) {
        return 'Minimum price should contain only digits';
      }
    }
    return null;
  }

  bool isNumeric(String value) {
    if (value == null) {
      return false;
    }
    return double.tryParse(value) != null;
  }
}

class HoursValidator extends Validator{
  @override
  String? validate(String? value){
    if(value == null || value.isEmpty) {
      return 'Email can not be empty.';
    }
    return null;
  }
}



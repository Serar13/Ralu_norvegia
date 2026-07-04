
bool isEmail(String em) {

  if (em.isEmpty) {
    return false;
  }
  String p =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  RegExp regExp = RegExp(p);
  return regExp.hasMatch(em);
}


bool isPasswordValid(String password) {
  // Check if the password is not null or empty
  if (password.isEmpty) {
    return false;
  }

  // Check if the password length is at least 7 characters
  if (password.length < 7) {
    return false;
  }

  // Check if the password contains at least one special character
  final specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
  if (!specialCharRegex.hasMatch(password)) {
    return false;
  }

  // If all checks pass, the password is considered valid
  return true;
}

bool isFirstName(String username) {
  if (username.isEmpty) {
    // Username is required, so it cannot be empty.
    return false;
  }

  final regex = RegExp(r"^[\p{L}\p{M}\s'\-]+$", unicode: true);
  return regex.hasMatch(username);
}

bool isLastName(String username) {
  if (username.isEmpty) {
    // Username is required, so it cannot be empty.
    return false;
  }

  final regex = RegExp(r"^[\p{L}\p{M}\s'\-]+$", unicode: true);
  return regex.hasMatch(username);
}



bool isURL(String em) {
  String p =
      r"[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%.\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%\+.~#?&//=]*)";
  RegExp regExp = RegExp(p);
  return regExp.hasMatch(em);
}

bool isPassword(String value) {
  String p =
      r'^(?=.\d)(?=.[a-z])(?=.[A-Z])(?=.[^a-zA-Z0-9])(?!.*\s).{8,30}$';
  RegExp regExp = RegExp(p);
  return regExp.hasMatch(value);
}


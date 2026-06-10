/// Auth ekranlarının ortak saf doğrulama kuralları.
///
/// BuildContext yok; dönen [AuthFieldError] lokalize metne widget tarafında
/// çevrilir (ConvError deseniyle aynı sözleşme).
enum AuthFieldError {
  emptyFields,
  emptyName,
  invalidEmail,
  passwordTooShort,
  passwordsDontMatch,
}

final RegExp authEmailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');

const int authPasswordMinLength = 6;

AuthFieldError? validateSignIn({
  required String email,
  required String password,
}) {
  if (email.trim().isEmpty || password.trim().isEmpty) {
    return AuthFieldError.emptyFields;
  }
  if (!authEmailRegex.hasMatch(email.trim())) {
    return AuthFieldError.invalidEmail;
  }
  return null;
}

AuthFieldError? validateSignUp({
  required String email,
  required String password,
  required String name,
}) {
  if (email.trim().isEmpty || password.trim().isEmpty) {
    return AuthFieldError.emptyFields;
  }
  if (name.trim().isEmpty) {
    return AuthFieldError.emptyName;
  }
  if (!authEmailRegex.hasMatch(email.trim())) {
    return AuthFieldError.invalidEmail;
  }
  if (password.trim().length < authPasswordMinLength) {
    return AuthFieldError.passwordTooShort;
  }
  return null;
}

AuthFieldError? validateEmail(String email) {
  if (email.trim().isEmpty || !authEmailRegex.hasMatch(email.trim())) {
    return AuthFieldError.invalidEmail;
  }
  return null;
}

/// Yeni şifre + tekrar alanları (reset/change ekranları).
AuthFieldError? validateNewPassword({
  required String password,
  required String confirm,
}) {
  if (password.isEmpty || confirm.isEmpty) {
    return AuthFieldError.emptyFields;
  }
  if (password.length < authPasswordMinLength) {
    return AuthFieldError.passwordTooShort;
  }
  if (password != confirm) {
    return AuthFieldError.passwordsDontMatch;
  }
  return null;
}

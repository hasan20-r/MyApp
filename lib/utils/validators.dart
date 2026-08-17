class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required.';
    }
    final email = value.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name is required.';
    }
    if (value.trim().length < 2) {
      return 'Display name must be at least 2 characters.';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Handle is required.';
    }
    final username = value.trim().toLowerCase();
    if (username.length < 3 || username.length > 20) {
      return 'Handle must be 3-20 characters.';
    }
    final regex = RegExp(r'^[a-z0-9_]+$');
    if (!regex.hasMatch(username)) {
      return 'Only lowercase letters, numbers, and underscores are allowed.';
    }
    return null;
  }
}

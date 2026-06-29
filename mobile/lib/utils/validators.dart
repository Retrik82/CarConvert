class Validators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w.-]+\.\w{2,}$');

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(trimmed)) return 'Invalid email format';
    return null;
  }

  /// Login accepts email or username (e.g. admin).
  static String? loginIdentifier(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email or username is required';
    if (_emailRegex.hasMatch(trimmed)) return null;
    if (RegExp(r'^[\w.-]+$').hasMatch(trimmed)) return null;
    return 'Invalid email or username';
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < minLength) return 'Password must be at least $minLength characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price is required';
    final normalized = value.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) return 'Price must be greater than 0';
    final parts = normalized.split('.');
    if (parts.length > 1 && parts[1].length > 2) {
      return 'Maximum 2 decimal places';
    }
    if (parsed > 999.99) return 'Price must not exceed 999.99';
    return null;
  }
}

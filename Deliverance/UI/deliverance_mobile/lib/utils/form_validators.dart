typedef FieldValidator = String? Function(Object? value);

class FieldLimits {
  static const personNameMax = 50;
  static const usernameMin = 3;
  static const usernameMax = 20;
  static const emailMax = 256;
  static const passwordMin = 8;
  static const passwordMax = 55;
  static const reportTitleMax = 30;
  static const reportDetailMax = 255;
  static const deviceDetailMax = 255;
  static const chatMessageMax = 1000;
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _phonePattern = RegExp(r'^\+?[0-9\s\-()]{6,20}$');

String _text(Object? value) => (value as String?)?.trim() ?? '';

FieldValidator allOf(List<FieldValidator> validators) => (value) {
  for (final validator in validators) {
    final message = validator(value);
    if (message != null) return message;
  }
  return null;
};

FieldValidator requiredField(String label) =>
    (value) => _text(value).isEmpty ? '$label is required' : null;

FieldValidator maxLength(String label, int max, {bool required = false}) =>
    (value) {
      final text = _text(value);
      if (required && text.isEmpty) return '$label is required';
      return text.length > max
          ? '$label can have at most $max characters (now ${text.length})'
          : null;
    };

FieldValidator lengthBetween(String label, int min, int max) => (value) {
  final text = _text(value);
  if (text.isEmpty) return '$label is required';
  return text.length < min || text.length > max
      ? '$label must be $min to $max characters long'
      : null;
};

FieldValidator personName(String label) =>
    maxLength(label, FieldLimits.personNameMax, required: true);

FieldValidator username() =>
    lengthBetween('Username', FieldLimits.usernameMin, FieldLimits.usernameMax);

FieldValidator email() => (value) {
  final text = _text(value);
  if (text.isEmpty) return 'Email is required';
  if (text.length > FieldLimits.emailMax) {
    return 'Email can have at most ${FieldLimits.emailMax} characters';
  }
  return _emailPattern.hasMatch(text)
      ? null
      : 'Enter a valid email address in the format name@example.com';
};

FieldValidator password(String label) => (value) {
  final text = (value as String?) ?? '';
  if (text.isEmpty) return '$label is required';
  return text.length < FieldLimits.passwordMin ||
          text.length > FieldLimits.passwordMax
      ? '$label must be ${FieldLimits.passwordMin} to ${FieldLimits.passwordMax} characters long'
      : null;
};

FieldValidator phone() => (value) {
  final text = _text(value);
  if (text.isEmpty) return 'Phone number is required';
  return _phonePattern.hasMatch(text)
      ? null
      : 'Enter a phone number of 6 to 20 characters: digits, spaces, dashes or brackets, optionally starting with + (e.g. +387 61 123 456)';
};

FieldValidator sameAs(String Function() other, String message) =>
    (value) => (value as String?) == other() ? null : message;

/// Validation for person first/last name fields.
///
/// Allows Unicode letters, spaces, hyphens, and apostrophes. Blocks numbers
/// and symbols that could be used for injection attacks.
class PersonNameValidator {
  PersonNameValidator._();

  static const int minLength = 1;
  static const int maxLength = 50;

  static final RegExp _allowedPattern = RegExp(
    r"^[\p{L}\u0F00-\u0FFF'\-\s]+$",
    unicode: true,
  );

  /// Trims whitespace and collapses consecutive spaces to a single space.
  ///
  /// Returns `null` when the result is empty (optional name fields).
  static String? sanitize(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Returns `true` when [input] is empty or passes all validation rules.
  static bool isValid(String input) {
    return validate(input) == null;
  }

  /// Returns a validation error kind, or `null` when valid.
  static PersonNameValidationError? validate(String input) {
    final sanitized = sanitize(input);
    if (sanitized == null) return null;
    if (sanitized.length < minLength) {
      return PersonNameValidationError.tooShort;
    }
    if (sanitized.length > maxLength) {
      return PersonNameValidationError.tooLong;
    }
    if (!_allowedPattern.hasMatch(sanitized)) {
      return PersonNameValidationError.invalidCharacters;
    }
    return null;
  }
}

enum PersonNameValidationError { tooShort, tooLong, invalidCharacters }

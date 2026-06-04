/// Result of a PATCH /users/username call.
class UsernameUpdateResult {
  final bool isAvailable;
  final String? updatedUsername;
  final List<String> suggestions;

  const UsernameUpdateResult._({
    required this.isAvailable,
    this.updatedUsername,
    this.suggestions = const [],
  });

  factory UsernameUpdateResult.success(String username) =>
      UsernameUpdateResult._(isAvailable: true, updatedUsername: username);

  factory UsernameUpdateResult.conflict(List<String> suggestions) =>
      UsernameUpdateResult._(isAvailable: false, suggestions: suggestions);
}

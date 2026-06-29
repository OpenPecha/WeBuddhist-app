class GroupMember {
  final String username;
  final String fullname;
  final String? avatarUrl;

  const GroupMember({
    required this.username,
    required this.fullname,
    this.avatarUrl,
  });
}

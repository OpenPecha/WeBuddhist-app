import 'package:flutter_pecha/features/group_profile/domain/entities/group_member.dart';

class GroupMembersPage {
  final List<GroupMember> members;
  final int skip;
  final int limit;
  final int totalMembers;

  const GroupMembersPage({
    required this.members,
    required this.skip,
    required this.limit,
    required this.totalMembers,
  });

  bool get hasMore => skip + members.length < totalMembers;
}

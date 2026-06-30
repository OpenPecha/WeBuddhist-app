import 'package:flutter_pecha/features/group_profile/domain/entities/group_member.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_members_page.dart';

class GroupMemberModel {
  final String username;
  final String fullname;
  final String? avatarUrl;

  GroupMemberModel({
    required this.username,
    required this.fullname,
    this.avatarUrl,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      username: json['username'] as String? ?? '',
      fullname: json['fullname'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  GroupMember toEntity() {
    return GroupMember(
      username: username,
      fullname: fullname,
      avatarUrl: avatarUrl,
    );
  }
}

class GroupMembersPageModel {
  final List<GroupMemberModel> members;
  final int skip;
  final int limit;
  final int totalMembers;

  GroupMembersPageModel({
    required this.members,
    required this.skip,
    required this.limit,
    required this.totalMembers,
  });

  factory GroupMembersPageModel.fromJson(Map<String, dynamic> json) {
    return GroupMembersPageModel(
      members:
          (json['list'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(GroupMemberModel.fromJson)
              .toList() ??
          const [],
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      totalMembers: (json['total_members'] as num?)?.toInt() ?? 0,
    );
  }

  GroupMembersPage toEntity() {
    return GroupMembersPage(
      members: members.map((member) => member.toEntity()).toList(),
      skip: skip,
      limit: limit,
      totalMembers: totalMembers,
    );
  }
}

import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';

class DiscoverGroupsPage {
  final List<GroupProfile> groups;
  final int skip;
  final int limit;
  final int total;

  const DiscoverGroupsPage({
    required this.groups,
    required this.skip,
    required this.limit,
    required this.total,
  });

  bool get hasMore => skip + groups.length < total;
}

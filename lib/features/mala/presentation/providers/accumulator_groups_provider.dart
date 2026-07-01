import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Joined group accumulators for the current preset
/// (`GET /accumulators/{accumulator_id}/groups?joined_only=true`).
final joinedAccumulatorGroupsProvider = FutureProvider.autoDispose
    .family<List<AccumulatorGroup>, String>((ref, presetId) async {
      final result = await ref
          .watch(malaRepositoryProvider)
          .getJoinedAccumulatorGroups(presetId);
      return result.fold((_) => const [], (groups) => groups);
    });

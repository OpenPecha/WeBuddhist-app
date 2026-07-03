import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_body.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupProfileDrawer extends ConsumerWidget {
  final String groupId;

  const GroupProfileDrawer({super.key, required this.groupId});

  static const double _initialSize = 0.82;
  static const double _minSize = 0.45;
  static const double _maxSize = 0.96;

  static Future<void> show(BuildContext context, String groupId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => GroupProfileDrawer(groupId: groupId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(groupProfileProvider(groupId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: _initialSize,
      minChildSize: _minSize,
      maxChildSize: _maxSize,
      snap: true,
      snapSizes: const [_minSize, _initialSize, _maxSize],
      snapAnimationDuration: const Duration(milliseconds: 180),
      builder: (context, _) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            elevation: 12,
            shadowColor: Colors.black.withValues(alpha: 0.18),
            child: Column(
              children: [
                _buildDragHandle(context),
                Expanded(
                  child: profileAsync.when(
                    data:
                        (either) => either.fold(
                          (failure) => Center(
                            child: ErrorStateWidget(
                              error: failure,
                              onRetry:
                                  () => ref.invalidate(
                                    groupProfileProvider(groupId),
                                  ),
                            ),
                          ),
                          (profile) => GroupProfileBody(
                            profile: profile,
                            isDark: isDark,
                          ),
                        ),
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (error, _) => Center(
                          child: ErrorStateWidget(
                            error: error,
                            onRetry:
                                () => ref.invalidate(
                                  groupProfileProvider(groupId),
                                ),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: context.l10n.drag_to_resize,
      child: SizedBox(
        height: 44,
        width: double.infinity,
        child: Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

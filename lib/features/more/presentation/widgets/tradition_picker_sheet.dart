import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/more/presentation/providers/tradition_onboarding_paths_provider.dart';
import 'package:flutter_pecha/features/more/presentation/providers/user_traditions_provider.dart';
import 'package:flutter_pecha/features/onboarding/data/models/tradition_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TraditionPickerSheet extends ConsumerStatefulWidget {
  const TraditionPickerSheet({
    super.key,
    required this.initialSelectedCodes,
  });

  final Set<String> initialSelectedCodes;

  @override
  ConsumerState<TraditionPickerSheet> createState() =>
      _TraditionPickerSheetState();
}

class _TraditionPickerSheetState extends ConsumerState<TraditionPickerSheet> {
  static const int _expectedPathCount = 3;
  static const double _rowHeight = 58;

  late Set<String> _selectedCodes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCodes = Set<String>.from(widget.initialSelectedCodes);
  }

  double _bodyHeight(int itemCount) {
    final rows = itemCount == 0 ? _expectedPathCount : itemCount;
    return rows * _rowHeight;
  }

  void _toggleSelection(String code) {
    setState(() {
      if (_selectedCodes.contains(code)) {
        _selectedCodes.remove(code);
      } else {
        _selectedCodes.add(code);
      }
    });
  }

  Future<void> _onDone() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final saved = await ref
        .read(userTraditionsProvider.notifier)
        .syncSelections(_selectedCodes);

    if (!mounted) return;

    if (saved) {
      Navigator.of(context).pop();
      return;
    }

    final serverCodes = ref
            .read(userTraditionsProvider)
            .valueOrNull
            ?.map((t) => t.traditionCode)
            .toSet() ??
        widget.initialSelectedCodes;
    setState(() {
      _isSaving = false;
      _selectedCodes = Set<String>.from(serverCodes);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.edit_profile_tradition_save_failed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final pathsAsync = ref.watch(traditionOnboardingPathsProvider);
    final paths = pathsAsync.valueOrNull ?? const <TraditionPath>[];
    final isLoadingPaths = pathsAsync.isLoading && paths.isEmpty;
    final hasLoadError = pathsAsync.hasError && paths.isEmpty;

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.edit_profile_traditions,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: SizedBox(
                key: ValueKey(
                  isLoadingPaths
                      ? 'loading'
                      : hasLoadError
                      ? 'error'
                      : 'list-${paths.length}',
                ),
                height: _bodyHeight(paths.length),
                child: _buildBody(
                  context,
                  l10n,
                  dividerColor,
                  paths,
                  isLoadingPaths,
                  hasLoadError,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed:
                      _isSaving || isLoadingPaths || hasLoadError
                          ? null
                          : _onDone,
                  style: TextButton.styleFrom(
                    backgroundColor:
                        isDark
                            ? AppColors.surfaceWhite
                            : AppColors.scaffoldBackgroundDark,
                    foregroundColor:
                        isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryDark,
                    disabledBackgroundColor:
                        isDark ? AppColors.grey800 : AppColors.grey300,
                    disabledForegroundColor:
                        isDark ? AppColors.grey600 : AppColors.grey500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child:
                      _isSaving
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(
                            l10n.done,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    Color dividerColor,
    List<TraditionPath> paths,
    bool isLoadingPaths,
    bool hasLoadError,
  ) {
    if (isLoadingPaths) {
      return _TraditionPickerSkeleton(dividerColor: dividerColor);
    }

    if (hasLoadError) {
      return Center(
        child: TextButton(
          onPressed: () => ref.invalidate(traditionOnboardingPathsProvider),
          child: Text(l10n.something_went_wrong),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: paths.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: dividerColor),
      itemBuilder: (context, index) {
        final path = paths[index];
        final isSelected = _selectedCodes.contains(path.code);

        return InkWell(
          onTap: () => _toggleSelection(path.code),
          child: SizedBox(
            height: _rowHeight - 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      path.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  _SelectionIndicator(isSelected: isSelected),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TraditionPickerSkeleton extends StatelessWidget {
  const _TraditionPickerSkeleton({required this.dividerColor});

  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _TraditionPickerSheetState._expectedPathCount,
      separatorBuilder: (_, __) => Divider(height: 1, color: dividerColor),
      itemBuilder: (context, index) {
        return SizedBox(
          height: _TraditionPickerSheetState._rowHeight - 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.grey300, width: 2),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.brandblue : AppColors.greyMedium,
          width: 2,
        ),
        color: isSelected ? AppColors.brandblue : Colors.transparent,
      ),
      child:
          isSelected
              ? const Center(
                child: Icon(Icons.circle, size: 10, color: Colors.white),
              )
              : null,
    );
  }
}

Future<void> showTraditionPickerSheet(
  BuildContext context, {
  required Set<String> initialSelectedCodes,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder:
        (_) => TraditionPickerSheet(
          initialSelectedCodes: initialSelectedCodes,
        ),
  );
}

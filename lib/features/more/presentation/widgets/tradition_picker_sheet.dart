import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/more/presentation/providers/user_traditions_provider.dart';
import 'package:flutter_pecha/features/onboarding/data/models/tradition_models.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/onboarding_datasource_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TraditionPickerSheet extends ConsumerStatefulWidget {
  const TraditionPickerSheet({super.key});

  @override
  ConsumerState<TraditionPickerSheet> createState() =>
      _TraditionPickerSheetState();
}

class _TraditionPickerSheetState extends ConsumerState<TraditionPickerSheet> {
  List<TraditionPath> _paths = const [];
  late Set<String> _selectedCodes;
  bool _isLoadingPaths = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    final currentTraditions = ref.read(userTraditionsProvider).valueOrNull ??
        const <UserTradition>[];
    _selectedCodes = currentTraditions.map((t) => t.traditionCode).toSet();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    setState(() {
      _isLoadingPaths = true;
      _loadError = null;
    });

    try {
      final language = ref.read(localeProvider).languageCode;
      final paths = await ref
          .read(onboardingRemoteDatasourceProvider)
          .fetchTraditionOnboardingPaths(language: language);
      if (!mounted) return;
      setState(() {
        _paths = paths;
        _isLoadingPaths = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingPaths = false;
        _loadError = 'load_failed';
      });
    }
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

    setState(() => _isSaving = false);
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
            Flexible(
              child: _buildBody(context, l10n, dividerColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: _isSaving || _isLoadingPaths ? null : _onDone,
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
  ) {
    if (_isLoadingPaths) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Center(
          child: TextButton(
            onPressed: _loadPaths,
            child: Text(l10n.something_went_wrong),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: _paths.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: dividerColor),
      itemBuilder: (context, index) {
        final path = _paths[index];
        final isSelected = _selectedCodes.contains(path.code);

        return InkWell(
          onTap: () => _toggleSelection(path.code),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
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

void showTraditionPickerSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => const TraditionPickerSheet(),
  );
}

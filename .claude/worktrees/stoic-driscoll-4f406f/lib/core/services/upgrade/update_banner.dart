import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';

/// Snackbar-style banner that notifies users about available app updates.
///
/// Shows at the bottom of the screen with slide-up + fade-in animation,
/// auto-dismisses after [displayDuration].
class UpdateBanner extends StatefulWidget {
  const UpdateBanner({
    super.key,
    required this.onUpdateTap,
    this.displayDuration = const Duration(seconds: 5),
    this.onDismissed,
  });

  /// Callback when user taps the "Update" button.
  final VoidCallback onUpdateTap;

  /// How long to display the banner before auto-dismissing.
  final Duration displayDuration;

  /// Called when the banner finishes dismissing.
  final VoidCallback? onDismissed;

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(widget.displayDuration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      widget.onDismissed?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A7C7C),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sync,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getUpdateText(locale, localizations),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: widget.onUpdateTap,
                child: Text(
                  _getUpdateButtonText(locale, localizations),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getUpdateText(Locale locale, AppLocalizations? localizations) {
    switch (locale.languageCode) {
      case AppConfig.tibetanLanguageCode:
        return 'གསར་བསྒྱུར་གསར་པ་འཐོབ་རུང་།';
      case AppConfig.chineseLanguageCode:
        return '有新更新可用';
      default:
        return 'New Update Available';
    }
  }

  String _getUpdateButtonText(Locale locale, AppLocalizations? localizations) {
    switch (locale.languageCode) {
      case AppConfig.tibetanLanguageCode:
        return 'གསར་བསྒྱུར།';
      case AppConfig.chineseLanguageCode:
        return '更新';
      default:
        return 'Update';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Uniform app bar for bottom navigation root tabs.
///
/// Keeps title typography, spacing, and toolbar height consistent so tab
/// switches do not shift the title vertically.
class MainTabAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainTabAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.bottom,
    this.toolbarHeight = defaultToolbarHeight,
  }) : assert(title != null || titleWidget != null);

  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;

  static const double defaultToolbarHeight = kToolbarHeight;
  static const double titleSpacing = 20;

  static TextStyle titleStyle(BuildContext context) {
    final titleFontSize = getLocalizedFontSize(AppTextSize.titleLarge);
    return Theme.of(context).textTheme.headlineMedium!.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: titleFontSize,
      height:
          context.isTibetanLocale
              ? AppFontConfig.tibetanCompactLineHeight
              : null,
      leadingDistribution:
          context.isTibetanLocale
              ? AppFontConfig.tibetanLeadingDistribution
              : null,
    );
  }

  static Widget buildTitle(BuildContext context, String text) {
    final titleFontSize = getLocalizedFontSize(AppTextSize.titleLarge);
    return Text(
      text,
      strutStyle: context.tibetanStrutStyle(titleFontSize, compact: true),
      style: titleStyle(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
      toolbarHeight: toolbarHeight,
      titleSpacing: titleSpacing,
      title: titleWidget ?? buildTitle(context, title!),
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(toolbarHeight + bottomHeight);
  }
}

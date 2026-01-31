import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppBottomNavItem<T> extends StatelessWidget {
  const AppBottomNavItem({
    super.key,
    required this.model,
    required this.selectedType,
  });

  final AppBottomBarItemModel model;
  final T selectedType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Active color uses primary color, inactive uses grey (dark mode friendly)
    final activeColor =
        theme.colorScheme.brightness == Brightness.dark
            ? Colors.white
            : Colors.black;
    final inactiveColor =
        isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child:
              model.type == selectedType
                  ? PhosphorIcon(
                    model.selectedIconData,
                    size: 24,
                    color: activeColor,
                  )
                  : PhosphorIcon(
                    model.unSelectedIconData,
                    size: 24,
                    color: inactiveColor,
                  ),
        ),
        const SizedBox(height: 2),
        Text(
          model.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight:
                model.type == selectedType
                    ? FontWeight.bold
                    : FontWeight.normal,
            color: model.type == selectedType ? activeColor : inactiveColor,
          ),
        ),
      ],
    );
  }
}

class AppBottomBarItemModel<T> {
  final PhosphorFlatIconData selectedIconData;
  final PhosphorFlatIconData unSelectedIconData;
  final String label;
  final Widget? selectedWidget;

  final T type;

  AppBottomBarItemModel({
    required this.selectedIconData,
    required this.unSelectedIconData,
    required this.selectedWidget,
    required this.label,
    required this.type,
  });

  @override
  bool operator ==(covariant AppBottomBarItemModel<T> other) {
    if (identical(this, other)) return true;

    return other.type == type;
  }

  @override
  int get hashCode {
    return type.hashCode;
  }
}

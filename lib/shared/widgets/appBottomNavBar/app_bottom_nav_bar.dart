import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/shared/widgets/appBottomNavBar/app_bottom_nav_item.dart';

class AppBottomNavBar<T> extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.onChanged,
    required this.type,
    this.backgroundColor = AppColors.backgroundDark,
  });

  final T type;
  final Color backgroundColor;
  final ValueChanged<T> onChanged;
  final List<AppBottomBarItemModel<T>> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            items.length,
            (index) => Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged.call(items[index].type),
                child: AppBottomNavItem(
                  model: items[index],
                  selectedType: type,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

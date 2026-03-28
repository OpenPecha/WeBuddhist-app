import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Application asset paths
/// Contains all asset file paths used throughout the app
class AppAssets {
  AppAssets._();

  // ========== IMAGES ==========
  static const String routineCalendar = 'assets/images/routine_calendar.png';

  // ========== LOGOS ==========
  static const String weBuddhistLogo = 'assets/images/webuddhist_gold.png';

  // Bottom Navigation icons
  static const PhosphorFlatIconData homeSelected = PhosphorIconsFill.house;
  static const PhosphorFlatIconData homeUnselected = PhosphorIconsRegular.house;
  static const PhosphorFlatIconData exploreSelected =
      PhosphorIconsFill.magnifyingGlass;
  static const PhosphorFlatIconData exploreUnselected =
      PhosphorIconsRegular.magnifyingGlass;
  static const PhosphorFlatIconData textsSelected =
      PhosphorIconsFill.bookOpenText;
  static const PhosphorFlatIconData textsUnselected =
      PhosphorIconsRegular.bookOpenText;
  static const PhosphorFlatIconData practiceSelected = PhosphorIconsFill.bell;
  static const PhosphorFlatIconData practiceUnselected =
      PhosphorIconsRegular.bell;
  static const PhosphorFlatIconData settingsSelected =
      PhosphorIconsFill.gearSix;
  static const PhosphorFlatIconData settingsUnselected =
      PhosphorIconsRegular.gearSix;
  static const PhosphorFlatIconData connectSelected =
      PhosphorIconsFill.usersThree;
  static const PhosphorFlatIconData connectUnselected =
      PhosphorIconsRegular.usersThree;
}

import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Application asset paths
/// Contains all asset file paths used throughout the app
class AppAssets {
  AppAssets._();

  // ========== IMAGES ==========

  // ========== LOGOS ==========
  static const String weBuddhistLogo = 'assets/images/webuddhist_logo.svg';

  // Bottom Navigation icons
  static const PhosphorFlatIconData homeSelected = PhosphorIconsFill.house;
  static const PhosphorFlatIconData homeUnselected = PhosphorIconsRegular.house;
  static const PhosphorFlatIconData textsSelected = PhosphorIconsFill.sparkle;
  static const PhosphorFlatIconData textsUnselected =
      PhosphorIconsRegular.sparkle;
  static const PhosphorFlatIconData practiceSelected = PhosphorIconsFill.bell;
  static const PhosphorFlatIconData practiceUnselected =
      PhosphorIconsRegular.bell;
  static const PhosphorFlatIconData settingsSelected =
      PhosphorIconsFill.gearSix;
  static const PhosphorFlatIconData settingsUnselected =
      PhosphorIconsRegular.gearSix;
}

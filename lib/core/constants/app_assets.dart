import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Application asset paths
/// Contains all asset file paths used throughout the app
class AppAssets {
  AppAssets._();

  // ========== IMAGES ==========
  static const String routineCalendar = 'assets/images/routine_calendar.png';
  static const String recitationCoverDefault =
      'assets/images/recitation_cover/recitation_05.jpg';

  // ========== LOGOS ==========
  static const String weBuddhistLogo = 'assets/images/webuddhist_gold.png';

  // Bottom Navigation icons
  static const IconData homeSelected = PhosphorIconsFill.house;
  static const IconData homeUnselected = PhosphorIconsRegular.house;
  static const IconData exploreSelected =
      PhosphorIconsFill.magnifyingGlass;
  static const IconData exploreUnselected =
      PhosphorIconsRegular.magnifyingGlass;
  static const IconData textsSelected =
      PhosphorIconsFill.bookOpenText;
  static const IconData textsUnselected =
      PhosphorIconsRegular.bookOpenText;
  static const IconData practiceSelected = PhosphorIconsFill.bell;
  static const IconData practiceUnselected =
      PhosphorIconsRegular.bell;
  static const IconData settingsSelected =
      PhosphorIconsFill.gearSix;
  static const IconData settingsUnselected =
      PhosphorIconsRegular.gearSix;
  static const IconData connectSelected =
      PhosphorIconsFill.usersThree;
  static const IconData connectUnselected =
      PhosphorIconsRegular.usersThree;
  static const IconData meSelected = PhosphorIconsFill.userCircle;
  static const IconData meUnselected = PhosphorIconsRegular.userCircle;
}

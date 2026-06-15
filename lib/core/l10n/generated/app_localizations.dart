import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bo.dart';
import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bo'),
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'WeBuddhist'**
  String get appTitle;

  /// No description provided for @pechaHeading.
  ///
  /// In en, this message translates to:
  /// **'WeBuddhist'**
  String get pechaHeading;

  /// No description provided for @learnLiveShare.
  ///
  /// In en, this message translates to:
  /// **'Learn, practice, and connect'**
  String get learnLiveShare;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get themeDark;

  /// No description provided for @switchToLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get switchToLight;

  /// No description provided for @switchToDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get switchToDark;

  /// No description provided for @sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get sign_in;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @onboarding_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get onboarding_welcome;

  /// No description provided for @onboarding_description.
  ///
  /// In en, this message translates to:
  /// **'Where we learn, practice, and share connect. Daily'**
  String get onboarding_description;

  /// No description provided for @onboarding_quote.
  ///
  /// In en, this message translates to:
  /// **'Drop by drop the water pot is filled. Likewise, the wise person, gathering it little by little, fills themselves with good.'**
  String get onboarding_quote;

  /// No description provided for @onboarding_find_peace.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboarding_find_peace;

  /// No description provided for @onboarding_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboarding_continue;

  /// No description provided for @onboarding_first_question.
  ///
  /// In en, this message translates to:
  /// **'Choose your language:'**
  String get onboarding_first_question;

  /// No description provided for @onboarding_second_question.
  ///
  /// In en, this message translates to:
  /// **'Choose the traditions you\'re part of or want to explore:'**
  String get onboarding_second_question;

  /// No description provided for @onboarding_choose_option.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one:'**
  String get onboarding_choose_option;

  /// No description provided for @onboarding_all_set.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set up'**
  String get onboarding_all_set;

  /// No description provided for @onboarding_all_set_description.
  ///
  /// In en, this message translates to:
  /// **'We\'ve tailored your experience to your tradition. Show up each day — even for a moment — and watch your practice grow'**
  String get onboarding_all_set_description;

  /// No description provided for @onboarding_begin_practice.
  ///
  /// In en, this message translates to:
  /// **'Begin your practice'**
  String get onboarding_begin_practice;

  /// No description provided for @home_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get home_today;

  /// No description provided for @home_good_morning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get home_good_morning;

  /// No description provided for @home_good_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get home_good_afternoon;

  /// No description provided for @home_good_evening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get home_good_evening;

  /// No description provided for @home_meditationTitle.
  ///
  /// In en, this message translates to:
  /// **'Meditation'**
  String get home_meditationTitle;

  /// No description provided for @home_prayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer of the day'**
  String get home_prayerTitle;

  /// No description provided for @home_scripture.
  ///
  /// In en, this message translates to:
  /// **'Guided scripture'**
  String get home_scripture;

  /// No description provided for @home_meditation.
  ///
  /// In en, this message translates to:
  /// **'Guided meditation'**
  String get home_meditation;

  /// No description provided for @home_goDeeper.
  ///
  /// In en, this message translates to:
  /// **'Go deeper'**
  String get home_goDeeper;

  /// No description provided for @home_intention.
  ///
  /// In en, this message translates to:
  /// **'My intention for today'**
  String get home_intention;

  /// No description provided for @home_recitation.
  ///
  /// In en, this message translates to:
  /// **'Recitation'**
  String get home_recitation;

  /// No description provided for @home_overall_stats.
  ///
  /// In en, this message translates to:
  /// **'Overall stats'**
  String get home_overall_stats;

  /// No description provided for @home_plans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get home_plans;

  /// No description provided for @home_chants.
  ///
  /// In en, this message translates to:
  /// **'Chants'**
  String get home_chants;

  /// No description provided for @home_mala.
  ///
  /// In en, this message translates to:
  /// **'Mala'**
  String get home_mala;

  /// No description provided for @home_timer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get home_timer;

  /// No description provided for @preset_timers.
  ///
  /// In en, this message translates to:
  /// **'Preset timers'**
  String get preset_timers;

  /// No description provided for @timer_min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get timer_min;

  /// No description provided for @home_bringing.
  ///
  /// In en, this message translates to:
  /// **'Bringing it to life'**
  String get home_bringing;

  /// No description provided for @home_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get home_profile;

  /// No description provided for @home_hello_prefix.
  ///
  /// In en, this message translates to:
  /// **'Hello, '**
  String get home_hello_prefix;

  /// No description provided for @home_greeting_fallback_name.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get home_greeting_fallback_name;

  /// No description provided for @home_share_prompt.
  ///
  /// In en, this message translates to:
  /// **'Enjoying {appName}?'**
  String home_share_prompt(String appName);

  /// No description provided for @no_feature_content.
  ///
  /// In en, this message translates to:
  /// **'No featured content available'**
  String get no_feature_content;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get nav_explore;

  /// No description provided for @nav_texts.
  ///
  /// In en, this message translates to:
  /// **'Texts'**
  String get nav_texts;

  /// No description provided for @nav_learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get nav_learn;

  /// No description provided for @nav_practice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get nav_practice;

  /// No description provided for @nav_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_settings;

  /// No description provided for @nav_connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get nav_connect;

  /// No description provided for @nav_me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get nav_me;

  /// No description provided for @text_browseTheLibrary.
  ///
  /// In en, this message translates to:
  /// **'Browse the library'**
  String get text_browseTheLibrary;

  /// No description provided for @text_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get text_search;

  /// No description provided for @text_detail_rootText.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get text_detail_rootText;

  /// No description provided for @text_detail_commentaryText.
  ///
  /// In en, this message translates to:
  /// **'Commentary'**
  String get text_detail_commentaryText;

  /// No description provided for @text_toc_continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get text_toc_continueReading;

  /// No description provided for @text_toc_content.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get text_toc_content;

  /// No description provided for @text_toc_versions.
  ///
  /// In en, this message translates to:
  /// **'Versions'**
  String get text_toc_versions;

  /// No description provided for @text_commentary.
  ///
  /// In en, this message translates to:
  /// **'Commentaries'**
  String get text_commentary;

  /// No description provided for @text_translations.
  ///
  /// In en, this message translates to:
  /// **'Translations'**
  String get text_translations;

  /// No description provided for @text_close_translation.
  ///
  /// In en, this message translates to:
  /// **'Close translations'**
  String get text_close_translation;

  /// No description provided for @no_translation.
  ///
  /// In en, this message translates to:
  /// **'No translations found'**
  String get no_translation;

  /// No description provided for @text_close_commentary.
  ///
  /// In en, this message translates to:
  /// **'Close commentary'**
  String get text_close_commentary;

  /// No description provided for @commentary_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get commentary_total;

  /// No description provided for @show_more.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get show_more;

  /// No description provided for @show_less.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get show_less;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @read_more.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get read_more;

  /// No description provided for @no_content.
  ///
  /// In en, this message translates to:
  /// **'No content found'**
  String get no_content;

  /// No description provided for @no_version.
  ///
  /// In en, this message translates to:
  /// **'No versions found'**
  String get no_version;

  /// No description provided for @no_commentary.
  ///
  /// In en, this message translates to:
  /// **'No commentaries found'**
  String get no_commentary;

  /// No description provided for @no_commentary_message.
  ///
  /// In en, this message translates to:
  /// **'No commentaries available for this segment'**
  String get no_commentary_message;

  /// No description provided for @commentary_not_available_for_language.
  ///
  /// In en, this message translates to:
  /// **'{language} commentary not available'**
  String commentary_not_available_for_language(String language);

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @choose_image.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get choose_image;

  /// No description provided for @choose_bg_image.
  ///
  /// In en, this message translates to:
  /// **'Choose a background image'**
  String get choose_bg_image;

  /// No description provided for @create_image.
  ///
  /// In en, this message translates to:
  /// **'Create image'**
  String get create_image;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @customise_message.
  ///
  /// In en, this message translates to:
  /// **'Tap the customize icon to adjust text style'**
  String get customise_message;

  /// No description provided for @download_image.
  ///
  /// In en, this message translates to:
  /// **'Download image'**
  String get download_image;

  /// No description provided for @no_images_available.
  ///
  /// In en, this message translates to:
  /// **'No images available'**
  String get no_images_available;

  /// No description provided for @customise_text.
  ///
  /// In en, this message translates to:
  /// **'Customize text'**
  String get customise_text;

  /// No description provided for @text_size.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get text_size;

  /// No description provided for @text_color.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get text_color;

  /// No description provided for @text_shadow.
  ///
  /// In en, this message translates to:
  /// **'Text shadow'**
  String get text_shadow;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @practice_nav_title.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practice_nav_title;

  /// No description provided for @my_plans.
  ///
  /// In en, this message translates to:
  /// **'My plans'**
  String get my_plans;

  /// No description provided for @find_plans.
  ///
  /// In en, this message translates to:
  /// **'Find plans'**
  String get find_plans;

  /// No description provided for @browse_plans.
  ///
  /// In en, this message translates to:
  /// **'Browse plans'**
  String get browse_plans;

  /// No description provided for @plan_info.
  ///
  /// In en, this message translates to:
  /// **'Plan info'**
  String get plan_info;

  /// No description provided for @start_plan.
  ///
  /// In en, this message translates to:
  /// **'Start plan'**
  String get start_plan;

  /// No description provided for @start_reading.
  ///
  /// In en, this message translates to:
  /// **'Practice now'**
  String get start_reading;

  /// No description provided for @continue_plan.
  ///
  /// In en, this message translates to:
  /// **'Continue plan'**
  String get continue_plan;

  /// No description provided for @tibetan.
  ///
  /// In en, this message translates to:
  /// **'Tibetan'**
  String get tibetan;

  /// No description provided for @sanskrit.
  ///
  /// In en, this message translates to:
  /// **'Sanskrit'**
  String get sanskrit;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @classicalChinese.
  ///
  /// In en, this message translates to:
  /// **'Classical Chinese'**
  String get classicalChinese;

  /// No description provided for @pali.
  ///
  /// In en, this message translates to:
  /// **'Pali'**
  String get pali;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @dailyPracticeNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily practice reminder'**
  String get dailyPracticeNotificationTitle;

  /// No description provided for @timeForDailyPractice.
  ///
  /// In en, this message translates to:
  /// **'It\'s time for your practice session'**
  String get timeForDailyPractice;

  /// No description provided for @recitation_reminder.
  ///
  /// In en, this message translates to:
  /// **'Recitations reminder'**
  String get recitation_reminder;

  /// No description provided for @moment_to_pray.
  ///
  /// In en, this message translates to:
  /// **'Take a moment to pray'**
  String get moment_to_pray;

  /// No description provided for @plan_unenroll.
  ///
  /// In en, this message translates to:
  /// **'Unenroll'**
  String get plan_unenroll;

  /// No description provided for @unenroll_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unenroll in'**
  String get unenroll_confirmation;

  /// No description provided for @unenroll_message.
  ///
  /// In en, this message translates to:
  /// **'Your progress will be permanently lost and cannot be recovered'**
  String get unenroll_message;

  /// No description provided for @practice_plan.
  ///
  /// In en, this message translates to:
  /// **'Build a daily practice. Explore what fits you.'**
  String get practice_plan;

  /// No description provided for @search_plans.
  ///
  /// In en, this message translates to:
  /// **'Search plans...'**
  String get search_plans;

  /// No description provided for @search_for_plans.
  ///
  /// In en, this message translates to:
  /// **'Search for plans'**
  String get search_for_plans;

  /// No description provided for @no_plans_found.
  ///
  /// In en, this message translates to:
  /// **'No plans found'**
  String get no_plans_found;

  /// No description provided for @no_days_available.
  ///
  /// In en, this message translates to:
  /// **'No days found'**
  String get no_days_available;

  /// No description provided for @notification_turn_on.
  ///
  /// In en, this message translates to:
  /// **'Please turn on notifications'**
  String get notification_turn_on;

  /// No description provided for @notification_enable_message.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to receive reminders'**
  String get notification_enable_message;

  /// No description provided for @enable_notification.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enable_notification;

  /// No description provided for @notification_daily_practice.
  ///
  /// In en, this message translates to:
  /// **'Daily practice'**
  String get notification_daily_practice;

  /// No description provided for @notification_select_time.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get notification_select_time;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @notification_daily_recitation.
  ///
  /// In en, this message translates to:
  /// **'Daily recitations'**
  String get notification_daily_recitation;

  /// No description provided for @text_noContent.
  ///
  /// In en, this message translates to:
  /// **'No texts available in this language'**
  String get text_noContent;

  /// No description provided for @text_switchToTibetan.
  ///
  /// In en, this message translates to:
  /// **'Switch to Tibetan'**
  String get text_switchToTibetan;

  /// No description provided for @recitations_title.
  ///
  /// In en, this message translates to:
  /// **'Recitations'**
  String get recitations_title;

  /// No description provided for @recitations_my_recitations.
  ///
  /// In en, this message translates to:
  /// **'My recitations'**
  String get recitations_my_recitations;

  /// No description provided for @browse_recitations.
  ///
  /// In en, this message translates to:
  /// **'Browse recitations'**
  String get browse_recitations;

  /// No description provided for @recitations_search.
  ///
  /// In en, this message translates to:
  /// **'Search for recitations...'**
  String get recitations_search;

  /// No description provided for @recitations_search_for.
  ///
  /// In en, this message translates to:
  /// **'Search for recitations'**
  String get recitations_search_for;

  /// No description provided for @recitations_no_found.
  ///
  /// In en, this message translates to:
  /// **'No recitations founds'**
  String get recitations_no_found;

  /// No description provided for @recitations_saved.
  ///
  /// In en, this message translates to:
  /// **'Recitation saved'**
  String get recitations_saved;

  /// No description provided for @recitations_unsaved.
  ///
  /// In en, this message translates to:
  /// **'Recitation removed'**
  String get recitations_unsaved;

  /// No description provided for @recitations_no_content.
  ///
  /// In en, this message translates to:
  /// **'No recitations available'**
  String get recitations_no_content;

  /// No description provided for @recitations_no_saved.
  ///
  /// In en, this message translates to:
  /// **'No saved recitations'**
  String get recitations_no_saved;

  /// No description provided for @recitations_login_prompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your saved recitations'**
  String get recitations_login_prompt;

  /// No description provided for @recitations_save.
  ///
  /// In en, this message translates to:
  /// **'Save recitation'**
  String get recitations_save;

  /// No description provided for @recitations_unsave.
  ///
  /// In en, this message translates to:
  /// **'Unsave recitation'**
  String get recitations_unsave;

  /// No description provided for @recitations_translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get recitations_translation;

  /// No description provided for @no_available.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get no_available;

  /// No description provided for @recitations_no_data_message.
  ///
  /// In en, this message translates to:
  /// **'No recitations found'**
  String get recitations_no_data_message;

  /// No description provided for @recitations_show_translation.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get recitations_show_translation;

  /// No description provided for @recitations_hide_translation.
  ///
  /// In en, this message translates to:
  /// **'Hide translation'**
  String get recitations_hide_translation;

  /// No description provided for @recitations_show_transliteration.
  ///
  /// In en, this message translates to:
  /// **'Show transliteration'**
  String get recitations_show_transliteration;

  /// No description provided for @recitations_hide_transliteration.
  ///
  /// In en, this message translates to:
  /// **'Hide transliteration'**
  String get recitations_hide_transliteration;

  /// No description provided for @recitations_show_recitation.
  ///
  /// In en, this message translates to:
  /// **'Show recitation'**
  String get recitations_show_recitation;

  /// No description provided for @recitations_hide_recitation.
  ///
  /// In en, this message translates to:
  /// **'Hide recitation'**
  String get recitations_hide_recitation;

  /// No description provided for @recitations_show_adaptation.
  ///
  /// In en, this message translates to:
  /// **'Show adaptation'**
  String get recitations_show_adaptation;

  /// No description provided for @recitations_hide_adaptation.
  ///
  /// In en, this message translates to:
  /// **'Hide adaptation'**
  String get recitations_hide_adaptation;

  /// No description provided for @next_recitation.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next_recitation;

  /// No description provided for @settings_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_appearance;

  /// No description provided for @settings_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notifications;

  /// No description provided for @notification_settings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notification_settings;

  /// No description provided for @notification_section_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notification_section_notifications;

  /// No description provided for @notification_section_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get notification_section_categories;

  /// No description provided for @notification_section_alarms.
  ///
  /// In en, this message translates to:
  /// **'Alarms & reminders'**
  String get notification_section_alarms;

  /// No description provided for @notification_section_battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get notification_section_battery;

  /// No description provided for @notification_allow_title.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get notification_allow_title;

  /// No description provided for @notification_allow_subtitle_enabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are enabled for this app'**
  String get notification_allow_subtitle_enabled;

  /// No description provided for @notification_allow_subtitle_disabled.
  ///
  /// In en, this message translates to:
  /// **'Permission needed. Tap to grant in Settings.'**
  String get notification_allow_subtitle_disabled;

  /// No description provided for @notification_allow_subtitle_paused.
  ///
  /// In en, this message translates to:
  /// **'Reminders are paused. Tap to resume.'**
  String get notification_allow_subtitle_paused;

  /// No description provided for @notification_routine_title.
  ///
  /// In en, this message translates to:
  /// **'Routine reminders'**
  String get notification_routine_title;

  /// No description provided for @notification_routine_subtitle_enabled.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders for your practice blocks'**
  String get notification_routine_subtitle_enabled;

  /// No description provided for @notification_routine_subtitle_disabled.
  ///
  /// In en, this message translates to:
  /// **'Routine reminders are paused. Tap to resume.'**
  String get notification_routine_subtitle_disabled;

  /// No description provided for @notification_alarms_title.
  ///
  /// In en, this message translates to:
  /// **'Exact reminder times'**
  String get notification_alarms_title;

  /// No description provided for @notification_alarms_subtitle_enabled.
  ///
  /// In en, this message translates to:
  /// **'Reminders are sent at the time you set'**
  String get notification_alarms_subtitle_enabled;

  /// No description provided for @notification_alarms_subtitle_disabled.
  ///
  /// In en, this message translates to:
  /// **'Reminders may arrive late or be skipped. Tap to fix'**
  String get notification_alarms_subtitle_disabled;

  /// No description provided for @notification_battery_title.
  ///
  /// In en, this message translates to:
  /// **'Background reminders'**
  String get notification_battery_title;

  /// No description provided for @notification_battery_subtitle_enabled.
  ///
  /// In en, this message translates to:
  /// **'Your reminders are sent on time, even when the app is closed.'**
  String get notification_battery_subtitle_enabled;

  /// No description provided for @notification_battery_subtitle_disabled.
  ///
  /// In en, this message translates to:
  /// **'Some Android phones pause background apps to save battery, which can delay or skip your reminders. Tap to keep yours running.'**
  String get notification_battery_subtitle_disabled;

  /// No description provided for @notification_recitation_title.
  ///
  /// In en, this message translates to:
  /// **'Recitations reminder'**
  String get notification_recitation_title;

  /// No description provided for @notification_recitation_subtitle_enabled.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders for your recitations'**
  String get notification_recitation_subtitle_enabled;

  /// No description provided for @notification_recitation_subtitle_disabled.
  ///
  /// In en, this message translates to:
  /// **'Recitation reminders are paused. Tap to resume.'**
  String get notification_recitation_subtitle_disabled;

  /// No description provided for @notification_alarms_info_title.
  ///
  /// In en, this message translates to:
  /// **'About exact reminder times'**
  String get notification_alarms_info_title;

  /// No description provided for @notification_alarms_info_body.
  ///
  /// In en, this message translates to:
  /// **'This permission lets the app fire reminders at the exact time you set. Without it, your reminders may arrive late or be skipped entirely when your phone is idle.'**
  String get notification_alarms_info_body;

  /// No description provided for @notification_battery_info_title.
  ///
  /// In en, this message translates to:
  /// **'About background reminders'**
  String get notification_battery_info_title;

  /// No description provided for @notification_battery_info_body.
  ///
  /// In en, this message translates to:
  /// **'Some Android phones pause background apps to save battery, which can delay or cancel your scheduled reminders. Exempting the app keeps your reminders reliably on time.'**
  String get notification_battery_info_body;

  /// No description provided for @notification_snack_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked. Turn them on in Settings'**
  String get notification_snack_permission_denied;

  /// No description provided for @notification_snack_disable_in_settings.
  ///
  /// In en, this message translates to:
  /// **'Turn off notifications in Settings.'**
  String get notification_snack_disable_in_settings;

  /// No description provided for @notification_snack_ios_manage_in_settings.
  ///
  /// In en, this message translates to:
  /// **'Manage notifications in Settings.'**
  String get notification_snack_ios_manage_in_settings;

  /// No description provided for @notification_snack_disable_alarms_in_settings.
  ///
  /// In en, this message translates to:
  /// **'Turn off alarms & reminders in Settings.'**
  String get notification_snack_disable_alarms_in_settings;

  /// No description provided for @notification_snack_battery_reenable.
  ///
  /// In en, this message translates to:
  /// **'Restore battery optimization in Settings → Battery.'**
  String get notification_snack_battery_reenable;

  /// No description provided for @profile_default_name.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profile_default_name;

  /// No description provided for @profile_default_bio.
  ///
  /// In en, this message translates to:
  /// **'Welcome to WeBuddhist'**
  String get profile_default_bio;

  /// No description provided for @profile_guest_title.
  ///
  /// In en, this message translates to:
  /// **'Guest user'**
  String get profile_guest_title;

  /// No description provided for @profile_guest_subtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re browsing as a guest'**
  String get profile_guest_subtitle;

  /// No description provided for @profile_guest_benefits_header.
  ///
  /// In en, this message translates to:
  /// **'Sign in to unlock:'**
  String get profile_guest_benefits_header;

  /// No description provided for @profile_guest_benefit_save_progress.
  ///
  /// In en, this message translates to:
  /// **'Save your progress'**
  String get profile_guest_benefit_save_progress;

  /// No description provided for @profile_guest_benefit_personalized.
  ///
  /// In en, this message translates to:
  /// **'Personalized content'**
  String get profile_guest_benefit_personalized;

  /// No description provided for @profile_guest_benefit_notifications.
  ///
  /// In en, this message translates to:
  /// **'Custom notifications'**
  String get profile_guest_benefit_notifications;

  /// No description provided for @auth_drawer_title.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue'**
  String get auth_drawer_title;

  /// No description provided for @auth_drawer_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Continue your practice on any device, wherever you go.'**
  String get auth_drawer_subtitle;

  /// No description provided for @routine_delete_block_message.
  ///
  /// In en, this message translates to:
  /// **'The time block and all its items will be removed'**
  String get routine_delete_block_message;

  /// No description provided for @something_went_wrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again'**
  String get something_went_wrong;

  /// No description provided for @onboarding_quote_citation.
  ///
  /// In en, this message translates to:
  /// **'— Dhammapada 122'**
  String get onboarding_quote_citation;

  /// No description provided for @onboarding_traditions_question.
  ///
  /// In en, this message translates to:
  /// **'Which traditions\ndo you follow?'**
  String get onboarding_traditions_question;

  /// No description provided for @onboarding_select_all.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get onboarding_select_all;

  /// No description provided for @onboarding_event_enrollment_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to enroll you. Check your connection and try again'**
  String get onboarding_event_enrollment_error;

  /// No description provided for @onboarding_event_question.
  ///
  /// In en, this message translates to:
  /// **'Join an\nevent?'**
  String get onboarding_event_question;

  /// No description provided for @onboarding_event_optional.
  ///
  /// In en, this message translates to:
  /// **'Optional · Tap to enroll'**
  String get onboarding_event_optional;

  /// No description provided for @onboarding_event_duration.
  ///
  /// In en, this message translates to:
  /// **'{description} · {days} days'**
  String onboarding_event_duration(String description, int days);

  /// No description provided for @onboarding_event_reminder_note.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a daily reminder at 7:30 AM. (Change anytime.)'**
  String get onboarding_event_reminder_note;

  /// No description provided for @tradition_theravada.
  ///
  /// In en, this message translates to:
  /// **'Theravada'**
  String get tradition_theravada;

  /// No description provided for @tradition_zen.
  ///
  /// In en, this message translates to:
  /// **'Zen'**
  String get tradition_zen;

  /// No description provided for @tradition_tibetan_buddhism.
  ///
  /// In en, this message translates to:
  /// **'Tibetan Buddhism'**
  String get tradition_tibetan_buddhism;

  /// No description provided for @tradition_pure_land.
  ///
  /// In en, this message translates to:
  /// **'Pure Land'**
  String get tradition_pure_land;

  /// No description provided for @tradition_ambedkar_buddhism.
  ///
  /// In en, this message translates to:
  /// **'Ambedkar Buddhism'**
  String get tradition_ambedkar_buddhism;

  /// No description provided for @plan_go_to_practice.
  ///
  /// In en, this message translates to:
  /// **'Go to practice'**
  String get plan_go_to_practice;

  /// No description provided for @plan_starts_soon_title.
  ///
  /// In en, this message translates to:
  /// **'Starts soon'**
  String get plan_starts_soon_title;

  /// No description provided for @plan_joining_late_title.
  ///
  /// In en, this message translates to:
  /// **'Joining after start date'**
  String get plan_joining_late_title;

  /// No description provided for @got_it.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get got_it;

  /// No description provided for @plan_no_tasks_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load tasks'**
  String get plan_no_tasks_error;

  /// No description provided for @plan_day_tasks_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load tasks'**
  String get plan_day_tasks_load_error;

  /// No description provided for @plans_empty_title.
  ///
  /// In en, this message translates to:
  /// **'More is on the way'**
  String get plans_empty_title;

  /// No description provided for @plans_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Our library is growing. Check back soon.'**
  String get plans_empty_subtitle;

  /// No description provided for @find_plans_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load.\nCheck your connection and try again'**
  String get find_plans_load_error;

  /// No description provided for @connect_coming_soon_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Teachers, communities, challenges, and events to support you on the path'**
  String get connect_coming_soon_subtitle;

  /// No description provided for @explore_coming_soon_subtitle.
  ///
  /// In en, this message translates to:
  /// **'A curated space to discover practices, teachings, and community events'**
  String get explore_coming_soon_subtitle;

  /// No description provided for @learn_coming_soon_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal study plans, designed to fit into everyday life'**
  String get learn_coming_soon_subtitle;

  /// No description provided for @creator_featured_plan.
  ///
  /// In en, this message translates to:
  /// **'Featured plan'**
  String get creator_featured_plan;

  /// No description provided for @audio_init_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to initialize audio player. Check your connection and try again'**
  String get audio_init_error;

  /// No description provided for @meditation_audio_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load. Check your connection and try again'**
  String get meditation_audio_load_error;

  /// No description provided for @prayer_audio_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load audio. Check your connection and try again'**
  String get prayer_audio_load_error;

  /// No description provided for @home_no_series_found.
  ///
  /// In en, this message translates to:
  /// **'No series found'**
  String get home_no_series_found;

  /// No description provided for @home_no_tags_found.
  ///
  /// In en, this message translates to:
  /// **'No tags found'**
  String get home_no_tags_found;

  /// No description provided for @home_celebrated_by.
  ///
  /// In en, this message translates to:
  /// **'Celebrated by: '**
  String get home_celebrated_by;

  /// No description provided for @home_default_duration.
  ///
  /// In en, this message translates to:
  /// **'1-2 min'**
  String get home_default_duration;

  /// No description provided for @reader_settings_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Reader settings'**
  String get reader_settings_tooltip;

  /// No description provided for @reader_font_size_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get reader_font_size_tooltip;

  /// No description provided for @reader_about_version_tooltip.
  ///
  /// In en, this message translates to:
  /// **'About this version'**
  String get reader_about_version_tooltip;

  /// No description provided for @reader_version_title.
  ///
  /// In en, this message translates to:
  /// **'Version · {language}'**
  String reader_version_title(String language);

  /// No description provided for @reader_script_title.
  ///
  /// In en, this message translates to:
  /// **'Script · {language}'**
  String reader_script_title(String language);

  /// No description provided for @reader_versions_load_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to load versions'**
  String get reader_versions_load_error;

  /// No description provided for @reader_scripts_load_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to load scripts'**
  String get reader_scripts_load_error;

  /// No description provided for @reader_languages_load_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to load languages'**
  String get reader_languages_load_error;

  /// No description provided for @reader_no_versions_in_language.
  ///
  /// In en, this message translates to:
  /// **'No versions available in {language}'**
  String reader_no_versions_in_language(String language);

  /// No description provided for @reader_no_scripts_in_language.
  ///
  /// In en, this message translates to:
  /// **'No scripts available in {language}'**
  String reader_no_scripts_in_language(String language);

  /// No description provided for @reader_no_languages.
  ///
  /// In en, this message translates to:
  /// **'No languages available for this text'**
  String get reader_no_languages;

  /// No description provided for @reader_published_by.
  ///
  /// In en, this message translates to:
  /// **'Published by'**
  String get reader_published_by;

  /// No description provided for @reader_published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get reader_published;

  /// No description provided for @reader_license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get reader_license;

  /// No description provided for @reader_version_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get reader_version_type;

  /// No description provided for @reader_version_details_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load version details'**
  String get reader_version_details_load_error;

  /// No description provided for @reader_no_version_info.
  ///
  /// In en, this message translates to:
  /// **'No additional information is available for this version'**
  String get reader_no_version_info;

  /// No description provided for @recitation_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Recitation content is currently unavailable.\nTry again later or contact support'**
  String get recitation_unavailable;

  /// No description provided for @recitation_sign_in_required.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access this recitation'**
  String get recitation_sign_in_required;

  /// No description provided for @my_recitations_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load.\nCheck your connection and try again'**
  String get my_recitations_load_error;

  /// No description provided for @recitations_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load recitations.\nTry again later'**
  String get recitations_load_error;

  /// No description provided for @story_audio_label.
  ///
  /// In en, this message translates to:
  /// **'Audio story'**
  String get story_audio_label;

  /// No description provided for @story_image_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load image'**
  String get story_image_load_error;

  /// No description provided for @story_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading story...'**
  String get story_loading;

  /// No description provided for @story_barrier_label.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get story_barrier_label;

  /// No description provided for @text_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Type to search'**
  String get text_search_hint;

  /// No description provided for @text_search_press_button.
  ///
  /// In en, this message translates to:
  /// **'Press search button to search'**
  String get text_search_press_button;

  /// No description provided for @text_search_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to perform search.\nPlease try again'**
  String get text_search_error;

  /// No description provided for @collections_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load.\nCheck your connection and try again'**
  String get collections_load_error;

  /// No description provided for @failed_load_collections.
  ///
  /// In en, this message translates to:
  /// **'Failed to load collections'**
  String get failed_load_collections;

  /// No description provided for @unknown_error.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknown_error;

  /// No description provided for @commentary_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'No commentaries are available for this segment'**
  String get commentary_empty_subtitle;

  /// No description provided for @image_share_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to share: {error}'**
  String image_share_error(String error);

  /// No description provided for @create_image_capture_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to create image. Please try again'**
  String get create_image_capture_error;

  /// No description provided for @create_image_share_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to share. Please try again'**
  String get create_image_share_error;

  /// No description provided for @create_image_save_success.
  ///
  /// In en, this message translates to:
  /// **'Image saved'**
  String get create_image_save_success;

  /// No description provided for @create_image_save_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to save image. Check that the app has photo access, or try again'**
  String get create_image_save_error;

  /// No description provided for @create_image_download_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to download your image. Please try again'**
  String get create_image_download_error;

  /// No description provided for @create_image_customize_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get create_image_customize_tooltip;

  /// No description provided for @create_image_text_too_long.
  ///
  /// In en, this message translates to:
  /// **'Text is too long to increase font size'**
  String get create_image_text_too_long;

  /// No description provided for @version_search_no_results.
  ///
  /// In en, this message translates to:
  /// **'No versions found for \"{query}\"'**
  String version_search_no_results(String query);

  /// No description provided for @my_plans_sign_in_prompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your plans'**
  String get my_plans_sign_in_prompt;

  /// No description provided for @plan_starts_soon_message.
  ///
  /// In en, this message translates to:
  /// **'Starts on {date}. You can browse the content now'**
  String plan_starts_soon_message(String date);

  /// No description provided for @plan_joining_late_message.
  ///
  /// In en, this message translates to:
  /// **'Started on {date}. Feel free to complete previous days\' tasks'**
  String plan_joining_late_message(String date);

  /// No description provided for @settings_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settings_account;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get select_language;

  /// No description provided for @logout_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logout_confirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @feedback_wishlist.
  ///
  /// In en, this message translates to:
  /// **'Community hub'**
  String get feedback_wishlist;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @plans_created.
  ///
  /// In en, this message translates to:
  /// **'Plan created'**
  String get plans_created;

  /// No description provided for @ask_ai.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get ask_ai;

  /// No description provided for @ai_chat_history.
  ///
  /// In en, this message translates to:
  /// **'Chat history'**
  String get ai_chat_history;

  /// No description provided for @ai_buddhist_assistant.
  ///
  /// In en, this message translates to:
  /// **'Build your daily rhythm. Set times, and we\'ll remind you to practice'**
  String get ai_buddhist_assistant;

  /// No description provided for @ai_new_chat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get ai_new_chat;

  /// No description provided for @ai_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get ai_retry;

  /// No description provided for @ai_dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get ai_dismiss;

  /// No description provided for @ai_sign_in_prompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use the Buddhist AI Assistant'**
  String get ai_sign_in_prompt;

  /// No description provided for @ai_explore_wisdom.
  ///
  /// In en, this message translates to:
  /// **'Explore Buddhist wisdom'**
  String get ai_explore_wisdom;

  /// No description provided for @ai_suggestion_self.
  ///
  /// In en, this message translates to:
  /// **'What is self?'**
  String get ai_suggestion_self;

  /// No description provided for @ai_suggestion_enlightenment.
  ///
  /// In en, this message translates to:
  /// **'How can you attain enlightenment?'**
  String get ai_suggestion_enlightenment;

  /// No description provided for @ai_ask_question.
  ///
  /// In en, this message translates to:
  /// **'Ask a question...'**
  String get ai_ask_question;

  /// No description provided for @ai_loading_conversation.
  ///
  /// In en, this message translates to:
  /// **'Loading conversation...'**
  String get ai_loading_conversation;

  /// No description provided for @ai_search_chats.
  ///
  /// In en, this message translates to:
  /// **'Search for chats'**
  String get ai_search_chats;

  /// No description provided for @ai_chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get ai_chats;

  /// No description provided for @ai_chat_deleted.
  ///
  /// In en, this message translates to:
  /// **'Chat deleted'**
  String get ai_chat_deleted;

  /// No description provided for @ai_no_conversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get ai_no_conversations;

  /// No description provided for @ai_start_new_chat.
  ///
  /// In en, this message translates to:
  /// **'Start a new chat to begin.'**
  String get ai_start_new_chat;

  /// No description provided for @ai_delete_chat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get ai_delete_chat;

  /// No description provided for @ai_delete_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this chat?'**
  String get ai_delete_confirmation;

  /// No description provided for @ai_delete_warning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get ai_delete_warning;

  /// No description provided for @ai_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get ai_confirm;

  /// No description provided for @ai_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get ai_delete;

  /// No description provided for @ai_greeting.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}'**
  String ai_greeting(String name);

  /// No description provided for @ai_text_not_found.
  ///
  /// In en, this message translates to:
  /// **'Text not found.'**
  String get ai_text_not_found;

  /// No description provided for @ai_text_not_found_message.
  ///
  /// In en, this message translates to:
  /// **'We don\'t have \"{title}\" in our library yet.\n\nTry a different title, or ask another way'**
  String ai_text_not_found_message(String title);

  /// No description provided for @ai_sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get ai_sources;

  /// No description provided for @ai_sources_count.
  ///
  /// In en, this message translates to:
  /// **'{count} sources'**
  String ai_sources_count(int count);

  /// No description provided for @search_no_results.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\"'**
  String search_no_results(String query);

  /// No description provided for @search_show_more.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get search_show_more;

  /// No description provided for @search_contents.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get search_contents;

  /// No description provided for @search_titles.
  ///
  /// In en, this message translates to:
  /// **'Titles'**
  String get search_titles;

  /// No description provided for @search_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get search_all;

  /// No description provided for @search_author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get search_author;

  /// No description provided for @search_tab_ai_mode.
  ///
  /// In en, this message translates to:
  /// **'AI mode'**
  String get search_tab_ai_mode;

  /// No description provided for @search_error.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String search_error(String message);

  /// No description provided for @search_retrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying...'**
  String get search_retrying;

  /// No description provided for @search_no_titles_found.
  ///
  /// In en, this message translates to:
  /// **'No titles found for \"{query}\"'**
  String search_no_titles_found(String query);

  /// No description provided for @search_no_contents_found.
  ///
  /// In en, this message translates to:
  /// **'No contents found for \"{query}\"'**
  String search_no_contents_found(String query);

  /// No description provided for @search_no_authors_found.
  ///
  /// In en, this message translates to:
  /// **'No authors found for \"{query}\"'**
  String search_no_authors_found(String query);

  /// No description provided for @search_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get search_coming_soon;

  /// No description provided for @search_buddhist_texts.
  ///
  /// In en, this message translates to:
  /// **'Search Buddhist texts...'**
  String get search_buddhist_texts;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @comingSoonHeadline.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonHeadline;

  /// No description provided for @routine_title.
  ///
  /// In en, this message translates to:
  /// **'My practices'**
  String get routine_title;

  /// No description provided for @routine_empty_title.
  ///
  /// In en, this message translates to:
  /// **'Practices'**
  String get routine_empty_title;

  /// No description provided for @routine_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get routine_edit;

  /// No description provided for @routine_empty_description.
  ///
  /// In en, this message translates to:
  /// **'Explore more teachings and practices to add to your routine'**
  String get routine_empty_description;

  /// No description provided for @routine_build.
  ///
  /// In en, this message translates to:
  /// **'Build your routine'**
  String get routine_build;

  /// No description provided for @routine_session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get routine_session;

  /// No description provided for @routine_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get routine_time;

  /// No description provided for @routine_notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get routine_notification;

  /// No description provided for @routine_save.
  ///
  /// In en, this message translates to:
  /// **'Save routine'**
  String get routine_save;

  /// No description provided for @routine_morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get routine_morning;

  /// No description provided for @routine_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get routine_afternoon;

  /// No description provided for @routine_evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get routine_evening;

  /// No description provided for @routine_add_session.
  ///
  /// In en, this message translates to:
  /// **'Add to session'**
  String get routine_add_session;

  /// No description provided for @routine_select_time.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get routine_select_time;

  /// No description provided for @routine_remind_me.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get routine_remind_me;

  /// No description provided for @routine_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit your routine'**
  String get routine_edit_title;

  /// No description provided for @routine_delete_block.
  ///
  /// In en, this message translates to:
  /// **'Remove block?'**
  String get routine_delete_block;

  /// No description provided for @routine_delete_time_block.
  ///
  /// In en, this message translates to:
  /// **'Remove time block'**
  String get routine_delete_time_block;

  /// No description provided for @routine_add_plan.
  ///
  /// In en, this message translates to:
  /// **'Add plan'**
  String get routine_add_plan;

  /// No description provided for @routine_add_recitation.
  ///
  /// In en, this message translates to:
  /// **'Add recitation'**
  String get routine_add_recitation;

  /// No description provided for @routine_add_plan_to_routine.
  ///
  /// In en, this message translates to:
  /// **'Add to routine'**
  String get routine_add_plan_to_routine;

  /// No description provided for @routine_go_to_practice.
  ///
  /// In en, this message translates to:
  /// **'Go to practice'**
  String get routine_go_to_practice;

  /// No description provided for @routine_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load. Check your connection and try again'**
  String get routine_load_error;

  /// No description provided for @routine_empty_block_title_singular.
  ///
  /// In en, this message translates to:
  /// **'Empty time block'**
  String get routine_empty_block_title_singular;

  /// No description provided for @routine_empty_block_title_plural.
  ///
  /// In en, this message translates to:
  /// **'Empty time blocks ({count})'**
  String routine_empty_block_title_plural(int count);

  /// No description provided for @routine_empty_block_message_singular.
  ///
  /// In en, this message translates to:
  /// **'This time block is empty. Add an item, or remove it from your routine?'**
  String get routine_empty_block_message_singular;

  /// No description provided for @routine_empty_block_message_plural.
  ///
  /// In en, this message translates to:
  /// **'{count} time blocks are empty. Add items, or remove them from your routine?'**
  String routine_empty_block_message_plural(int count);

  /// No description provided for @routine_empty_block_add_items.
  ///
  /// In en, this message translates to:
  /// **'Add items'**
  String get routine_empty_block_add_items;

  /// No description provided for @routine_empty_block_delete_singular.
  ///
  /// In en, this message translates to:
  /// **'Remove block'**
  String get routine_empty_block_delete_singular;

  /// No description provided for @routine_empty_block_delete_plural.
  ///
  /// In en, this message translates to:
  /// **'Remove blocks'**
  String get routine_empty_block_delete_plural;

  /// No description provided for @routine_notification_title.
  ///
  /// In en, this message translates to:
  /// **'Make practice a habit'**
  String get routine_notification_title;

  /// No description provided for @routine_notification_description.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications so we can remind you to practice'**
  String get routine_notification_description;

  /// No description provided for @routine_notification_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get routine_notification_enable;

  /// No description provided for @routine_notification_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get routine_notification_skip;

  /// No description provided for @routine_time_adjusted.
  ///
  /// In en, this message translates to:
  /// **'Adjusted to {time} ({gap}-min minimum gap)'**
  String routine_time_adjusted(String time, int gap);

  /// No description provided for @routine_add_block_label.
  ///
  /// In en, this message translates to:
  /// **'Time block'**
  String get routine_add_block_label;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @profileError.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get profileError;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get pleaseTryAgain;

  /// No description provided for @successfully.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successfully;

  /// No description provided for @failedTo.
  ///
  /// In en, this message translates to:
  /// **'Failed to'**
  String get failedTo;

  /// No description provided for @unableTo.
  ///
  /// In en, this message translates to:
  /// **'Unable to'**
  String get unableTo;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @noContentAvailable.
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get noContentAvailable;

  /// No description provided for @missingParameters.
  ///
  /// In en, this message translates to:
  /// **'Missing required parameters'**
  String get missingParameters;

  /// No description provided for @invalidParameters.
  ///
  /// In en, this message translates to:
  /// **'Invalid parameters'**
  String get invalidParameters;

  /// No description provided for @cannotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Can\'t open this link'**
  String get cannotOpenLink;

  /// No description provided for @invalidUrlFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL format'**
  String get invalidUrlFormat;

  /// No description provided for @cannotOpenEmail.
  ///
  /// In en, this message translates to:
  /// **'Can\'t open this email'**
  String get cannotOpenEmail;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get invalidEmailFormat;

  /// No description provided for @unableToLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load. Check your connection and try again'**
  String get unableToLoad;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Check your connection and try again'**
  String get somethingWrong;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get typing;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get searchResults;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation?'**
  String get deleteConversation;

  /// No description provided for @errorOops.
  ///
  /// In en, this message translates to:
  /// **'Oops. Please try again'**
  String get errorOops;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @tabAuthors.
  ///
  /// In en, this message translates to:
  /// **'Authors'**
  String get tabAuthors;

  /// No description provided for @tabContents.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get tabContents;

  /// No description provided for @tabTitles.
  ///
  /// In en, this message translates to:
  /// **'Titles'**
  String get tabTitles;

  /// No description provided for @option1.
  ///
  /// In en, this message translates to:
  /// **'Option 1'**
  String get option1;

  /// No description provided for @option2.
  ///
  /// In en, this message translates to:
  /// **'Option 2'**
  String get option2;

  /// No description provided for @option3.
  ///
  /// In en, this message translates to:
  /// **'Option 3'**
  String get option3;

  /// No description provided for @languageTibetan.
  ///
  /// In en, this message translates to:
  /// **'བོད་ཡིག'**
  String get languageTibetan;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks available'**
  String get noTasks;

  /// No description provided for @taskNotFound.
  ///
  /// In en, this message translates to:
  /// **'Task not found'**
  String get taskNotFound;

  /// No description provided for @updateTaskError.
  ///
  /// In en, this message translates to:
  /// **'Unable to update task status'**
  String get updateTaskError;

  /// No description provided for @enrollSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully enrolled in {planTitle}'**
  String enrollSuccess(String planTitle);

  /// No description provided for @enrollError.
  ///
  /// In en, this message translates to:
  /// **'Unable to enroll you. Check your connection and try again'**
  String get enrollError;

  /// No description provided for @enrollErrorDetail.
  ///
  /// In en, this message translates to:
  /// **'Unable to enroll you. Check your connection and try again'**
  String enrollErrorDetail(String error);

  /// No description provided for @unenrollSuccess.
  ///
  /// In en, this message translates to:
  /// **'You have unenrolled in {planTitle}'**
  String unenrollSuccess(String planTitle);

  /// No description provided for @unenrollError.
  ///
  /// In en, this message translates to:
  /// **'Unable to unenroll you. Check your connection and try again'**
  String get unenrollError;

  /// No description provided for @unenrollGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Check your connection and try again'**
  String get unenrollGenericError;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'This is no longer available. Edit your routine to update.'**
  String get notFound;

  /// No description provided for @noTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'No available time slots. Try removing a block first'**
  String get noTimeSlot;

  /// No description provided for @maxBlocks.
  ///
  /// In en, this message translates to:
  /// **'Maximum of {max} time blocks reached'**
  String maxBlocks(int max);

  /// No description provided for @duplicateItem.
  ///
  /// In en, this message translates to:
  /// **'This item is already in the block'**
  String get duplicateItem;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item?'**
  String get removeItem;

  /// No description provided for @removeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'\"{itemName}\" will be removed from this block'**
  String removeConfirmation(String itemName);

  /// No description provided for @shareError.
  ///
  /// In en, this message translates to:
  /// **'Unable to share. Please try again'**
  String shareError(String error);

  /// No description provided for @updateOrderError.
  ///
  /// In en, this message translates to:
  /// **'Unable to update order. Please try again'**
  String get updateOrderError;

  /// No description provided for @noCollections.
  ///
  /// In en, this message translates to:
  /// **'No collections available'**
  String get noCollections;

  /// No description provided for @loadCollectionsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load. Check your connection and try again'**
  String get loadCollectionsError;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load. Check your connection and try again'**
  String get loadFailed;

  /// No description provided for @captureError.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture QR code. Please try again'**
  String get captureError;

  /// No description provided for @qrShareError.
  ///
  /// In en, this message translates to:
  /// **'Unable to share QR code. Try again later'**
  String get qrShareError;

  /// No description provided for @errorDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorDetail(String error);

  /// No description provided for @text_qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get text_qrCode;

  /// No description provided for @missedDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 missed days} =1{1 missed day} other{{count} missed days}}'**
  String missedDaysCount(int count);

  /// No description provided for @plan_enrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get plan_enrolled;

  /// No description provided for @plan_status_on_track.
  ///
  /// In en, this message translates to:
  /// **'On track!'**
  String get plan_status_on_track;

  /// No description provided for @start_now.
  ///
  /// In en, this message translates to:
  /// **'Start now'**
  String get start_now;

  /// No description provided for @plan_enroll.
  ///
  /// In en, this message translates to:
  /// **'Enroll'**
  String get plan_enroll;

  /// No description provided for @plan_starts_on.
  ///
  /// In en, this message translates to:
  /// **'Starts {date}'**
  String plan_starts_on(String date);

  /// No description provided for @show_second_version.
  ///
  /// In en, this message translates to:
  /// **'Show second version'**
  String get show_second_version;

  /// No description provided for @enable_add_msg.
  ///
  /// In en, this message translates to:
  /// **'Enable to add a translation or transliteration alongside the main text'**
  String get enable_add_msg;

  /// No description provided for @main_version.
  ///
  /// In en, this message translates to:
  /// **'Main version'**
  String get main_version;

  /// No description provided for @second_version.
  ///
  /// In en, this message translates to:
  /// **'Second version'**
  String get second_version;

  /// No description provided for @second_version_msg.
  ///
  /// In en, this message translates to:
  /// **'The second version will appear below each verse of the main text'**
  String get second_version_msg;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Versions'**
  String get version;

  /// No description provided for @parallel_version.
  ///
  /// In en, this message translates to:
  /// **'Parallel version'**
  String get parallel_version;

  /// No description provided for @version_not_available.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get version_not_available;

  /// No description provided for @read_full_text.
  ///
  /// In en, this message translates to:
  /// **'Read full text'**
  String get read_full_text;

  /// No description provided for @reader_source_label.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get reader_source_label;

  /// No description provided for @reader_license_label.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get reader_license_label;

  /// No description provided for @know_more.
  ///
  /// In en, this message translates to:
  /// **'Know more'**
  String get know_more;

  /// No description provided for @series_stats.
  ///
  /// In en, this message translates to:
  /// **'{planCount} PLANS · {totalDays} DAYS'**
  String series_stats(int planCount, int totalDays);

  /// No description provided for @force_update_title.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get force_update_title;

  /// No description provided for @force_update_message.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is available. Please update to continue'**
  String get force_update_message;

  /// No description provided for @force_update_button.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get force_update_button;

  /// No description provided for @settings_section_personalisation.
  ///
  /// In en, this message translates to:
  /// **'PERSONALIZATION'**
  String get settings_section_personalisation;

  /// No description provided for @settings_section_more.
  ///
  /// In en, this message translates to:
  /// **'MORE'**
  String get settings_section_more;

  /// No description provided for @settings_section_account.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get settings_section_account;

  /// No description provided for @settings_edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get settings_edit_profile;

  /// No description provided for @settings_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_theme;

  /// No description provided for @settings_notification_row.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notification_row;

  /// No description provided for @settings_feedback_row.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get settings_feedback_row;

  /// No description provided for @edit_profile_title.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get edit_profile_title;

  /// No description provided for @edit_profile_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get edit_profile_save;

  /// No description provided for @edit_profile_first_name.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get edit_profile_first_name;

  /// No description provided for @edit_profile_last_name.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get edit_profile_last_name;

  /// No description provided for @edit_profile_bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get edit_profile_bio;

  /// No description provided for @edit_profile_bio_hint.
  ///
  /// In en, this message translates to:
  /// **'Share a little about yourself'**
  String get edit_profile_bio_hint;

  /// No description provided for @edit_profile_delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get edit_profile_delete_account;

  /// No description provided for @edit_profile_photo_not_uploaded.
  ///
  /// In en, this message translates to:
  /// **'Photo not uploaded'**
  String get edit_profile_photo_not_uploaded;

  /// No description provided for @edit_profile_photo_too_large.
  ///
  /// In en, this message translates to:
  /// **'Image is too large. Please choose a photo under 1 MB and try again'**
  String get edit_profile_photo_too_large;

  /// No description provided for @edit_profile_photo_upload_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not upload your photo. Please try again'**
  String get edit_profile_photo_upload_failed;

  /// No description provided for @edit_profile_choose_from_library.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get edit_profile_choose_from_library;

  /// No description provided for @edit_profile_take_photo.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get edit_profile_take_photo;

  /// No description provided for @edit_profile_offline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Connect to the internet and try again'**
  String get edit_profile_offline;

  /// No description provided for @edit_profile_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your changes. Please try again'**
  String get edit_profile_save_failed;

  /// No description provided for @username_label.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username_label;

  /// No description provided for @username_taken.
  ///
  /// In en, this message translates to:
  /// **'Someone already used this name'**
  String get username_taken;

  /// No description provided for @username_available_label.
  ///
  /// In en, this message translates to:
  /// **'Available: '**
  String get username_available_label;

  /// No description provided for @username_check_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to check username. Try again'**
  String get username_check_error;

  /// No description provided for @username_invalid_format.
  ///
  /// In en, this message translates to:
  /// **'Invalid username format'**
  String get username_invalid_format;

  /// No description provided for @username_min_length.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get username_min_length;

  /// No description provided for @username_max_length.
  ///
  /// In en, this message translates to:
  /// **'Username must be 30 characters or less'**
  String get username_max_length;

  /// No description provided for @username_no_spaces.
  ///
  /// In en, this message translates to:
  /// **'Username cannot contain spaces'**
  String get username_no_spaces;

  /// No description provided for @username_invalid_chars.
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, _ . - are allowed'**
  String get username_invalid_chars;

  /// No description provided for @username_must_start_alphanumeric.
  ///
  /// In en, this message translates to:
  /// **'Username must start with a letter or number'**
  String get username_must_start_alphanumeric;

  /// No description provided for @username_must_end_alphanumeric.
  ///
  /// In en, this message translates to:
  /// **'Username must end with a letter or number'**
  String get username_must_end_alphanumeric;

  /// No description provided for @about_title.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about_title;

  /// No description provided for @about_connect_with_us.
  ///
  /// In en, this message translates to:
  /// **'Connect with us'**
  String get about_connect_with_us;

  /// No description provided for @about_description.
  ///
  /// In en, this message translates to:
  /// **'We help Buddhists do less harm, more good, and know their own mind better by learning, practicing and connecting daily so that all beings become free from suffering and find lasting happiness.'**
  String get about_description;

  /// No description provided for @about_social_website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get about_social_website;

  /// No description provided for @about_social_instagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get about_social_instagram;

  /// No description provided for @about_social_facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get about_social_facebook;

  /// No description provided for @about_social_x_twitter.
  ///
  /// In en, this message translates to:
  /// **'X (Twitter)'**
  String get about_social_x_twitter;

  /// No description provided for @about_social_youtube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get about_social_youtube;

  /// No description provided for @me_guest_headline.
  ///
  /// In en, this message translates to:
  /// **'Access the full experience'**
  String get me_guest_headline;

  /// No description provided for @me_guest_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a free account to save your progress'**
  String get me_guest_subtitle;

  /// No description provided for @delete_account_title.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get delete_account_title;

  /// No description provided for @delete_account_description.
  ///
  /// In en, this message translates to:
  /// **'If you delete your account, all your information, history, and personalized settings within WeBuddhist will be permanently eliminated. Please note that this action is irreversible. To proceed, tap the button below.'**
  String get delete_account_description;

  /// No description provided for @delete_account_button.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get delete_account_button;

  /// No description provided for @delete_account_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your WeBuddhist account?'**
  String get delete_account_confirm_message;

  /// No description provided for @legal_title.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal_title;

  /// No description provided for @legal_terms_of_service.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get legal_terms_of_service;

  /// No description provided for @legal_privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get legal_privacy_policy;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @share_this_quote.
  ///
  /// In en, this message translates to:
  /// **'Share this quote'**
  String get share_this_quote;

  /// No description provided for @shared_from.
  ///
  /// In en, this message translates to:
  /// **'Shared from'**
  String get shared_from;

  /// No description provided for @verse_share_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to share quote. Please try again'**
  String get verse_share_error;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bo', 'en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bo':
      return AppLocalizationsBo();
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

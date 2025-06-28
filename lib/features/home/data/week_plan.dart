import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import localized week plans
import 'week_plan_en.dart';
import 'week_plan_bo.dart';
import 'week_plan_zh.dart';

// Default English week plan (fallback)
const Map<String, dynamic> weekPlan = weekPlanEn;

// Provider to get the appropriate week plan based on locale
final weekPlanProvider = Provider<Map<String, dynamic>>((ref) {
  final locale = ref.watch(localeProvider);
  return _getWeekPlanForLocale(locale);
});

// Function to get week plan based on locale
Map<String, dynamic> _getWeekPlanForLocale(Locale? locale) {
  if (locale == null) return weekPlanEn;

  switch (locale.languageCode) {
    case 'bo':
      return weekPlanBo;
    case 'zh':
      return weekPlanZh;
    case 'en':
    default:
      return weekPlanEn;
  }
}

// Helper function to get week plan for a specific locale
Map<String, dynamic> getWeekPlanForLocale(Locale? locale) {
  return _getWeekPlanForLocale(locale);
}

// detail format of the a day plan item
const oneDayPlan = {
  "verse": {
    "text": "this is the verse text",
    "imageUrl":
        "https://drive.google.com/uc?export=view&id=1M_IFmQGMrlBOHDWpSID_kesZiFUsV9zS",
  },
  "scripture": {
    "videoUrl":
        "https://drive.google.com/uc?export=view&id=1M_IFmQGMrlBOHDWpSID_kesZiFUsV9zS",
  },
  "meditation": {
    "audioUrl":
        "https://drive.google.com/uc?export=view&id=1M_IFmQGMrlBOHDWpSID_kesZiFUsV9zS",
    "imageUrl":
        "https://drive.google.com/uc?export=view&id=1M_IFmQGMrlBOHDWpSID_kesZiFUsV9zS",
  },
  "prayer": {
    "data": [
      {
        "text": "this is the prayer text",
        "startTime": "00:00:00",
        "endTime": "00:00:00",
      },
    ],
    "audioUrl":
        "https://drive.google.com/uc?export=view&id=1M_IFmQGMrlBOHDWpSID_kesZiFUsV9zS",
  },
  "mindTraining": {
    "imageUrl":
        "https://drive.google.com/uc?export=view&id=1M_IFmQGMrlBOHDWpSID_kesZiFUsV9zS",
  },
};

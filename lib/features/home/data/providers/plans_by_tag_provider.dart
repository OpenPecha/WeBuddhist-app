import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// /// Future provider for fetching plans filtered by tag
// /// TODO: Replace with actual API call when ready
// final plansByTagProvider =
//     FutureProvider.family<List<PlansModel>, String>((ref, tag) async {
//   // Simulate network delay
//   await Future.delayed(const Duration(milliseconds: 500));

//   // Return mock data for testing UI
//   return _getMockPlans(tag);
// });

// /// Mock data for testing UI/UX
// List<PlansModel> _getMockPlans(String tag) {
//   return [
//     PlansModel(
//       id: '1',
//       title: 'Daily Trivia',
//       description: 'Learn about the faith',
//       language: 'en',
//       tags: [tag],
//       totalDays: 7,
//       image: ImageModel(
//         thumbnail: null,
//         medium: null,
//         original: null,
//       ),
//     ),
//     PlansModel(
//       id: '2',
//       title: 'Morning Meditation',
//       description: 'Start your day with peace',
//       language: 'en',
//       tags: [tag],
//       totalDays: 14,
//       image: ImageModel(
//         thumbnail: null,
//         medium: null,
//         original: null,
//       ),
//     ),
//     PlansModel(
//       id: '3',
//       title: 'Evening Prayers',
//       description: 'Wind down with gratitude',
//       language: 'en',
//       tags: [tag],
//       totalDays: 21,
//       image: ImageModel(
//         thumbnail: null,
//         medium: null,
//         original: null,
//       ),
//     ),
//     PlansModel(
//       id: '4',
//       title: 'Weekly Reflection',
//       description: 'Reflect on your spiritual journey',
//       language: 'en',
//       tags: [tag],
//       totalDays: 4,
//       image: ImageModel(
//         thumbnail: null,
//         medium: null,
//         original: null,
//       ),
//     ),
//     PlansModel(
//       id: '5',
//       title: 'Mindfulness Practice',
//       description: 'Be present in the moment',
//       language: 'en',
//       tags: [tag],
//       totalDays: 30,
//       image: ImageModel(
//         thumbnail: null,
//         medium: null,
//         original: null,
//       ),
//     ),
//     PlansModel(
//       id: '6',
//       title: 'Gratitude Journal',
//       description: 'Count your blessings daily',
//       language: 'en',
//       tags: [tag],
//       totalDays: 10,
//       image: ImageModel(
//         thumbnail: null,
//         medium: null,
//         original: null,
//       ),
//     ),
//   ];
// }

// Uncomment below and remove mock when API is ready:
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/plans/data/providers/plans_providers.dart';

final plansByTagProvider =
    FutureProvider.family<List<PlansModel>, String>((ref, tag) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  return ref.watch(plansRepositoryProvider).getPlans(
        language: languageCode,
        tag: tag,
      );
});

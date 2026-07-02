/// Service to handle sharing plans with friends
library;

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class PlanShareService {
  final _logger = AppLogger('PlanShareService');

  /// Generate deep link URL for a plan invitation
  String generatePlanInviteLink(String planId) {
    // Using HTTPS URL for better compatibility
    // This will work as App Link on Android and Universal Link on iOS

    // return 'https://webuddhist.app/plans/invite?planId=$planId';
    
    // Using custom scheme for immediate testing
    return 'weBuddhist://plans/invite?planId=$planId';
  }

  /// Share a plan with friends
  /// Opens the native share sheet with the plan invitation.
  /// [localizedMessage] and [localizedSubject] should come from the caller's
  /// localization context (e.g. l10n.share_plan_message / l10n.share_plan_subject).
  Future<void> sharePlan(
    String planId,
    String planTitle, {
    required String localizedMessage,
    required String localizedSubject,
  }) async {
    try {
      _logger.info('Sharing plan: $planId - $planTitle');

      final deepLink = generatePlanInviteLink(planId);
      _logger.debug('Generated deep link: $deepLink');

      final message = '$localizedMessage\n\n$deepLink';

      // ignore: deprecated_member_use
      await Share.share(
        message,
        subject: localizedSubject,
      );

      _logger.info('Share completed successfully');
    } catch (e) {
      _logger.error('Error sharing plan', e);
      rethrow;
    }
  }
}

/// Riverpod provider for PlanShareService
final planShareServiceProvider = Provider<PlanShareService>((ref) {
  return PlanShareService();
});

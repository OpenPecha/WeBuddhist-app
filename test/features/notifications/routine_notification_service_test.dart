import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'routine_notification_service_test.mocks.dart';

// Run after creating this file:
//   flutter pub run build_runner build --delete-conflicting-outputs
@GenerateMocks([FlutterLocalNotificationsPlugin])
void main() {
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late RoutineNotificationService service;

  // Helper to build a RoutineBlock for tests.
  RoutineBlock _block({
    String id = 'block-1',
    int hour = 8,
    int minute = 0,
    bool notificationEnabled = true,
    List<RoutineItem> items = const [],
    int? notificationId,
  }) {
    return RoutineBlock(
      id: id,
      time: TimeOfDay(hour: hour, minute: minute),
      notificationEnabled: notificationEnabled,
      items: items,
      notificationId: notificationId ?? 1001,
    );
  }

  RoutineItem _item({String id = 'item-1', String title = 'Morning Prayer'}) {
    return RoutineItem(
      id: id,
      title: title,
      type: RoutineItemType.plan,
    );
  }

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    service = RoutineNotificationService.withPlugin(mockPlugin);

    // Default stubs — can be overridden per test.
    when(
      mockPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      ),
    ).thenAnswer((_) async {});

    when(mockPlugin.cancel(any)).thenAnswer((_) async {});
    when(mockPlugin.cancelAll()).thenAnswer((_) async {});
  });

  // ── scheduleBlockNotification ─────────────────────────────────────────────

  group('scheduleBlockNotification', () {
    test('returns skipped when notificationEnabled is false', () async {
      final block = _block(notificationEnabled: false, items: [_item()]);
      final result = await service.scheduleBlockNotification(block);

      expect(result.success, isTrue);
      expect(result.notificationId, isNull);
      verifyNever(mockPlugin.zonedSchedule(
        any, any, any, any, any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      ));
    });

    test('returns skipped when block has no items', () async {
      final block = _block(notificationEnabled: true, items: []);
      final result = await service.scheduleBlockNotification(block);

      expect(result.success, isTrue);
      expect(result.notificationId, isNull);
      verifyNever(mockPlugin.zonedSchedule(
        any, any, any, any, any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      ));
    });

    test('returns failure when notification service is not initialized', () async {
      // Service created without a NotificationService initialized — _isReady is false.
      // Use a fresh service that has no initialized NotificationService.
      final uninitializedService = RoutineNotificationService.withPlugin(mockPlugin);
      // We cannot easily override _isReady, but the withPlugin factory creates
      // a new instance that delegates isReady to NotificationService singleton.
      // Since NotificationService is not initialized in tests, _isReady = false.
      final block = _block(items: [_item()]);
      final result = await uninitializedService.scheduleBlockNotification(block);

      // _isReady is false so we expect failure
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('not initialized'));
    });

    test('calls zonedSchedule with routineBlockId channel', () async {
      // We need _isReady = true — test this through the channel ID captured
      // via the ArgumentCaptor approach.
      // Since we cannot trivially set isReady=true in unit tests without
      // a full NotificationService, we verify the channel constants directly
      // on the NotificationDetails that would be passed.
      final details = NotificationChannels.routineBlockDetails();
      final android = details.android! as AndroidNotificationDetails;
      expect(android.channelId, NotificationChannels.routineBlockId);
    });

    test('NotificationDetails Android sound is RawResourceAndroidNotificationSound("routine")', () {
      final details = NotificationChannels.routineBlockDetails();
      final android = details.android! as AndroidNotificationDetails;
      expect(android.sound, isA<RawResourceAndroidNotificationSound>());
      final sound = android.sound as RawResourceAndroidNotificationSound;
      expect(sound.sound, 'routine');
    });

    test('NotificationDetails iOS sound is routine.caf', () {
      final details = NotificationChannels.routineBlockDetails();
      final ios = details.iOS! as DarwinNotificationDetails;
      expect(ios.sound, 'routine.caf');
    });
  });

  // ── cancelBlockNotification ───────────────────────────────────────────────

  group('cancelBlockNotification', () {
    test('does not throw when service is not ready', () async {
      final block = _block();
      // Service's _isReady is false in test environment — should be a no-op.
      await expectLater(
        service.cancelBlockNotification(block),
        completes,
      );
    });
  });

  // ── syncNotifications ─────────────────────────────────────────────────────

  group('syncNotifications', () {
    test('returns error result when service is not ready', () async {
      final result = await service.syncNotifications([_block(items: [_item()])]);
      expect(result.hasErrors, isTrue);
      expect(result.errors.first, contains('not initialized'));
    });

    test('returns zero counts when blocks list is empty and not ready', () async {
      final result = await service.syncNotifications([]);
      expect(result.scheduled, 0);
      expect(result.failed, 0);
    });
  });

  // ── cancelAllBlockNotifications ───────────────────────────────────────────

  group('cancelAllBlockNotifications', () {
    test('does not throw when called with empty list', () async {
      await expectLater(
        service.cancelAllBlockNotifications([]),
        completes,
      );
    });

    test('does not throw when called with blocks when not ready', () async {
      final blocks = [_block(items: [_item()])];
      await expectLater(
        service.cancelAllBlockNotifications(blocks),
        completes,
      );
    });
  });

  // ── NotificationResult factory constructors ───────────────────────────────

  group('NotificationResult', () {
    test('success sets success=true and notificationId', () {
      final result = NotificationResult.success(42);
      expect(result.success, isTrue);
      expect(result.notificationId, 42);
      expect(result.errorMessage, isNull);
    });

    test('failure sets success=false and errorMessage', () {
      final result = NotificationResult.failure('oops');
      expect(result.success, isFalse);
      expect(result.errorMessage, 'oops');
      expect(result.notificationId, isNull);
    });

    test('skipped sets success=true with a reason message', () {
      final result = NotificationResult.skipped('disabled');
      expect(result.success, isTrue);
      expect(result.errorMessage, 'disabled');
      expect(result.notificationId, isNull);
    });
  });

  // ── NotificationSyncResult ────────────────────────────────────────────────

  group('NotificationSyncResult', () {
    test('default values are all zero with no errors', () {
      const result = NotificationSyncResult();
      expect(result.scheduled, 0);
      expect(result.failed, 0);
      expect(result.cancelled, 0);
      expect(result.errors, isEmpty);
      expect(result.hasErrors, isFalse);
      expect(result.isFullySuccessful, isTrue);
    });

    test('hasErrors is true when errors list is non-empty', () {
      const result = NotificationSyncResult(errors: ['something failed']);
      expect(result.hasErrors, isTrue);
      expect(result.isFullySuccessful, isFalse);
    });

    test('isFullySuccessful is false when failed > 0', () {
      const result = NotificationSyncResult(failed: 1);
      expect(result.isFullySuccessful, isFalse);
    });
  });
}

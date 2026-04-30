import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationChannels', () {
    group('routineBlock constants', () {
      test('channel ID is stable — changing it silently breaks existing scheduled notifications on devices', () {
        expect(NotificationChannels.routineBlockId, 'routine_block_reminder');
      });

      test('channel name is correct', () {
        expect(NotificationChannels.routineBlockName, 'Routine Block Reminder');
      });

      test('iOS sound file is routine.caf', () {
        expect(NotificationChannels.routineIosSoundFile, 'routine.caf');
      });

      test('Android sound references res/raw/routine without extension', () {
        expect(
          NotificationChannels.routineAndroidSound,
          isA<RawResourceAndroidNotificationSound>(),
        );
        expect(NotificationChannels.routineAndroidSound.sound, 'routine');
      });
    });

    group('routineBlockChannel', () {
      test('importance is high', () {
        expect(
          NotificationChannels.routineBlockChannel.importance,
          Importance.high,
        );
      });

      test('playSound is true', () {
        expect(NotificationChannels.routineBlockChannel.playSound, isTrue);
      });

      test('vibration is enabled', () {
        expect(
          NotificationChannels.routineBlockChannel.enableVibration,
          isTrue,
        );
      });

      test('sound is set on channel (Android 8+ requires this for custom sound)', () {
        expect(
          NotificationChannels.routineBlockChannel.sound,
          isA<RawResourceAndroidNotificationSound>(),
        );
        final sound = NotificationChannels.routineBlockChannel.sound
            as RawResourceAndroidNotificationSound;
        expect(sound.sound, 'routine');
      });

      test('channel ID matches routineBlockId constant', () {
        expect(
          NotificationChannels.routineBlockChannel.id,
          NotificationChannels.routineBlockId,
        );
      });
    });

    group('routineBlockDetails', () {
      test('Android details use correct channel ID', () {
        final details = NotificationChannels.routineBlockDetails();
        final android = details.android! as AndroidNotificationDetails;
        expect(android.channelId, NotificationChannels.routineBlockId);
      });

      test('Android details have custom sound', () {
        final details = NotificationChannels.routineBlockDetails();
        final android = details.android! as AndroidNotificationDetails;
        expect(android.sound, isA<RawResourceAndroidNotificationSound>());
        final sound = android.sound as RawResourceAndroidNotificationSound;
        expect(sound.sound, 'routine');
      });

      test('Android details have playSound true', () {
        final details = NotificationChannels.routineBlockDetails();
        final android = details.android! as AndroidNotificationDetails;
        expect(android.playSound, isTrue);
      });

      test('Android details have importance high', () {
        final details = NotificationChannels.routineBlockDetails();
        final android = details.android! as AndroidNotificationDetails;
        expect(android.importance, Importance.high);
      });

      test('Android details have priority high', () {
        final details = NotificationChannels.routineBlockDetails();
        final android = details.android! as AndroidNotificationDetails;
        expect(android.priority, Priority.high);
      });

      test('iOS details have sound routine.caf', () {
        final details = NotificationChannels.routineBlockDetails();
        final ios = details.iOS! as DarwinNotificationDetails;
        expect(ios.sound, 'routine.caf');
      });

      test('iOS details have presentAlert true', () {
        final details = NotificationChannels.routineBlockDetails();
        final ios = details.iOS! as DarwinNotificationDetails;
        expect(ios.presentAlert, isTrue);
      });

      test('iOS details have presentSound true', () {
        final details = NotificationChannels.routineBlockDetails();
        final ios = details.iOS! as DarwinNotificationDetails;
        expect(ios.presentSound, isTrue);
      });

      test('custom icon is passed through to Android details', () {
        final details = NotificationChannels.routineBlockDetails(
          icon: 'custom_icon',
        );
        final android = details.android! as AndroidNotificationDetails;
        expect(android.icon, 'custom_icon');
      });
    });
  });
}

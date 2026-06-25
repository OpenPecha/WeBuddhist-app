import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/push_notifications/data/push_config.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_pecha/features/push_notifications/domain/repositories/push_messaging_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Talks to Firebase Cloud Messaging and the backend, mapping the SDK's
/// `RemoteMessage` into the domain [PushMessage]. This is the only file in the
/// feature that imports firebase_messaging.
class PushMessagingRepositoryImpl implements PushMessagingRepository {
  final FirebaseMessaging _messaging;
  final Dio _dio;
  final _logger = AppLogger('PushMessagingRepository');

  PushMessagingRepositoryImpl({required Dio dio, FirebaseMessaging? messaging})
      : _dio = dio,
        _messaging = messaging ?? FirebaseMessaging.instance;

  @override
  Future<bool> requestPermission() async {
    final status = (await _messaging.requestPermission()).authorizationStatus;
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(_toPushMessage);

  @override
  Stream<PushMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(_toPushMessage);

  @override
  Future<PushMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _toPushMessage(message);
  }

  @override
  Future<Either<Failure, Unit>> registerDeviceToken(
    String token, {
    String? email,
  }) async {
    // Backend endpoint isn't live yet — capture without hitting the network so
    // the wiring works the moment PushConfig.backendSyncEnabled flips to true.
    if (!PushConfig.backendSyncEnabled) {
      _logger.info('Device token captured (backend sync disabled)');
      return const Right(unit);
    }
    try {
      await _dio.post(
        PushConfig.deviceTokenPath,
        data: {
          'fcm_token': token,
          'platform': Platform.operatingSystem,
          // Placeholder: current backend keys on email.
          if (email != null) 'email': email,
        },
      );
      return const Right(unit);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'registerDeviceToken'));
    }
  }

  PushMessage _toPushMessage(RemoteMessage m) => PushMessage(
        title: m.notification?.title,
        body: m.notification?.body,
        data: m.data,
      );
}

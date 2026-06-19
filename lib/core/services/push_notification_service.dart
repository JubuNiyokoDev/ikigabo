import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/notification_service.dart';
import 'notification_navigation_service.dart';

// Handler background (doit être top-level)
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  await PushNotificationService._recordRemoteMessage(message);
}

class PushNotificationService {
  static const String _fcmTokenKey = 'push_fcm_token';
  static const String _deviceIdKey = 'push_device_id';

  static final _localNotif = FlutterLocalNotificationsPlugin();
  static const _channelId = 'ikigabo_notifications';
  static const _channelName = 'Ikigabo';

  static String? _cachedToken;
  static Future<void> Function(String token)? onTokenUpdated;
  static bool _isInitialized = false;
  static Future<void>? _initializationFuture;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    final pending = _initializationFuture;
    if (pending != null) return pending;

    final future = _initialize();
    _initializationFuture = future;
    try {
      await future;
    } finally {
      if (identical(_initializationFuture, future)) {
        _initializationFuture = null;
      }
    }
  }

  static Future<void> _initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Canal Android haute priorité
      await _localNotif
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              importance: Importance.max,
              enableVibration: true,
              playSound: true,
            ),
          );

      await _localNotif.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        ),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Handler background
      FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

      // Handler foreground
      FirebaseMessaging.onMessage.listen(_handleForeground);

      // Tap depuis notification (app en arrière-plan)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

      // Tap depuis notification (app terminée)
      final initial = await messaging.getInitialMessage();
      if (initial != null) _handleTap(initial);

      // Récupérer et sauvegarder le token FCM
      final token = await messaging.getToken();
      if (token != null) await _saveToken(token);

      // Rafraîchissement du token
      messaging.onTokenRefresh.listen((token) {
        unawaited(_saveToken(token));
      });
      _isInitialized = true;
    } catch (e, stackTrace) {
      debugPrint('⚠️ Push notification init failed: $e');
      debugPrint('$stackTrace');
    }
  }

  static Future<String?> getFcmToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceIdKey);
    if (id == null) {
      id = _generateDeviceId();
      await prefs.setString(_deviceIdKey, id);
    }
    return id;
  }

  static String _generateDeviceId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = now.hashCode ^ DateTime.now().microsecond;
    return 'ikigabo_${rand.abs().toRadixString(16).padLeft(12, '0')}';
  }

  static Future<void> _saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);

    try {
      await onTokenUpdated?.call(token);
    } catch (e) {
      debugPrint('⚠️ Token push sync failed: $e');
    }
  }

  static void _handleForeground(RemoteMessage message) {
    _showLocalFromRemote(message);
  }

  static void _handleTap(RemoteMessage message) {
    unawaited(_recordRemoteMessage(message));
    NotificationNavigationService.registerTap(message.data);
    debugPrint('🔔 Notification tappée: ${message.data}');
  }

  static void _onNotificationTap(NotificationResponse response) {
    final payload = _decodePayload(response.payload);
    if (payload != null) {
      unawaited(_recordPayloadNotification(payload));
      NotificationNavigationService.registerTap(payload);
    }
    debugPrint('🔔 Local notification tappée: ${response.payload}');
  }

  static Future<void> _showLocalFromRemote(RemoteMessage message) async {
    await _recordRemoteMessage(message);

    final payload = _payloadForMessage(message);
    final title = _stripVisibleEmoji(payload['title']?.toString() ?? '');
    final body = _stripVisibleEmoji(payload['body']?.toString() ?? '');
    if (title.isEmpty || body.isEmpty) return;

    await _localNotif.show(
      _numericNotificationId(
        payload['notificationId']?.toString() ?? _messageId(message),
      ),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      payload: jsonEncode(payload),
    );
  }

  static Future<void> _recordRemoteMessage(RemoteMessage message) async {
    final payload = _payloadForMessage(message);
    await _recordPayloadNotification(payload);
  }

  static Future<void> _recordPayloadNotification(
    Map<String, dynamic> payload,
  ) async {
    final title = payload['title']?.toString();
    final body = payload['body']?.toString();
    if (title == null || body == null) return;

    await NotificationService().recordPushNotification(
      id: payload['notificationId']?.toString() ?? _stablePushId(payload),
      title: title,
      body: body,
      receivedAt: _dateFromPayload(payload),
    );
  }

  static Map<String, dynamic> _payloadForMessage(RemoteMessage message) {
    final notification = message.notification;
    final payload = <String, dynamic>{
      ...message.data,
      'notificationId': message.data['notificationId'] ?? _messageId(message),
      'receivedAt': (message.sentTime ?? DateTime.now()).millisecondsSinceEpoch,
    };

    if (notification?.title != null) {
      payload['title'] = notification!.title;
    } else if (!payload.containsKey('title')) {
      payload['title'] = 'Ikigabo';
    }

    if (notification?.body != null) {
      payload['body'] = notification!.body;
    } else if (!payload.containsKey('body')) {
      payload['body'] = '';
    }

    return payload;
  }

  static Map<String, dynamic>? _decodePayload(String? rawPayload) {
    if (rawPayload == null || rawPayload.isEmpty) return null;
    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (e) {
      debugPrint('⚠️ Push payload decode failed: $e');
    }
    return null;
  }

  static String _messageId(RemoteMessage message) {
    final messageId = message.messageId;
    if (messageId != null && messageId.isNotEmpty) {
      return 'push_$messageId';
    }
    return _stablePushId({
      ...message.data,
      'title': message.notification?.title,
      'body': message.notification?.body,
      'receivedAt': message.sentTime?.millisecondsSinceEpoch,
    });
  }

  static String _stablePushId(Map<String, dynamic> payload) {
    final raw = jsonEncode(payload);
    var hash = 0;
    for (final codeUnit in raw.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return 'push_$hash';
  }

  static int _numericNotificationId(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }

  static DateTime? _dateFromPayload(Map<String, dynamic> payload) {
    final raw = payload['receivedAt'];
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) {
      final millis = int.tryParse(raw);
      if (millis != null) return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return null;
  }

  static String _stripVisibleEmoji(String value) {
    return value
        .replaceAll(
          RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true),
          '',
        )
        .replaceAll(RegExp(r'[\uFE0F\u200D]'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }
}

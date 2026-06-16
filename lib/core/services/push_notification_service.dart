import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Handler background (doit être top-level)
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await PushNotificationService._showLocalFromRemote(message);
}

class PushNotificationService {
  static const String _fcmTokenKey = 'push_fcm_token';
  static const String _deviceIdKey = 'push_device_id';

  static final _localNotif = FlutterLocalNotificationsPlugin();
  static const _channelId = 'ikigabo_push';
  static const _channelName = 'Ikigabo Notifications';

  static String? _cachedToken;

  static Future<void> initialize() async {
    await Firebase.initializeApp();

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Canal Android haute priorité
    await _localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
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
    messaging.onTokenRefresh.listen(_saveToken);
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
  }

  static void _handleForeground(RemoteMessage message) {
    _showLocalFromRemote(message);
  }

  static void _handleTap(RemoteMessage message) {
    // Deep link possible ici selon message.data['screen']
    print('🔔 Notification tappée: ${message.data}');
  }

  static void _onNotificationTap(NotificationResponse response) {
    print('🔔 Local notification tappée: ${response.payload}');
  }

  static Future<void> _showLocalFromRemote(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotif.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          styleInformation: BigTextStyleInformation(notification.body ?? ''),
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}

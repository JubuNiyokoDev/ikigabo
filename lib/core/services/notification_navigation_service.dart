import 'package:flutter/material.dart';

import '../../presentation/screens/notifications/notifications_screen.dart';

class NotificationNavigationService {
  NotificationNavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Map<String, dynamic>? _pendingPayload;
  static bool _isOpening = false;

  static void registerTap(Map<String, dynamic> payload, {bool openNow = true}) {
    _pendingPayload = payload;
    if (openNow) {
      openPendingIfPossible();
    }
  }

  static void openPendingIfPossible() {
    if (_pendingPayload == null || _isOpening) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    _isOpening = true;
    final payload = _pendingPayload;
    _pendingPayload = null;

    navigator
        .push(
          MaterialPageRoute(
            builder: (_) => const NotificationsScreen(),
            settings: RouteSettings(name: 'notifications', arguments: payload),
          ),
        )
        .whenComplete(() => _isOpening = false);
  }
}

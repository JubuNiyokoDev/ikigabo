import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class RealAlarmService {
  static const MethodChannel _channel = MethodChannel('real_alarm_channel');
  static bool _isInitialized = false;
  static bool _hasPermission = false;
  static String? _errorMessage;

  static bool get isAvailable => _isInitialized && _hasPermission;
  static String? get lastError => _errorMessage;

  static Future<AlarmStatus> initialize() async {
    try {
      _errorMessage = null;

      // Vérifier la version Android
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt < 23) {
        _errorMessage = 'Android 6.0+ requis pour les alarmes';
        return AlarmStatus.unsupported;
      }

      // La demande est centralisée dans NotificationService afin d'éviter
      // plusieurs dialogues système concurrents au lancement.
      final permissionStatus = await _checkPermissions();
      if (permissionStatus != AlarmStatus.ready) {
        return permissionStatus;
      }

      // Pas de test du service - considérer comme disponible si permissions OK
      _isInitialized = true;
      _hasPermission = true;
      return AlarmStatus.ready;
    } catch (e) {
      _errorMessage = 'Erreur initialisation: $e';
      return AlarmStatus.error;
    }
  }

  static Future<AlarmStatus> _checkPermissions() async {
    try {
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      if (!exactAlarmStatus.isGranted) {
        _errorMessage = 'Permission alarmes exactes refusée';
        return AlarmStatus.permissionDenied;
      }

      final notificationStatus = await Permission.notification.status;
      if (!notificationStatus.isGranted) {
        _errorMessage = 'Permission notifications refusée';
        return AlarmStatus.permissionDenied;
      }

      return AlarmStatus.ready;
    } catch (e) {
      _errorMessage = 'Erreur permissions: $e';
      return AlarmStatus.error;
    }
  }

  static Future<AlarmResult> scheduleRealAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    required String message,
  }) async {
    if (dateTime.isBefore(DateTime.now())) {
      return AlarmResult(
        success: false,
        error: 'Impossible de programmer une alarme dans le passé',
      );
    }

    try {
      print('🚨 Programmation alarme ID: $id pour: $dateTime');

      final result = await _channel.invokeMethod('setAlarm', {
        'id': id,
        'hour': dateTime.hour,
        'minute': dateTime.minute,
        'day': dateTime.day,
        'month': dateTime.month,
        'year': dateTime.year,
        'title': title,
        'message': message,
      });

      print('✅ Résultat alarme: $result');

      return AlarmResult(success: true);
    } catch (e) {
      print('❌ Erreur alarme: $e');
      return AlarmResult(success: false, error: 'Erreur: $e');
    }
  }

  static Future<bool> cancelAlarm(int id) async {
    if (!isAvailable) return false;

    try {
      final result = await _channel.invokeMethod('cancelAlarm', {'id': id});
      return result == true;
    } catch (e) {
      return false;
    }
  }

  static String getStatusMessage(AlarmStatus status) {
    switch (status) {
      case AlarmStatus.ready:
        return 'Alarmes disponibles';
      case AlarmStatus.unsupported:
        return 'Alarmes non supportées sur cet appareil';
      case AlarmStatus.permissionDenied:
        return 'Permissions requises pour les alarmes';
      case AlarmStatus.serviceUnavailable:
        return 'Service d\'alarme indisponible';
      case AlarmStatus.error:
        return _errorMessage ?? 'Erreur inconnue';
    }
  }
}

enum AlarmStatus {
  ready,
  unsupported,
  permissionDenied,
  serviceUnavailable,
  error,
}

class AlarmResult {
  final bool success;
  final String? error;

  AlarmResult({required this.success, this.error});
}

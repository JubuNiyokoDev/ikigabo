import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class RealAlarmService {
  static const MethodChannel _channel = MethodChannel('real_alarm_channel');

  static Future<void> initialize() async {
    // Demander la permission d'alarme au démarrage
    await _requestAlarmPermission();
  }

  static Future<bool> _requestAlarmPermission() async {
    try {
      final status = await Permission.scheduleExactAlarm.request();
      print('🔔 Permission alarme: $status');
      return status.isGranted;
    } catch (e) {
      print('❌ Erreur permission: $e');
      return false;
    }
  }

  static Future<void> scheduleRealAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    required String message,
  }) async {
    try {
      // Vérifier/demander la permission
      final hasPermission = await _requestAlarmPermission();
      if (!hasPermission) {
        print('❌ Permission alarme refusée');
        return;
      }
      
      print('🚨 Programmation VRAIE ALARME système Android ID: $id pour: $dateTime');
      
      // Utiliser l'app Alarme d'Android directement
      await _channel.invokeMethod('setAlarm', {
        'hour': dateTime.hour,
        'minute': dateTime.minute,
        'message': '$title - $message',
      });
      
      print('✅ Alarme système Android programmée!');
    } catch (e) {
      print('❌ Erreur alarme système: $e');
    }
  }

  static Future<void> cancelAlarm(int id) async {
    print('🚫 Tentative annulation alarme ID: $id');
    // Les alarmes système Android ne peuvent pas être annulées programmatiquement
  }
}
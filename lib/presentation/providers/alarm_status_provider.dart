import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/real_alarm_service.dart';

final alarmStatusProvider = StateNotifierProvider<AlarmStatusNotifier, AlarmStatusState>((ref) {
  return AlarmStatusNotifier();
});

class AlarmStatusState {
  final AlarmStatus status;
  final String message;
  final bool isChecking;

  const AlarmStatusState({
    required this.status,
    required this.message,
    this.isChecking = false,
  });

  AlarmStatusState copyWith({
    AlarmStatus? status,
    String? message,
    bool? isChecking,
  }) {
    return AlarmStatusState(
      status: status ?? this.status,
      message: message ?? this.message,
      isChecking: isChecking ?? this.isChecking,
    );
  }
}

class AlarmStatusNotifier extends StateNotifier<AlarmStatusState> {
  AlarmStatusNotifier() : super(const AlarmStatusState(
    status: AlarmStatus.error,
    message: 'Non initialisé',
    isChecking: true,
  )) {
    _checkAlarmStatus();
  }

  Future<void> _checkAlarmStatus() async {
    state = state.copyWith(isChecking: true);
    
    final status = await RealAlarmService.initialize();
    final message = RealAlarmService.getStatusMessage(status);
    
    state = AlarmStatusState(
      status: status,
      message: message,
      isChecking: false,
    );
  }

  Future<void> recheckStatus() async {
    await _checkAlarmStatus();
  }

  Future<AlarmResult> scheduleAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    required String message,
  }) async {
    if (state.status != AlarmStatus.ready) {
      return AlarmResult(
        success: false,
        error: 'Service d\'alarme non disponible: ${state.message}',
      );
    }

    return await RealAlarmService.scheduleRealAlarm(
      id: id,
      dateTime: dateTime,
      title: title,
      message: message,
    );
  }
}
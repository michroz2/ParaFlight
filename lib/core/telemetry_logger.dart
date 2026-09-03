// Версия: 0.1.0 | Цель: Хранилище телеметрии и логов для отладки

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class DebugEvent {
  final int id;
  final DateTime time;
  final LatLng location;
  final String reason;

  DebugEvent({
    required this.id,
    required this.time,
    required this.location,
    required this.reason,
  });
}

class TelemetryLogger extends Notifier<List<DebugEvent>> {
  static const int maxLogs = 50;
  int _currentId = 1;

  @override
  List<DebugEvent> build() {
    return [];
  }

  void logEvent(DateTime time, LatLng loc, String reason) {
    final event = DebugEvent(
      id: _currentId++,
      time: time,
      location: loc,
      reason: reason,
    );
    
    // Добавляем в начало списка
    state = [event, ...state];
    
    if (state.length > maxLogs) {
      state = state.sublist(0, maxLogs);
    }
  }

  void clear() {
    _currentId = 1;
    state = [];
  }
} // конец класса TelemetryLogger

final telemetryProvider = NotifierProvider<TelemetryLogger, List<DebugEvent>>(TelemetryLogger.new);

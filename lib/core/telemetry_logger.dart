// Версия: 0.1.0 | Цель: Хранилище телеметрии и логов для отладки

import 'package:flutter_riverpod/flutter_riverpod.dart';

class TelemetryLogger extends Notifier<List<String>> {
  static const int maxLogs = 50;

  @override
  List<String> build() {
    return [];
  }

  void log(String message) {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    final formattedMessage = "[$timeStr] $message";
    
    // Добавляем в начало списка
    state = [formattedMessage, ...state];
    
    if (state.length > maxLogs) {
      state = state.sublist(0, maxLogs);
    }
  }

  void clear() {
    state = [];
  }
} // конец класса TelemetryLogger

final telemetryProvider = NotifierProvider<TelemetryLogger, List<String>>(TelemetryLogger.new);

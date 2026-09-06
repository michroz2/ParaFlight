// Версия: 0.1.0 | Цель: Фоновая задача для получения координат
import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'dart:isolate';

/// Главная точка входа для фонового изолята.
/// Должна быть объявлена на верхнем уровне (top-level).
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionStream;
  DateTime? _lastSendTime;
  int _intervalMs = 1000;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    debugPrint('BackgroundLocationTask | onStart');
    
    // Пытаемся получить интервал из сохраненных данных
    final customData = await FlutterForegroundTask.getData<String>(key: 'intervalMs');
    if (customData != null) {
      _intervalMs = int.tryParse(customData) ?? 1000;
    }

    final locationSettings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
            forceLocationManager: false, // Используем FusedLocationProvider!
            intervalDuration: const Duration(seconds: 1),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final now = DateTime.now();
      
      // Защита очереди (Rate Limiter): фильтруем точки в фоне
      if (_lastSendTime == null || now.difference(_lastSendTime!).inMilliseconds >= _intervalMs) {
        _lastSendTime = now;
        
        final map = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'altitude': position.altitude,
          'speed': position.speed,
          'heading': position.heading,
          'timestamp': position.timestamp.millisecondsSinceEpoch,
        };
        
        // Отправляем сырые данные в главный изолят через ReceivePort
        sendPort?.send(jsonEncode(map));
      }
    }, onError: (error) {
      debugPrint('BackgroundLocationTask | error: $error');
    });
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // В данном случае периодические события таймера нам не нужны, 
    // вся логика реактивна (поток Geolocator).
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    debugPrint('BackgroundLocationTask | onDestroy');
    await _positionStream?.cancel();
  }
}

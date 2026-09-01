// Версия: 0.1.0 | Цель: Провайдеры настроек экрана (Ориентация, Wakelock)

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/preferences/preferences_provider.dart';

enum AppOrientation { system, portrait, landscape }

class WakelockNotifier extends StateNotifier<bool> {
  final Ref ref;
  
  WakelockNotifier(this.ref) : super(ref.read(sharedPreferencesProvider).getBool('wakelock_enabled') ?? true) {
    _applyState();
  } // конец конструктора

  void toggle(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('wakelock_enabled', value);
    _applyState();
  } // конец метода toggle

  void _applyState() {
    if (state) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    } // конец if
  } // конец метода _applyState
} // конец класса WakelockNotifier

final wakelockProvider = StateNotifierProvider<WakelockNotifier, bool>((ref) {
  return WakelockNotifier(ref);
}); // конец wakelockProvider

class OrientationNotifier extends StateNotifier<AppOrientation> {
  final Ref ref;

  OrientationNotifier(this.ref) : super(_parse(ref.read(sharedPreferencesProvider).getString('app_orientation'))) {
    _applyState();
  } // конец конструктора

  static AppOrientation _parse(String? value) {
    if (value == AppOrientation.portrait.name) return AppOrientation.portrait;
    if (value == AppOrientation.landscape.name) return AppOrientation.landscape;
    return AppOrientation.system;
  } // конец метода _parse

  void setOrientation(AppOrientation orientation) {
    state = orientation;
    ref.read(sharedPreferencesProvider).setString('app_orientation', orientation.name);
    _applyState();
  } // конец метода setOrientation

  void _applyState() {
    switch (state) {
      case AppOrientation.portrait:
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
        break;
      case AppOrientation.landscape:
        SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
        break;
      case AppOrientation.system:
        SystemChrome.setPreferredOrientations([]);
        break;
    } // конец switch
  } // конец метода _applyState
} // конец класса OrientationNotifier

final orientationProvider = StateNotifierProvider<OrientationNotifier, AppOrientation>((ref) {
  return OrientationNotifier(ref);
}); // конец orientationProvider

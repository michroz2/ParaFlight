// Версия: 0.2.0 | Цель: Контроллер Режима Кокпита (Kiosk Mode)

import 'package:flutter/services.dart'; // Новое: для управления системным UI
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'screen_settings_provider.dart';
import '../../../core/location/location_state.dart'; // для dataSourceProvider

// Новое: Глобальный контроллер, который слушает состояние и управляет kiosk_mode
final cockpitModeControllerProvider = Provider<void>((ref) {
  // Функция проверки и применения режима
  void checkKioskMode() {
    final isInternalGps = ref.read(dataSourceProvider) == DataSource.internalGps;
    final isCockpitEnabled = ref.read(cockpitModeProvider);

    if (isInternalGps && isCockpitEnabled) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); // Изменение: скрываем статус-бар
      startKioskMode();
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); // Изменение: возвращаем стандартный вид
      stopKioskMode();
    }
  } // конец функции checkKioskMode

  // Слушаем изменения источника данных
  ref.listen(dataSourceProvider, (prev, next) {
    checkKioskMode();
  }); // конец слушателя dataSourceProvider

  // Слушаем изменения тумблера
  ref.listen(cockpitModeProvider, (prev, next) {
    checkKioskMode();
  }); // конец слушателя cockpitModeProvider

  // Применяем при первой инициализации
  checkKioskMode();
}); // конец cockpitModeControllerProvider

// =============================================================================
// Файл:    track_settings_screen.dart
// Проект:  ParaFlight
// Версия:  0.1.0
// Цель:    Экран настроек параметров трека и детектора полета
// Изменения:
//   0.1.0 - Первичная реализация
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../flight_detector/presentation/track_config_provider.dart';
import '../application/advanced_mode_provider.dart';

class TrackSettingsScreen extends ConsumerWidget {
  const TrackSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(trackConfigProvider);
    final notifier = ref.read(trackConfigProvider.notifier);
    final isAdvanced = ref.watch(advancedModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Управление треком')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Автоматика', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Авто-старт с земли'),
            value: config.enableAutoTakeoff,
            onChanged: (val) => notifier.updateConfig(enableAutoTakeoff: val),
          ),
          SwitchListTile(
            title: const Text('Авто-старт в воздухе (Mid-Air)'),
            value: config.enableMidAirStart,
            onChanged: (val) => notifier.updateConfig(enableMidAirStart: val),
          ),
          SwitchListTile(
            title: const Text('Авто-посадка'),
            value: config.enableAutoLanding,
            onChanged: (val) => notifier.updateConfig(enableAutoLanding: val),
          ),
          if (isAdvanced) ...[
            SwitchListTile(
              title: const Text('Авто-стоп по ветру (CFV)'),
              value: config.enableCfvWindFail,
              onChanged: (val) => notifier.updateConfig(enableCfvWindFail: val),
            ),
            SwitchListTile(
              title: const Text('Авто-стоп по маневрам (CFV)'),
              value: config.enableCfvIntersection,
              onChanged: (val) => notifier.updateConfig(enableCfvIntersection: val),
            ),
            SwitchListTile(
              title: const Text('Авто-стоп по трассе (CFV)'),
              value: config.enableCfvHighway,
              onChanged: (val) => notifier.updateConfig(enableCfvHighway: val),
            ),
            SwitchListTile(
              title: const Text('Debug markers'),
              value: config.enableDebugMarkers,
              onChanged: (val) => notifier.updateConfig(enableDebugMarkers: val),
            ),
          ],
          
          if (isAdvanced) ...[
            const Divider(height: 32),
            const Text(
              'Задержки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 8),

            ListTile(
              title: const Text('Ожидание перед стартом (сек)'),
              subtitle: Text(config.takeoffWaitTimeSec.toString()),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: config.takeoffWaitTimeSec.toDouble(),
                  min: 1,
                  max: 15,
                  divisions: 14,
                  label: config.takeoffWaitTimeSec.toString(),
                  onChanged: (value) =>
                      notifier.updateConfig(takeoffWaitTimeSec: value.toInt()),
                ),
              ),
            ),
            ListTile(
              title: const Text('Время разбега/отрыва (сек)'),
              subtitle: Text(config.takeoffFlightTimeSec.toString()),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: config.takeoffFlightTimeSec.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 25,
                  label: config.takeoffFlightTimeSec.toString(),
                  onChanged: (value) =>
                      notifier.updateConfig(takeoffFlightTimeSec: value.toInt()),
                ),
              ),
            ),
            ListTile(
              title: const Text('Время подтверждения посадки (сек)'),
              subtitle: Text(config.landingConfirmTimeSec.toString()),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: config.landingConfirmTimeSec.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 25,
                  label: config.landingConfirmTimeSec.toString(),
                  onChanged: (value) =>
                      notifier.updateConfig(landingConfirmTimeSec: value.toInt()),
                ),
              ),
            ),

            const Divider(height: 32),
            const Text(
              'Пороги скоростей (м/с)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 8),

            ListTile(
              title: const Text('Мин. взлетная скорость'),
              subtitle: Text(
                '${config.minFlightSpeedMs.toStringAsFixed(1)} м/с (~${(config.minFlightSpeedMs * 3.6).toStringAsFixed(0)} км/ч)',
              ),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: config.minFlightSpeedMs,
                  min: 2.0,
                  max: 10.0,
                  divisions: 80,
                  label: config.minFlightSpeedMs.toStringAsFixed(1),
                  onChanged: (value) =>
                      notifier.updateConfig(minFlightSpeedMs: value),
                ),
              ),
            ),
            ListTile(
              title: const Text('Мин. скорость пешехода'),
              subtitle: Text(
                '${config.maxWalkSpeedMs.toStringAsFixed(1)} м/с (~${(config.maxWalkSpeedMs * 3.6).toStringAsFixed(0)} км/ч)',
              ),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: config.maxWalkSpeedMs,
                  min: 0.2,
                  max: 5.0,
                  divisions: 48,
                  label: config.maxWalkSpeedMs.toStringAsFixed(1),
                  onChanged: (value) =>
                      notifier.updateConfig(maxWalkSpeedMs: value),
                ),
              ),
            ),

            const Divider(height: 32),
            const Text(
              'Валидация состояния «в полёте»',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 8),

            ListTile(
              title: const Text('Таймаут провала ветра (сек)'),
              subtitle: Text(config.cfvWindFailTimeoutSec.toString()),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: config.cfvWindFailTimeoutSec.toDouble(),
                  min: 30,
                  max: 300,
                  divisions: 27,
                  label: config.cfvWindFailTimeoutSec.toString(),
                  onChanged: (value) =>
                      notifier.updateConfig(cfvWindFailTimeoutSec: value.toInt()),
                ),
              ),
            ),
            ListTile(
              title: const Text('Окно поворота (сек)'),
              subtitle: Text(config.cfvTurnWindowSec.toString()),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: config.cfvTurnWindowSec.toDouble(),
                  min: 2,
                  max: 15,
                  divisions: 13,
                  label: config.cfvTurnWindowSec.toString(),
                  onChanged: (value) =>
                      notifier.updateConfig(cfvTurnWindowSec: value.toInt()),
                ),
              ),
            ),
          ],

          const Divider(height: 32),
          const Text(
            'Запись трека',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 8),

          ListTile(
            title: const Text('Интервал записи GPX (сек)'),
            subtitle: Text(config.gpsRecordIntervalSec.toStringAsFixed(1)),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: config.gpsRecordIntervalSec,
                min: 0.3,
                max: 3.0,
                divisions: 27, // (3.0 - 0.3) / 0.1 = 27
                label: config.gpsRecordIntervalSec.toStringAsFixed(1),
                onChanged: (value) =>
                    notifier.updateConfig(gpsRecordIntervalSec: value),
              ),
            ),
          ),
          ListTile(
            title: const Text('Оставить секунд до/после полета (сек)'),
            subtitle: Text(config.gpsCleanupExtraSec.toString()),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: config.gpsCleanupExtraSec.toDouble(),
                min: 0,
                max: 60,
                divisions: 60,
                label: config.gpsCleanupExtraSec.toString(),
                onChanged: (value) =>
                    notifier.updateConfig(gpsCleanupExtraSec: value.toInt()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

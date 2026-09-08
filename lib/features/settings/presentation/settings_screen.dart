// Версия: 0.5.1 | Цель: Главный экран настроек (Иерархия категорий)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Импорт будущих экранов категорий
import 'data_source_settings_screen.dart';
import 'screen_settings_screen.dart';
import 'map_settings_screen.dart';

import 'track_settings_screen.dart'; // Новое: импорт экрана трека
import 'wind_settings_screen.dart'; // Новое: импорт экрана ветра
import 'dashboard_settings_screen.dart'; // Новое: импорт экрана дашборда
import '../../fuel/presentation/fuel_settings_screen.dart';

// Новое: импорты для проверки сохранения трека при выходе
import '../../../core/location/location_state.dart';
import '../../../core/location/flight_path_state.dart'; // Новое: импорт для realGpsTrackProvider
import '../../flight_detector/presentation/flight_detector_provider.dart';
import '../../flight_detector/presentation/track_config_provider.dart';
import '../../../core/location/gpx_writer.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../dashboard/presentation/widgets/save_track_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        children: [
          // Новое: Элемент перехода к источнику данных
          ListTile(
            leading: const Icon(Icons.satellite_alt),
            title: const Text('Источник данных'),
            subtitle: const Text('GPS, Внешние датчики, Симулятор'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DataSourceSettingsScreen()),
              );
            }, // конец onTap
          ), // конец ListTile
          const Divider(),
          // Новое: Элемент перехода к настройкам трека
          ListTile(
            leading: const Icon(Icons.timeline),
            title: const Text('Управление треком'),
            subtitle: const Text('Детектор полета, тайминги, пороги'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TrackSettingsScreen()),
              );
            }, // конец onTap
          ), // конец ListTile
          const Divider(),
          // Новое: Элемент перехода к ветру
          ListTile(
            leading: const Icon(Icons.air),
            title: const Text('Параметры ветра'),
            subtitle: const Text('Чувствительность, размеры буфера'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WindSettingsScreen()),
              );
            }, // конец onTap
          ), // конец ListTile
          const Divider(),
          // Новое: Элемент перехода к настройкам экрана
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Управление картой'),
            subtitle: const Text('Панель управления и масштаб'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MapSettingsScreen()),
              );
            }, // конец onTap
          ), // конец ListTile
          const Divider(),
          // Новое: Элемент перехода к настройкам панели инструментов
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Панель инструментов'),
            subtitle: const Text('Настройка вариометра (Vz) и приборов'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DashboardSettingsScreen()),
              );
            }, // конец onTap
          ), // конец ListTile
          const Divider(),
          // Расчет топлива
          ListTile(
            leading: const Icon(Icons.local_gas_station),
            title: const Text('Расчёт топлива'),
            subtitle: const Text('Вкл/выкл, расход, емкость'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const FuelSettingsScreen()),
              );
            },
          ),
          const Divider(),
          // Элемент перехода к настройкам экрана
          ListTile(
            leading: const Icon(Icons.display_settings),
            title: const Text('Экран'),
            subtitle: const Text('Ориентация, Wakelock'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ScreenSettingsScreen()),
              );
            }, // конец onTap
          ), // конец ListTile
          const Divider(),
          // Новое: Элемент Выхода из приложения
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Выход', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: const Text('Закрыть приложение'),
            onTap: () async {
              // Изменение: добавляем проверку сохранения трека перед выходом
              final currentSource = ref.read(dataSourceProvider);
              if (currentSource == DataSource.internalGps) {
                final rawPoints = ref.read(realGpsTrackProvider);
                if (rawPoints.isNotEmpty) {
                  final flightDetectorState = ref.read(flightDetectorProvider);
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => SaveTrackDialog(
                      flightCount: flightDetectorState.flights.length,
                      totalPoints: rawPoints.length,
                    ),
                  );

                  if (result == null || result['action'] == 'abort') {
                    return; // Отменяем выход
                  }

                  if (result['action'] == 'save') {
                    final config = ref.read(trackConfigProvider);
                    await GpxWriter.saveTrack(
                      rawPoints: rawPoints,
                      flights: flightDetectorState.flights,
                      cleanUpExtra: result['cleanUpExtra'],
                      splitFlights: result['splitFlights'],
                      cleanupExtraSec: config.gpsCleanupExtraSec,
                      storageService: ref.read(localStorageProvider),
                    );
                  }
                  // Если action == 'erase', просто продолжаем без сохранения
                }
              }

              SystemNavigator.pop();
            }, // конец onTap
          ), // конец ListTile
        ],
      ), // конец ListView
    ); // конец Scaffold
  } // конец метода build
} // конец класса SettingsScreen

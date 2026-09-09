// =============================================================================
// Файл:    data_source_settings_screen.dart
// Проект:  ParaFlight
// Версия:  0.6.2
// Цель:    Экран выбора источника данных (GPS/Симулятор)
// Изменения:
//   0.6.2 - В диалоге выбора трека добавлено отображение размера файла (Б/КБ/МБ)
// =============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../../core/location/location_state.dart';
import '../../../core/storage/local_storage_service.dart'; // Новое: импорт сервиса хранилища
import '../../../core/location/flight_path_state.dart';
import '../../../core/location/gpx_writer.dart';
import '../../flight_detector/presentation/flight_detector_provider.dart';
import '../../flight_detector/presentation/track_config_provider.dart';
import '../../dashboard/presentation/widgets/save_track_dialog.dart';

class DataSourceSettingsScreen extends ConsumerWidget {
  const DataSourceSettingsScreen({super.key});

  // Изменение: Переход на LocalStorageService и отказ от импорта
  void _showTrackPicker(BuildContext context, WidgetRef ref) async {
    final storageService = ref.read(localStorageProvider);
    
    // Инициализация (запрос прав и создание папки)
    await storageService.init();
    
    final tracks = await storageService.getGpxFiles();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Выберите трек для симуляции',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                // Убрана логика импорта файла через системный пикер
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final file = tracks[index];
                      final name = path.basename(file.path);
                      // Форматирование размера файла: Б / КБ / МБ
                      final sizeBytes = file.lengthSync();
                      final String sizeLabel;
                      if (sizeBytes < 1024) {
                        sizeLabel = '$sizeBytes Б';
                      } else if (sizeBytes < 1024 * 1024) {
                        final kb = (sizeBytes / 1024).toStringAsFixed(1);
                        sizeLabel = '$kb КБ';
                      } else {
                        final mb = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);
                        sizeLabel = '$mb МБ';
                      }
                      return ListTile(
                        leading: const Icon(Icons.map),
                        title: Text(name),
                        subtitle: Text(
                          sizeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        onTap: () {
                          ref
                              .read(selectedGpxFileProvider.notifier)
                              .setFile(file.path);
                          if (context.mounted) Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSource = ref.watch(dataSourceProvider);
    final selectedFile = ref.watch(selectedGpxFileProvider);

    final fileName = selectedFile != null
        ? path.basename(selectedFile)
        : 'Файл не выбран';

    return Scaffold(
      appBar: AppBar(title: const Text('Источник данных')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          RadioListTile<DataSource>(
            title: const Text('Симулятор GPX'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Воспроизведение записанного трека с симуляцией времени',
                ),
                if (currentSource == DataSource.simulator) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Текущий трек: $fileName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => _showTrackPicker(context, ref),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Выбрать другой трек'),
                  ),
                ],
              ],
            ),
            value: DataSource.simulator,
            groupValue: currentSource,
            onChanged: (DataSource? value) async {
              if (value != null) {
                if (currentSource == DataSource.internalGps &&
                    value == DataSource.simulator) {
                  final rawPoints = ref.read(realGpsTrackProvider);
                  if (rawPoints.isNotEmpty) {
                    final flightDetectorState = ref.read(
                      flightDetectorProvider,
                    );
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => SaveTrackDialog(
                        flightCount: flightDetectorState.flights.length,
                        totalPoints: rawPoints.length,
                      ),
                    );

                    // Изменение: обработка различных действий
                    if (result == null || result['action'] == 'abort') {
                      return; // Отменяем смену источника
                    }

                    if (result['action'] == 'save') {
                      final config = ref.read(trackConfigProvider);
                      final savedPaths = await GpxWriter.saveTrack( // Изменение: сохраняем результат
                        rawPoints: rawPoints,
                        flights: flightDetectorState.flights,
                        cleanUpExtra: result['cleanUpExtra'],
                        splitFlights: result['splitFlights'],
                        cleanupExtraSec: config.gpsCleanupExtraSec,
                        storageService: ref.read(localStorageProvider), // Новое: пробрасываем сервис
                      );
                      
                      // Новое: показываем диалог после сохранения
                      if (context.mounted && savedPaths.isNotEmpty) {
                        final fileNames = savedPaths.map((p) => p.split(RegExp(r'[\\/]')).last).join(', ');
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Успешно'),
                            content: Text('Трек $fileNames записан'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                    // Если action == 'erase', просто продолжаем без сохранения
                  }
                }

                ref.read(dataSourceProvider.notifier).setSource(value);
                if (value == DataSource.simulator &&
                    (selectedFile == null || selectedFile.isEmpty)) {
                  _showTrackPicker(context, ref);
                }
              }
            },
          ),

          RadioListTile<DataSource>(
            title: const Text('Встроенный GPS смартфона'),
            subtitle: const Text(
              'Использование аппаратного датчика геолокации устройства',
            ),
            value: DataSource.internalGps,
            groupValue: currentSource,
            onChanged: (DataSource? value) {
              if (value != null) {
                ref.read(dataSourceProvider.notifier).setSource(value);
              }
            },
          ),
          if (currentSource == DataSource.internalGps)
            SwitchListTile(
              title: const Text('Данные эмулятора (Математические)'),
              subtitle: const Text(
                'Игнорировать нулевую скорость эмулятора и вычислять её по координатам (сглаженно). Включите при отладке в Android эмуляторе.',
              ),
              value: ref.watch(emulatorDataEnabledProvider),
              onChanged: (value) {
                ref.read(emulatorDataEnabledProvider.notifier).toggle(value);
              },
            ),
        ],
      ),
    );
  }
}

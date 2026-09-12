// =============================================================================
// Файл:    dashboard_screen.dart
// Проект:  ParaFlight
// Версия:  1.18.11
// Цель:    Главный экран с линейными контролами и умным компасом ветра
// Изменения:
//   0.7.0 - Добавлены линейные контролы и умный компас ветра
//   1.18.10 - Вывод параметров буфера ветра (bufferSize и bufferAngle)
//   1.18.11 - Цветовая индикация параметров валидации ветра в телеметрии
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'dart:async';

import '../../../core/location/location_state.dart';
import '../../../core/storage/local_storage_service.dart'; // Новое: Импорт сервиса локального хранилища
import '../../../core/location/flight_path_state.dart';
import '../../../core/location/gpx_writer.dart';
import '../../../core/version_provider.dart';
import '../../flight_detector/presentation/flight_detector_provider.dart'; // Новое: импорт провайдера
import '../../flight_detector/presentation/track_config_provider.dart';
import '../../flight_detector/domain/flight_state.dart';
import '../../../core/telemetry_logger.dart';
import '../../wind/presentation/wind_provider.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/application/map_settings_provider.dart';
import '../../settings/application/wind_config_provider.dart';
import '../../settings/application/screen_settings_provider.dart'; // Новое: Импорт настроек экрана для режима Кокпита
import '../../fuel/application/fuel_provider.dart';
import '../../fuel/domain/fuel_state.dart';
import '../../fuel/presentation/fuel_dialog.dart';
import 'widgets/save_track_dialog.dart';
import 'widgets/wind_compass_overlay.dart';
import 'widgets/top_telemetry_bar.dart';
import 'widgets/simulator_control_bar.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  bool _showOverlays = false;
  Timer? _hideTimer;

  bool _isFreePanMode = false;
  bool _isTrackingPilot = true;
  bool? _userPreviewToggle;
  Timer? _autoReturnTimer;

  // Переменная для настройки скорости возврата карты на маркер самолёта (в миллисекундах)
  final int _mapReturnAnimationMs = 1000;

  // --- ОГРАНИЧИТЕЛИ МАСШТАБА КАРТЫ ---
  // Зум 8.5: обзор около 100-120 км (соответствует нашему максимальному радиусу 50 000 м)
  static const double _kMapMinZoom = 8.5; 
  // Зум 18.5: обзор около 100-150 м (близко к радиусу 10-25 м). 
  // Глубже опускаться нельзя, так как тайлы OSM обычно не рендерятся дальше 19-го зума.
  static const double _kMapMaxZoom = 18.5;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!context.mounted) return;
      final flightState = ref.read(flightDetectorProvider).state;
      final loc = ref.read(locationProvider).valueOrNull;
      final config = ref.read(trackConfigProvider);
      final fuelState = ref.read(fuelProvider);
      
     if (fuelState.enableFuelTracking && flightState == FlightState.groundMovement && (loc == null || loc.speed <= config.maxWalkSpeedMs)) {
        if (!context.mounted) return; // Повторная проверка непосредственно перед использованием context
        // ignore: use_build_context_synchronously
        _showFuelDialog(context);
      }
    });
  }

  void _showFuelDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const FuelDialog(),
    );
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: Duration(milliseconds: _mapReturnAnimationMs),
      vsync: this,
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _autoReturnTimer?.cancel();
    super.dispose();
  }

  void _resetUiTimer() {
    _hideTimer?.cancel();
    if (_showOverlays) {
      final uiHideSeconds = ref.read(mapSettingsProvider).uiAutoHideSeconds;
      _hideTimer = Timer(Duration(seconds: uiHideSeconds), () {
        if (mounted) setState(() => _showOverlays = false);
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _showOverlays = !_showOverlays);
    _resetUiTimer();
  }

  Widget _buildControlButton(
    IconData icon,
    VoidCallback onPressed, {
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xDD333333),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.white60,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.blue : Colors.white,
          size: 36,
        ),
      ),
    );
  }

  void _showTelemetrySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Telemetry Logs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(telemetryProvider.notifier).clear(),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final logs = ref.watch(telemetryProvider);
                    if (logs.isEmpty) {
                      return const Center(child: Text('No logs'));
                    }
                    return ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final event = logs[index];
                        final timeStr =
                            "${event.time.hour.toString().padLeft(2, '0')}:${event.time.minute.toString().padLeft(2, '0')}:${event.time.second.toString().padLeft(2, '0')}";
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            "#[${event.id}] [$timeStr] - ${event.reason}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FuelState>(fuelProvider, (prev, next) {
      if (next.enableFuelTracking && 
          next.remainder <= next.jokerRemainder && 
          !next.hasShownJokerWarning) {
        
        // Показываем предупреждение и помечаем
        Future.microtask(() {
          ref.read(fuelProvider.notifier).markJokerWarningShown();
          if (!context.mounted) return; // Проверка: контекст всё ещё валиден
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => Dialog(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ТОПЛИВО МИНИМУМ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('ОТМЕНИТЬ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      }
    });

    final mapSettings = ref.watch(mapSettingsProvider);

    final screenSize = MediaQuery.of(context).size;

    final dataSource = ref.watch(dataSourceProvider);
    final isSimulation = dataSource == DataSource.simulator;

    // Изменение: Динамический оффсет для смещения оптического центра карты вниз.
    // 0.0 для симулятора (по центру, освобождая низ), 0.2 для реального GPS (сдвиг вниз на 10%).
    final double mapCenterOffsetPercent = isSimulation ? 0.0 : 0.2;

    final track = ref.watch(flightPathProvider);
    final asyncLocation = ref.watch(locationProvider);
    final gpxStateAsync = ref.watch(gpxPointsProvider);
    final gpxState = gpxStateAsync.valueOrNull;
    final currentLocation = asyncLocation.valueOrNull;
    final isKioskActive = dataSource == DataSource.internalGps && ref.watch(cockpitModeProvider); // Новое: проверяем активен ли киоск

    final playbackState = ref.watch(playbackProvider);
    final isPreviewVisible = _userPreviewToggle ?? !playbackState.hasStarted;

    final windState = ref.watch(windProvider);
    final wind = windState.telemetryResult;
    final windConfig = ref.watch(windConfigProvider);

    ref.listen(playbackProvider, (previous, next) {
      if (previous?.hasStarted == true && next.hasStarted == false) {
        setState(() {
          _userPreviewToggle = null;
        });
      }
    });

    ref.listen(locationProvider, (previous, nextAsync) {
      final next = nextAsync.valueOrNull;
      debugPrint('DashboardScreen listen locationProvider | next loc: ${next?.latitude}, ${next?.longitude}');
      if (next != null) {
        try {
          if (_isTrackingPilot) {
            double z = 13.0;
            try {
              z = _mapController.camera.zoom;
            } catch (_) {}
            debugPrint('DashboardScreen moving map to ${next.latitude}, ${next.longitude}');
            _mapController.move(LatLng(next.latitude, next.longitude), z);
          }
          final currentRotationMode = ref.read(mapSettingsProvider).defaultRotationMode;
          if (currentRotationMode == MapRotationMode.heading) {
            _mapController.rotate(360.0 - next.heading);
          }
        } catch (e) {
          debugPrint('DashboardScreen map error: $e');
          // Игнорируем ошибку
        }
      }
    });

    // Изменение: WillPopScope заменён на PopScope (WillPopScope устарел с v3.12.0)
    return PopScope(
      canPop: false, // Всегда перехватываем — сами управляем выходом
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // Уже закрылось — ничего не делаем
        final currentSource = ref.read(dataSourceProvider);
        if (currentSource == DataSource.internalGps) {
          final rawPoints = ref.read(realGpsTrackProvider);
          if (rawPoints.isNotEmpty) {
            final flightDetectorState = ref.read(flightDetectorProvider);
            if (!context.mounted) return;
            final dialogResult = await showDialog<Map<String, dynamic>>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => SaveTrackDialog(
                flightCount: flightDetectorState.flights.length,
                totalPoints: rawPoints.length,
              ),
            );

            // Изменение: обработка различных действий
            if (dialogResult == null || dialogResult['action'] == 'abort') {
              return; // Отменяем выход — не вызываем pop
            }

            if (dialogResult['action'] == 'save') {
              final config = ref.read(trackConfigProvider);
              final savedPaths = await GpxWriter.saveTrack( // Изменение: сохраняем результат
                rawPoints: rawPoints,
                flights: flightDetectorState.flights,
                cleanUpExtra: dialogResult['cleanUpExtra'],
                splitFlights: dialogResult['splitFlights'],
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

        // Позволяем системе выйти (закрыть экран)
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Изменение: смещение центра карты вниз
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: -screenSize.height * mapCenterOffsetPercent,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: currentLocation != null
                      ? LatLng(
                          currentLocation.latitude,
                          currentLocation.longitude,
                        )
                      : const LatLng(0, 0),
                  initialZoom: 13.0,
                  minZoom: _kMapMinZoom, // Новое: Защита от отдаления в космос
                  maxZoom: _kMapMaxZoom, // Новое: Защита от провала в пустые пиксели
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onTap: _onMapTap,
                  onMapReady: () {
                    final loc = ref.read(locationProvider).valueOrNull;
                    if (loc != null && _isTrackingPilot) {
                      _mapController.move(
                        LatLng(loc.latitude, loc.longitude),
                        _mapController.camera.zoom,
                      );
                    }
                  },
                  onPositionChanged: (MapCamera camera, bool hasGesture) {
                    if (hasGesture) {
                      if (_isTrackingPilot) {
                        setState(() => _isTrackingPilot = false);
                      }
                      if (!_isFreePanMode) {
                        _autoReturnTimer?.cancel();
                        _autoReturnTimer = Timer(
                          Duration(seconds: mapSettings.mapAutoCenterSeconds),
                          () {
                            if (mounted && !_isTrackingPilot) {
                              setState(() => _isTrackingPilot = true);
                              final loc = ref.read(locationProvider).valueOrNull;
                              if (loc != null) {
                                _animatedMapMove(
                                  LatLng(loc.latitude, loc.longitude),
                                  _mapController.camera.zoom,
                                );
                              }
                            }
                          },
                        );
                      }
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.paraflight',
                  ),
                  if (isPreviewVisible && gpxState != null && gpxState.points != null && dataSource == DataSource.simulator)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: gpxState.points!.map((p) => LatLng(p.latitude, p.longitude)).toList(),
                          color: Colors.purple,
                          strokeWidth: 3.0,
                        )
                      ],
                    ),
                  if ((playbackState.hasStarted || dataSource == DataSource.internalGps) && track.isNotEmpty)
                    PolylineLayer(
                      polylines: track.map((segment) {
                        return Polyline(
                          points: segment.points,
                          color: segment.isFlight ? Colors.blue : Colors.grey,
                          strokeWidth: segment.isFlight ? 4.0 : 2.0,
                        );
                      }).toList(),
                    ),
                  // Новое: слой маркеров для старта и финиша
                  if (playbackState.hasStarted || dataSource == DataSource.internalGps)
                    Builder(
                      builder: (context) {
                        final detectorState = ref.watch(flightDetectorProvider);
                        final markers = <Marker>[];
                        final flights = detectorState.flights;
                        for (int i = 0; i < flights.length; i++) {
                          final flight = flights[i];
                          // Маркер старта: первый полет 'S', остальные 'R'. Забытый старт в воздухе - 'O'
                          final startChar = flight.isMidAirStart
                              ? 'O'
                              : (i == 0 ? 'S' : 'R');
                          markers.add(
                            Marker(
                              point: LatLng(
                                flight.start.latitude,
                                flight.start.longitude,
                              ),
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(200),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.blue, width: 2),
                                ),
                                child: Text(
                                  startChar,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          );

                          // Маркер финиша (если есть)
                          if (flight.finish != null) {
                            markers.add(
                              Marker(
                                point: LatLng(
                                  flight.finish!.latitude,
                                  flight.finish!.longitude,
                                ),
                                width: 20,
                                height: 20,
                                alignment: Alignment.center,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(200),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Text(
                                    'X',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        } // конец for
                        if (markers.isEmpty) return const SizedBox.shrink();
                        return MarkerLayer(markers: markers);
                      },
                    ),
                  if (playbackState.hasStarted || dataSource == DataSource.internalGps)
                    Builder(
                      builder: (context) {
                        final config = ref.watch(trackConfigProvider);
                        if (!config.enableDebugMarkers) return const SizedBox.shrink();
                        final logs = ref.watch(telemetryProvider);
                      if (logs.isEmpty) return const SizedBox.shrink();
                      final markers = logs.map((event) {
                        return Marker(
                          point: event.location,
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(200),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              event.id.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                height: 1.0,
                              ),
                            ),
                          ),
                        );
                      }).toList();
                      return MarkerLayer(markers: markers);
                    },
                  ),
                  if (currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            currentLocation.latitude,
                            currentLocation.longitude,
                          ),
                          child: Transform.rotate(
                            angle: currentLocation.heading * pi / 180.0,
                            child: const Icon(
                              Icons.flight,
                              color: Colors.red,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Изменение: Вынесенный виджет круга ветра
            WindCompassOverlay(
              mapController: _mapController,
              mapCenterOffsetPercent: mapCenterOffsetPercent,
            ),  

            SafeArea(
                top: !isKioskActive,
              child: TopTelemetryBar(
                onFuelTap: () => _showFuelDialog(context),
              ),
            ),
            
            // Изменение: Телеметрия теперь зависит только от тумблера
            if (windConfig.enableWindOverlay)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                bottom: _showOverlays
                    ? (dataSource == DataSource.simulator ? 230 : 100)
                    : (dataSource == DataSource.simulator ? 140 : 20),
                left: 16,
                child: SafeArea(
                  bottom: true, top: false, left: false, right: false,
                  child: Card(
                    color: Colors.white.withAlpha(220),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Builder( // Используем Builder, чтобы вычислять переменные перед отрисовкой Column
                      builder: (context) {
                        final bool isAirspeedBad = wind != null && (wind.airspeed < windConfig.minAirspeedMs || wind.airspeed > windConfig.maxAirspeedMs);
                        final bool isRmseBad = wind != null && wind.rmse > windConfig.maxRmseMs;
                        final bool isRoundnessBad = wind != null && wind.roundness < windConfig.minRoundness;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.air, size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'Ветер: ${wind?.windSpeed.toStringAsFixed(1) ?? '--.-'} м/с',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Transform.rotate(
                                  angle: ((wind?.windDirection ?? 0.0) + 180) * pi / 180.0,
                                  child: const Icon(
                                    Icons.arrow_upward,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Направление: ${wind?.windDirection.toStringAsFixed(0) ?? '---'}°',
                                ),
                              ],
                            ),
                            if (currentLocation != null)
                              Text(
                                'SOG: ${currentLocation.speed.toStringAsFixed(1)} м/с',
                              ),
                            Text(
                              'Airspeed: ${wind?.airspeed.toStringAsFixed(1) ?? '--.-'} м/с',
                              style: TextStyle(
                                color: isAirspeedBad ? Colors.red : null,
                              ),
                            ),
                            Text(
                              'RMSE: ${wind?.rmse.toStringAsFixed(2) ?? '--.--'} м/с',
                              style: TextStyle(
                                fontSize: 14,
                                color: isRmseBad ? Colors.red : null,
                              ),
                            ),
                            Text(
                              'Round: ${wind?.roundness.toStringAsFixed(2) ?? '--.--'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isRoundnessBad ? Colors.red : null,
                              ),
                            ),
                            // Новое: Живые данные буфера
                            Text(
                              'N=${windState.bufferSize}, ∟=${windState.bufferAngle.toStringAsFixed(0)}°',
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                ),
                ),
              ),
           if (dataSource == DataSource.simulator)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                // Изменение: Вынесенный виджет панели симулятора
                child: SimulatorControlBar(
                  isPreviewVisible: isPreviewVisible,
                  onTogglePreview: () {
                    setState(() {
                      _userPreviewToggle = !isPreviewVisible;
                    });
                  },
                ),
              ),
            // Панель: Линейная панель управления (Linear Control Bar)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showOverlays
                  ? (dataSource == DataSource.simulator ? 90 : 20)
                  : -100,
              left: 0,    // Изменение: убираем жёсткий отступ — SafeArea сам учтёт боковые nav-bar
              right: 0,   // Изменение: аналогично
              child: SafeArea(
                // Изменение: добавляем left/right для корректной работы в ландшафтном режиме
                bottom: true, top: false, left: true, right: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  _buildControlButton(Icons.remove, () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                    _resetUiTimer();
                  }),
                  _buildControlButton(
                    _isFreePanMode ? Icons.lock_open : Icons.my_location,
                    () {
                      setState(() {
                        _isFreePanMode = !_isFreePanMode;
                        if (!_isFreePanMode) {
                          _isTrackingPilot = true;
                          final loc = ref.read(locationProvider).valueOrNull;
                          if (loc != null) {
                            _animatedMapMove(
                              LatLng(loc.latitude, loc.longitude),
                              _mapController.camera.zoom,
                            );
                          }
                        }
                      });
                      _resetUiTimer();
                    },
                    isActive:
                        !_isFreePanMode, // Синяя, когда включено авто-слежение
                  ),
                  _buildControlButton(
                    mapSettings.defaultRotationMode == MapRotationMode.heading
                        ? Icons.navigation
                        : Icons.explore,
                    () {
                      final newMode = mapSettings.defaultRotationMode == MapRotationMode.north
                          ? MapRotationMode.heading
                          : MapRotationMode.north;
                      ref.read(mapSettingsProvider.notifier).setDefaultRotation(newMode);
                      if (newMode == MapRotationMode.north) {
                        _mapController.rotate(0);
                      }
                      _resetUiTimer();
                    },
                    isActive:
                        mapSettings.defaultRotationMode ==
                        MapRotationMode.heading, // Синяя, когда по курсу
                  ),
                  _buildControlButton(Icons.add, () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                    _resetUiTimer();
                  }),
                    ],
                  ),
                ),
              ),
            ),

            // Верхняя панель
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: _showOverlays ? 0 : -100,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.amber,
                elevation: 4,
                child: SafeArea(
                  top: !isKioskActive, // Изменение: скрываем SafeArea в Режиме Кокпита
                  bottom: false,
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Consumer(
                          builder: (context, ref, _) {
                            final versionAsync = ref.watch(packageInfoProvider);
                            final versionText = versionAsync.when(
                              data: (info) => ' v${info.version}',
                              loading: () => '',
                              error: (_, _) => '',
                            );
                            return Text(
                              'ParaFlight$versionText',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        Consumer(
                          builder: (context, ref, _) {
                            final config = ref.watch(trackConfigProvider);
                            if (!config.enableDebugMarkers) return const SizedBox.shrink();
                            return IconButton(
                              iconSize: 32,
                              icon: const Icon(
                                Icons.bug_report,
                                color: Colors.black87,
                              ),
                              onPressed: () => _showTelemetrySheet(context),
                            );
                          },
                        ),
                        IconButton(
                          iconSize: 32,
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.black87,
                          ),
                          onPressed: () {
                            _hideTimer?.cancel();
                            setState(() => _showOverlays = false);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

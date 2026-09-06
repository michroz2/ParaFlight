# Changelog

All notable changes to this project will be documented in this file.

## [1.16.0] - 2026-09-05
### Added
- Added Fuel Tracking system (Учёт топлива) with dynamic calculation in flight based on EMA.
- Added Fuel settings toggle and configuration in Settings.
- Added interactive Fuel dialog on the Dashboard to input remainder and added fuel.
- Added adjustable sliders for Tank Capacity (0-30L) and Average Consumption (0-15L/h).
- Added toggle for automatic EMA consumption correction.

## [1.16.10] - 2026-09-06
### Fixed
- Fixed internal GPS on Android emulators not receiving Mock Locations from Extended Controls by explicitly setting `forceLocationManager: true`.
- Added `debugPrint` for raw GPS position in `location_state.dart` to verify raw sensor input.

## [1.16.9] - 2026-09-06
### Fixed
- Added a hard limit of 15 L/h (and minimum of 1 L/h) for the dynamically calculated fuel consumption during manual remainder adjustments in the Fuel Dialog and Provider.

## [1.16.8] - 2026-09-06
### Fixed
- Fixed build error caused by missing `FuelState` import in `dashboard_screen.dart`.

## [1.16.7] - 2026-09-06
### Added
- Added "Joker Remainder" (Рубежный остаток) fuel tracking feature. When fuel drops below the configured amount (0-5L, adjustable in settings), the dashboard FUEL widget flashes orange and a warning dialog alerts the pilot.

## [1.16.6] - 2026-09-05
### Fixed
- Fixed Fuel Dialog dynamic consumption calculation logic: removed EMA smoothing for immediate manual input to ensure accurate recalculation, and retained flight time upon save.
- Improved Fuel Dialog layout for tablets (like Hugerock X7) in landscape mode by wrapping it in `SafeArea` with a 90% screen height constraint, and formatted the info blocks exactly per the new spec.

## [1.16.5] - 2026-09-05
### Added
- Added `correctInSimulator` toggle in Fuel Settings to optionally prevent EMA correction and recording flight data during simulation.
### Changed
- Wrapped Fuel Dialog content in a `SingleChildScrollView` and reduced paddings to prevent overflow on smaller tablets.
- Updated the "Last flight" info block in Fuel Dialog to dynamically calculate and display the prospective consumption as the user adjusts the remainder.

## [1.16.4] - 2026-09-05
### Fixed
- Reserved layout space for the overflow warning in the Fuel Dialog to prevent dialog height changes.

## [1.16.3] - 2026-09-05
### Changed
- Redesigned Fuel Dialog to a Glove-Friendly BottomSheet.
- Replaced standard buttons with `RepeatingIconButton` supporting continuous press for easier adjustments.
- Changed adjustment step from 0.5 to 0.1 liters.
- Added info block about the last flight duration.

## [1.15.2] - 2026-09-05
- Fixed map starting at (0, 0) and missing plane marker by using `getLastKnownPosition` before stream starts.
- Added missing `GeolocatorLocationService` declaration to AndroidManifest to prevent ForegroundService crash on startup.

## [1.15.1] - 2026-09-04
### Fixed
- Fixed background location tracking on Android by properly initializing `Geolocator` with `AndroidSettings` and `ForegroundNotificationConfig`.

## [1.15.0] - 2026-09-04
### Added
- Added strict standard GPX 1.1 namespaces and track name support to GPX exports.

## [1.14.1] - 2026-09-04
### Fixed
- Исправлено отображение Vz на Дашборде (ранее значение всегда было жестко задано как 0.0 из-за ошибки слияния).
- Расширен порог сброса буфера для Vz, чтобы избежать обнуления при редких обновлениях GPS или симуляции.

## [1.14.0] - 2026-09-04
### Added
- Расчет и отображение вертикальной скорости (Vz) на Дашборде с использованием сглаживания линейной регрессией.
- Новая категория настроек "Панель инструментов" (настройка окна сглаживания Vz).

## [1.13.0] - 2026-09-04
### Added
- Расчет и отображение времени и дистанции полёта на Dashboard (от старта до текущей позиции, суммарно для всех полётов или с начала трека до взлёта).

## [1.8.0] - 2026-09-03
### Added
- Added current version to the title bar on the Dashboard screen.

## [1.7.0] - 2026-09-03
### Added
- GPS track recording using internal GPS data.
- Rate-limiting configuration for track points (0.3s - 3.0s interval).
- Setting for track cleanup padding around detected flights (0s - 10s).
- GPX Export Module (`GpxWriter`) with intelligent segmentation.
  - Ability to split multiple detected flights into separate `.gpx` files.
  - Ability to trim excess ground time around flights ("clean up extra").
- UI dialog to prompt for track saving upon exiting the app or switching from internal GPS to Simulator.

### Fixed
- Fixed uninitialized `sharedPreferencesProvider` and missing `LocationEntity` imports which were failing unit tests.
- Fixed layout parsing during testing by injecting `MockTracksManager` and proper mock preferences.

## [1.3.1+1] - 2026-08-30
### Added
- Track selection and GPX replay simulation support.
- Flight detector pipeline to determine in-flight state.

# Changelog

All notable changes to this project will be documented in this file.

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

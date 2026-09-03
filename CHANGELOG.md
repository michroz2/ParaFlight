# Changelog

All notable changes to this project will be documented in this file.

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

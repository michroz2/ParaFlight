# Changelog
Все заметные изменения в этом проекте документируются в этом файле.

## [1.20.4] - 2026-09-11
### Changed
- Рефакторинг модуля ветра: внедрен класс `WindState`. 
- Телеметрия ветра теперь всегда показывает живые параметры рабочего буфера (размер N и угол ∟), независимо от успешности математических расчетов.

## [1.20.3] - 2026-09-10
### Added
- Добавлен вывод параметров буфера ветра (bufferSize и bufferAngle) на экран телеметрии.
- Расширена модель `WindCalculationResult` для хранения данных буфера.
- В математическое ядро Kasa Fit проброшен максимальный угол поворота (maxDelta).

## [1.20.2] - 2026-09-10
### Fixed
- Улучшен расчет амбиентного ветра. Собирается Минимальный рабочий буфер. Если расчеты дают некорректные ошибки, буфер очищается.   
- Внедрена защита от полета на акселераторе и улучшена точность расчета. 
- Внесены правки в `wind_config.dart` и `wind_pipeline.dart`
- Внесены правки в `wind_circle_painter.dart` и `wind_compass_overlay.dart`
- Внесены правки в `wind_provider.dart`

## [1.20.1] - 2026-09-10
### Fixed
- `wind_compass_overlay.dart`: стрелка направления ветра теперь отображается только в режиме полета и только при включенном тумблере в настройках ветра.
- телеметрия отображается в любом режиме по тумблеру в настройках телеметрии.

## [1.20.0] - 2026-09-10
### Changed
- Изменена иконка приложения на PF4.
### Рефакторинг. 
- Удален гейткипер из модуля ветра:
- Удалена логика паузы/возобновления расчёта ветра в зависимости от скорости (Gatekeeper). Теперь ветер пересчитывается непрерывно по мере поступления координат, что обеспечивает более точное отображение направления и силы ветра при резких изменениях скорости (взлёт/посадка).
- Упрощена реализация `wind_provider.dart`: убраны управляющие поля (`_isPaused`, `_activeStartTime`) и сложная логика их обработки. Оставлен только чистый пересчёт на основе `timestamp` и `speed`.

## [1.19.1] - 2026-09-10
### Fixed
- `gpx_writer.dart`: высота `<ele>` при записи GPX округляется до 0.1 м (`toStringAsFixed(1)`). Ранее записывалось 7–8 знаков после запятой.

## [1.19.0] - 2026-09-10
### Added
- Иконка приложения.

## [1.18.10] - 2026-09-10
### Fixed
- Исправлена анимация возврата карты на маркер самолёта. Теперь она работает плавно и корректно.
## [1.18.9] - 2026-09-09
### Refactor
- Нижняя панель симулятора вынесена в изолированный виджет 'SimulatorControlBar'.
- Верхняя панель телеметрии вынесена в изолированный виджет 'TopTelemetryBar'.
- Интерактивные кнопки вынесены в изолированный виджет 'InteractiveControls'.
## [1.18.8] - 2026-09-09
### Fixed Унификация потоков геолокации и фикс детектора полета (устранение Race Condition)
- Устранен архитектурный дефект в realGpsProvider: удален "черный ход" (асинхронный впрыск через Future.microtask), вызывавший рассинхронизацию модулей.
- flightDetectorProvider (State Machine) и RealGpsTrackNotifier переведены на строгое прослушивание единого источника правды — locationProvider.
- Восстановлена корректная работа паттернов взлета, посадки и расстановки маркеров для режима Встроенного GPS.
### Fixed / Refactor
- Устранены все issues flutter analyze (20 штук)
- Устранены критические угрозы падения (use_build_context_synchronously) в диалогах dashboard_screen и data_source_settings_screen.
- Зачищен мертвый код и исправлены null-aware выражения в логике геолокации.
- `location_state.dart`: удалён мёртвый код (`?? DateTime.now()` для non-nullable `timestamp`)
- `flight_detector_provider.dart`: удалено неиспользуемое поле `_lastTimestamp` и все его присвоения
- `dashboard_screen.dart`: добавлены недостающие `mounted`-проверки перед `_showFuelDialog` и `showDialog` в `Future.microtask`
- `dashboard_screen.dart`: `WillPopScope` заменён на `PopScope` (устарел с Flutter 3.12); логика диалога сохранения трека сохранена полностью
- `screen_settings_screen.dart`, `map_settings_screen.dart`, `data_source_settings_screen.dart`: `RadioListTile.groupValue`/`onChanged` заменены на `RadioGroup` (устарели с Flutter 3.32)

## [1.18.7] - 2026-09-09
### Added
- В диалоге «Выберите трек для симуляции» каждая строка теперь показывает размер файла. Формат: `Б` (< 1 КБ), `КБ` (< 1 МБ), `МБ` (≥ 1 МБ).

## [1.18.6] - 2026-09-09
### Docs
- Добавлены стандартные профессиональные шапки во все 47 Dart-файлов проекта. Формат: Файл / Проект / Версия / Цель / Изменения. Старые однострочные шапки `// Версия: X.X | Цель: ...` заменены расширенным блоком.

## [1.18.5] - 2026-09-08
### Fixed
- Исправлено перекрытие нижних панелей системными кнопками устройства в ландшафтном режиме на реальных устройствах Android. В ландшафте nav-bar перемещается вправо. Обёртка `SafeArea(bottom:true, left:true, right:true)` + `Padding(horizontal:16)` внутри корневого `Positioned(left:0, right:0)` для панели симулятора и панели управления картой.

## [1.18.4] - 2026-09-08
### Fixed
- Исправлена установка приложения на Android 11 и ниже. Разрешение `FOREGROUND_SERVICE_LOCATION` появилось только в Android 14 (API 34). Его наличие в манифесте без ограничения версии блокировало установку на старых устройствах. Добавлен атрибут `android:minSdkVersion="34"`.

## [1.18.3] - 2026-09-08
### Fixed
- Исправлено перекрытие нижних панелей (управление симулятором, кнопки масштаба карты и панель ветра) системным навигационным баром Android. Проблема была вызвана переходом на `edgeToEdge` дизайн экрана в версии 1.17.3. Нижние элементы интерфейса теперь обернуты в `SafeArea(bottom: true)`.

## [1.18.2] - 2026-09-08
### Fixed
- Восстановлено отображение элементов управления внизу экрана (например, панели симулятора). Причина: перевод `FlutterMap` в режим `Positioned` привел к сжатию основного `Stack` экрана до минимальных размеров. Добавлено `fit: StackFit.expand`, чтобы вернуть `Stack` на полный экран.

## [1.18.1] - 2026-09-08
### Fixed
- Исправлено позиционирование круга радара и шкалы масштаба. Из-за особенностей работы `Align` круг не совпадал с оптическим центром карты. Заменено на прямое смещение в пикселях через `Transform.translate`.

## [1.18.0] - 2026-09-08
### Changed
- UX: Оптический центр карты (маркер самолета) и компас радара сдвинуты вниз на 10% (до отметки 60% от верха экрана), чтобы освободить верхнюю часть интерфейса для приборной панели. Значение смещения вынесено в переменную `mapCenterOffsetPercent` (0.2).

## [1.17.3] - 2026-09-08
### Fixed
- В Режиме Кокпита добавлено принудительное отключение системного UI (SystemUiMode.immersiveSticky), чтобы убрать полупрозрачную подложку статус-бара на Android 14.

## [1.17.2] - 2026-09-08
### Fixed
- Отключение SafeArea (верхнего отступа статусбара) на Главном экране при активном Режиме Кокпита, чтобы панель приборов занимала весь экран.

## [1.17.1] - 2026-09-08
### Fixed
- Добавлено всплывающее окно подтверждения ("Трек записан") с кнопкой OK после успешного сохранения трека при выходе из приложения или переключении источника данных. 

## [1.17.0] - 2026-09-08
### Added
- Режим Кокпита (Kiosk Mode / App Pinning) для защиты от случайного сворачивания приложения системными жестами в реальном полете.
- Настройка в меню "Настройки экрана" с тумблером (по умолчанию включен). Жестко привязан к выбором Встроенного GPS, при симуляции режим отключается в фоне.

## [1.16.32] - 2026-09-08
### Fixed
- Восстановлен диалог сохранения трека при выходе через кнопку "Выход" в меню настроек. Ранее `SystemNavigator.pop()` игнорировал `WillPopScope`, из-за чего приложение закрывалось без сохранения.

## [1.16.31] - 2026-09-08
### Changed
- В диалог сохранения трека добавлена кнопка "Вернуться", позволяющая полностью отменить действие (выход из приложения или смену источника данных).
- Кнопка "Отмена" в диалоге переименована в "Стереть", её действие (завершить операцию без сохранения трека) осталось неизменным.

## [1.16.29] - 2026-09-08
### Changed
- Единая директория `Documents/ParaFlight/Tracks` для сохранения и симуляции GPX.
- Отказ от системного менеджера файлов (`file_picker`) в пользу прямого сканирования директории.
- Удалены встроенные треки из APK и логика их копирования (`TracksManager`).
- Добавлены разрешения `MANAGE_EXTERNAL_STORAGE` для создания публичной папки на Android 11+.
### Fixed
- Исправлена кодировка русского текста в файле `docs/CHANGELOG.md`.

## [1.16.28] - 2026-09-07
### Fixed
- Исправлено вычисление математической скорости и курса для обхода багов эмулятора Android. Сглаживание теперь производится по окну времени (4 секунды), а не по количеству точек. Ранее при прореживании GPS (например, 1 раз в 5 секунд) сглаживание по 4 точкам растягивалось на 20 секунд, из-за чего State Machine получала слишком инерционные данные и не могла вовремя детектировать взлет (маркеры не ставились).
- В вычисляемые данные добавлено математическое вычисление курса (heading), необходимое для работы фильтра дисквалификации CFV.

## [1.16.27] - 2026-09-07
### Changed
- Восстановлено использование оригинальной аппаратной скорости от встроенного GPS в State Machine по умолчанию.
- Добавлен новый тоггл "Данные эмулятора" в настройки источника данных. Если он включен, скорость и направление вычисляются математически по координатам (сглаженно). Это позволяет обходить баг Android эмулятора с нулевой скоростью, не затрагивая реальные полеты.

## [1.16.26] - 2026-09-07
### Changed
- Унифицирована логика расчета скорости (speed) в FlightDetectorPipeline. Теперь детектор полета игнорирует аппаратную скорость GPS (которая в эмуляторе Android при проигрывании GPX всегда равна 0.0) и вычисляет сглаженную скорость самостоятельно на основе координат (deltaDist / deltaTime). Это гарантирует 100% идентичную работу State Machine независимо от источника данных (Simulator или Внутренний GPS).

## [1.16.25] - 2026-09-07
### Fixed
- Исправлен сброс State Machine (FlightDetectorPipeline): старая логика определения перемотки (прыжок времени > 2000мс) конфликтовала с прореженным потоком GPS (интервал 5000мс) и приводила к бесконечному сбросу пайплайна. Логика переписана: для симулятора перемотка определяется по индексу пойнтера (index gap > 1), а для реального GPS сброс пайплайна из-за потерь сигнала (gap > 2000ms) полностью отключен.

## [1.16.24] - 2026-09-07
### Fixed
- Устранен баг 'Мертвого порта' при переключении с Симулятора обратно на Внутренний GPS. Теперь сервис принудительно делает restart, если он не успел полностью погаснуть, а фоновый изолят динамически обновляет sendPort, гарантируя доставку координат в UI.

## [1.16.23] - 2026-09-07
### Fixed
- Исправлено смешивание данных: фоновый GPS-сервис теперь корректно завершается (autoDispose) при переключении на Симулятор, а инъекция координат блокируется, если выбран не внутренний GPS. За счет этого устранены аномальные скачки расстояния и сбросы стейтов в режиме симуляции.

## [1.16.22] - 2026-09-06
### Changed
- Откат временного фикса v1.16.21.
- Внедрено централизованное прореживание GPS-координат (downsampling) на уровне `realGpsProvider`. Теперь `RealGpsTrackNotifier` и `FlightDetectorNotifier` получают идентичный поток прореженных точек, исключая возможность рассинхронизации стейтов и визуализации.

## [1.16.0] - 2026-09-05
### Added
- Added Fuel Tracking system (Учёт топлива) with dynamic calculation in flight based on EMA.
- Added Fuel settings toggle and configuration in Settings.
- Added interactive Fuel dialog on the Dashboard to input remainder and added fuel.
- Added adjustable sliders for Tank Capacity (0-30L) and Average Consumption (0-15L/h).
- Added toggle for automatic EMA consumption correction.

## [1.16.18] - 2026-09-06
### Added
- Implemented **Fast-Forward Background Isolate Strategy** using `flutter_foreground_task` to prevent Android Doze Mode and Flutter Engine from suspending the GPS stream when the app goes into the background. 
- Transferred the rate limiting logic (based on `gpsRecordIntervalSec`) directly into the background isolate to protect the Dart Event Loop from overflowing with messages while the UI isolate is suspended.
- Switched from the legacy Android LocationManager back to FusedLocationProviderClient for significantly improved battery efficiency and precision.

## [1.16.17] - 2026-09-06
### Added
- Added a diagnostic `Timer.periodic` in `main.dart` to determine if the Flutter Engine is suspending the Dart UI Isolate when the app goes into the background on Android.

## [1.16.16] - 2026-09-06
### Fixed
- Hardened background tracking against Riverpod widget-tree lifecycle dormancy by moving `realGpsTrackProvider` and `flightDetectorProvider` listeners entirely outside of the Flutter widget tree. They are now attached directly to a standalone `ProviderContainer` in `main.dart`, guaranteeing they never pause even if the UI element tree is heavily suspended or reconstructed by the OS.

## [1.16.15] - 2026-09-06
### Fixed
- Fixed build failure caused by `permission_handler` v13.0.2 requiring Android API 37 by downgrading to `permission_handler: ^11.3.1` which is compatible with the stable API 34.

## [1.16.14] - 2026-09-06
### Added
- Added `permission_handler` package to explicitly request `POST_NOTIFICATIONS` and `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` at startup. This prevents Android 13+ from silently killing the `Geolocator` Foreground Service by ensuring it has a visible sticky notification and is whitelisted from battery optimization.

## [1.16.13] - 2026-09-06
### Fixed
- Fixed critical bug where GPS tracking, flight detection, and path recording would stop working in the background (or when navigating away from the Dashboard screen). The bug was caused by Riverpod providers (`realGpsTrackProvider`, `flightDetectorProvider`) going dormant when losing all UI listeners. Added global watchers in `ParaFlightApp` to keep core tracking systems alive continuously.
- Added `ACCESS_BACKGROUND_LOCATION` permission and logic to explicitly request it to ensure the Android OS does not throttle the event channel while the app is in the background.

## [1.16.12] - 2026-09-06
### Fixed
- Fixed `SecurityException: Neither user nor current process has android.permission.WAKE_LOCK` crash when `Geolocator` starts the foreground service. Added `WAKE_LOCK` permission to `AndroidManifest.xml` to satisfy `enableWakeLock: true` setting in `AndroidSettings`.

## [1.16.11] - 2026-09-06
### Added
- Added full diagnostic logging (debugPrint) across the entire geolocation data chain to trace the source of the emulator marker bug.
- Added a 2-second timeout to `Geolocator.getLastKnownPosition()` to prevent the location stream from hanging indefinitely on Android emulators.

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

## [1.3.1] - 2026-09-03 (GPX Simulator File Selection)
### Added
- Полная поддержка выбора GPX файла для симуляции из внутренней файловой системы.
- Менеджер треков (TracksManager), который копирует треки из ресурсов ssets/tracks при первом запуске в папку 	racks документов приложения.
- Кнопка импорта новых GPX файлов из файловой системы Android с использованием пакета ile_picker.
- Провайдер selectedGpxFileProvider для переключения текущего трека в реальном времени.

### Fixed
- Исправлено отображение переменной имени файла GPX в настройках симулятора.

### Changed
- Обновлен экран DataSourceSettingsScreen: добавлен вывод текущего файла и диалог выбора трека.
- При смене источника симуляции старый трек полностью выгружается и плеер PlaybackNotifier сбрасывается для исключения артефактов.
- Удален вшитый файл mock_flight.gpx, теперь все треки управляются динамически через ssets/tracks/.


## [1.2.1] - 2026-09-02 (UI Refinements & Core Config)
### Added
- Компасная стрелка (N) на радаре, адаптирующаяся к вращению карты. Отрисовывается только в режиме "Курс сверху".
- Плавная анимация центрирования карты по кнопке и таймауту (через AnimationController, 1 секунда).
- Отмена сохранения источника данных: приложение теперь жестко стартует в режиме "Встроенный GPS".

### Fixed
- Переработан UI симулятора: контроллер стал максимально компактным и навсегда зафиксирован снизу (больше не прячется по тапу).
- Выстроена иерархия панелей управления: панель кнопок (Linear Control Bar) всплывает над плеером симулятора без перекрытий.
- Уменьшены отступы подложки радарного масштаба для большей аккуратности.


## [1.2.0] - 2026-09-02 (Streaming GPX & Map Controls)
### Added
- Интерактивное управление картой: кнопка центрирования и свободный обзор.
- Временная панель кнопок управления масштабом (+/-) и компасом.
- Масштаб радара привязан к географической сетке.
- Потоковый парсер GPX в фоновом Isolate через RegExp для ускорения загрузки длинных треков (O(N) по памяти и времени).
- ProgressBar в UI для отображения хода потоковой загрузки GPX.

### Fixed
- Исправлена критическая ошибка RangeError при gpxSmoothingWindow = 0.
- Исправлено залипание карты на стартовых координатах из-за race condition во время загрузки (добавлен onMapReady).

## [1.1.0] - 2026-09-01 (HUD Redesign)
### Added
- Полный редизайн панели приборов (Dashboard). Добавлен авиационный приборный стиль: тёмно-серые блоки с контрастными белыми цифрами и желтыми заголовками.
- Реализован адаптивный виджет `InstrumentBlock` с защитой от переноса текста (`FittedBox`).
- Расположение приборов адаптировано под углы экрана: SOG (слева), ALT (справа), BRG (по центру).
- Заложены заглушки под будущие метрики: Время полета, Дистанция, Вертикальная скорость (Vz) и Топливо.

## [1.0.0] - 2026-09-01 (MVP Release)
### Added
- Персистентность настроек (SharedPreferences): сохранение источника данных (GPS/Симулятор), ориентации дисплея и режима Wakelock.
- Корректный выход из приложения (`SystemNavigator.pop`) через меню настроек.
- Официальное достижение статуса MVP (Minimum Viable Product).

## [0.5.0] - 2026-09-01
### Added
- Аппаратная интеграция GPS (F-03): пакет `geolocator`, Android-пермиссии (вкл. Foreground Location).
- Провайдер реального GPS с проверкой прав доступа на лету.
- Выбор источника данных в настройках (Симулятор / Встроенный GPS смартфона).
- Скрипт `run_multidevice.bat` с интерактивным меню запуска для фермы устройств.

### Fixed
- Исправлено отображение переменной имени файла GPX в настройках симулятора.

### Changed
- UI главного экрана адаптирован под оба режима (динамическое скрытие панели плеера).
- Маркер пилота теперь отображается всегда по реальным координатам, а не только при наличии трека.
- Провайдер ветра автоматически очищает историю вычислений при смене источника данных во избежание фантомных показаний.
- Трек полета (`flightPathProvider`) для реального GPS накапливается динамически во время движения.
- Временно отключена инкрементальная компиляция Kotlin в `gradle.properties` для стабильной сборки плагинов.

## [0.4.0] - 2026-09-01
### Added
- Базовая архитектура настроек (Config UI Gateway) со скрытым доступом по долгому нажатию на карту.
- Главный экран категорий настроек и заглушка для экрана выбора источника данных.

### Fixed
- Исправлено отображение переменной имени файла GPX в настройках симулятора.

### Changed
- Удален глобальный системный `AppBar` с главного экрана для максимизации полезного пространства карты.
- Выплывающий сверху желтый "Title bar" с иконкой настроек при долгом нажатии.

### Fixed
- Закрыт технический долг по оформлению файлов в `lib/` (актуализация шапок, версий, маркеров и комментариев закрывающихся скобок).

## [0.3.0] - 2026-09-01
### Added
- Модуль ветра (F-02) на базе Kasa Fit (алгебраический фиттинг окружности).
- Панель Time Warp для симулятора (F-01) с контролем воспроизведения.
- Парсер GPX-файлов (F-00) с фильтрацией и сглаживанием координат.
- Визуализация трека и HUD на FlutterMap (отображение курса, скорости, высоты и вектора ветра).
- Окно настроек `WindConfig` для тонкого тюнинга конвейера данных.

### Fixed
- Исправлено отображение переменной имени файла GPX в настройках симулятора.

### Changed
- Рефакторинг движка симуляции на управляемый `PlaybackNotifier`.
- Улучшена обработка GPX: вычисление дистанции и азимута вынесено на прямое сравнение крайних точек окна (Spatial Decimation).


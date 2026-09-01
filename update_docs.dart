import 'dart:io';
void main() {
  final file = File('docs/CHANGELOG.md');
  final content = file.readAsStringSync();
  final index = content.indexOf('## [1.1.0]');
  final header = content.substring(0, index);
  final rest = content.substring(index);
  
  final newLog = '''## [1.2.0] - 2026-09-02 (Streaming GPX & Map Controls)
### Added
- Интерактивное управление картой: кнопка центрирования и свободный обзор.
- Временная панель кнопок управления масштабом (+/-) и компасом.
- Масштаб радара привязан к географической сетке.
- Потоковый парсер GPX в фоновом Isolate через RegExp для ускорения загрузки длинных треков (O(N) по памяти и времени).
- ProgressBar в UI для отображения хода потоковой загрузки GPX.

### Fixed
- Исправлена критическая ошибка RangeError при gpxSmoothingWindow = 0.
- Исправлено залипание карты на стартовых координатах из-за race condition во время загрузки (добавлен onMapReady).

''';
  file.writeAsStringSync(header + newLog + rest);
}

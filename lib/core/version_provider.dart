// =============================================================================
// Файл:    version_provider.dart
// Проект:  ParaFlight
// Версия:  0.1.0
// Цель:    Провайдер информации о версии приложения через package_info_plus
// Изменения:
//   0.1.0 - Первичная реализация
// =============================================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

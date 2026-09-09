// =============================================================================
// Файл:    dashboard_config_provider.dart
// Проект:  ParaFlight
// Версия:  0.1.0
// Цель:    Провайдер настроек Дашборда (Панели инструментов)
// Изменения:
//   0.1.0 - Первичная реализация
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/preferences/preferences_provider.dart';

class DashboardConfig {
  final int vzWindowSec;

  const DashboardConfig({
    required this.vzWindowSec,
  });

  DashboardConfig copyWith({
    int? vzWindowSec,
  }) {
    return DashboardConfig(
      vzWindowSec: vzWindowSec ?? this.vzWindowSec,
    );
  }
} // конец класса DashboardConfig

class DashboardConfigNotifier extends StateNotifier<DashboardConfig> {
  final Ref ref;

  DashboardConfigNotifier(this.ref)
      : super(const DashboardConfig(
          vzWindowSec: 3,
        )) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final prefs = ref.read(sharedPreferencesProvider);
    final vzWindow = prefs.getInt('dashboardVzWindowSec') ?? 3;
    
    state = DashboardConfig(
      vzWindowSec: vzWindow,
    );
  } // конец метода _loadFromPrefs

  Future<void> setVzWindowSec(int seconds) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt('dashboardVzWindowSec', seconds);
    state = state.copyWith(vzWindowSec: seconds);
  }
} // конец класса DashboardConfigNotifier

final dashboardConfigProvider = StateNotifierProvider<DashboardConfigNotifier, DashboardConfig>((ref) {
  return DashboardConfigNotifier(ref);
});

// =============================================================================
// Файл:    advanced_mode_provider.dart
// Проект:  ParaFlight
// Цель:    Провайдер расширенного режима настроек (Advanced Mode)
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/preferences/preferences_provider.dart';

class AdvancedModeNotifier extends StateNotifier<bool> {
  final Ref ref;

  AdvancedModeNotifier(this.ref) : super(false) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final prefs = ref.read(sharedPreferencesProvider);
    state = prefs.getBool('is_advanced_mode') ?? false;
  }

  Future<void> toggle() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final newState = !state;
    await prefs.setBool('is_advanced_mode', newState);
    state = newState;
  }

  Future<void> reset() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('is_advanced_mode', false);
    state = false;
  }
}

final advancedModeProvider = StateNotifierProvider<AdvancedModeNotifier, bool>((ref) {
  return AdvancedModeNotifier(ref);
});

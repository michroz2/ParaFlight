// Версия: 0.1.0 | Цель: Провайдер доступа к SharedPreferences

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Новое: Глобальный провайдер для доступа к сохраненным настройкам.
// Инициализируется через overrideWithValue в main.dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider не был инициализирован');
}); // конец sharedPreferencesProvider

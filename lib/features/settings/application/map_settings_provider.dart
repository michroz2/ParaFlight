// Версия: 0.1.0 | Цель: Настройки поведения карты (Таймеры и дефолтный компас)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/preferences/preferences_provider.dart';

enum MapRotationMode { north, heading }

class MapSettings {
  final int uiAutoHideSeconds;
  final int mapAutoCenterSeconds;
  final MapRotationMode defaultRotationMode;

  const MapSettings({
    required this.uiAutoHideSeconds,
    required this.mapAutoCenterSeconds,
    required this.defaultRotationMode,
  });

  MapSettings copyWith({
    int? uiAutoHideSeconds,
    int? mapAutoCenterSeconds,
    MapRotationMode? defaultRotationMode,
  }) {
    return MapSettings(
      uiAutoHideSeconds: uiAutoHideSeconds ?? this.uiAutoHideSeconds,
      mapAutoCenterSeconds: mapAutoCenterSeconds ?? this.mapAutoCenterSeconds,
      defaultRotationMode: defaultRotationMode ?? this.defaultRotationMode,
    );
  }
} // конец класса MapSettings

class MapSettingsNotifier extends StateNotifier<MapSettings> {
  final Ref ref;

  MapSettingsNotifier(this.ref)
      : super(const MapSettings(
          uiAutoHideSeconds: 5,
          mapAutoCenterSeconds: 5,
          defaultRotationMode: MapRotationMode.north,
        )) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final prefs = ref.read(sharedPreferencesProvider);
    final uiHide = prefs.getInt('uiAutoHideSeconds') ?? 5;
    final autoCenter = prefs.getInt('mapAutoCenterSeconds') ?? 5;
    final rotModeStr = prefs.getString('defaultRotationMode') ?? 'north';
    
    state = MapSettings(
      uiAutoHideSeconds: uiHide,
      mapAutoCenterSeconds: autoCenter,
      defaultRotationMode: rotModeStr == 'heading' ? MapRotationMode.heading : MapRotationMode.north,
    );
  } // конец метода _loadFromPrefs

  Future<void> setUiAutoHide(int seconds) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt('uiAutoHideSeconds', seconds);
    state = state.copyWith(uiAutoHideSeconds: seconds);
  }

  Future<void> setMapAutoCenter(int seconds) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt('mapAutoCenterSeconds', seconds);
    state = state.copyWith(mapAutoCenterSeconds: seconds);
  }

  Future<void> setDefaultRotation(MapRotationMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('defaultRotationMode', mode == MapRotationMode.heading ? 'heading' : 'north');
    state = state.copyWith(defaultRotationMode: mode);
  }
} // конец класса MapSettingsNotifier

final mapSettingsProvider = StateNotifierProvider<MapSettingsNotifier, MapSettings>((ref) {
  return MapSettingsNotifier(ref);
});

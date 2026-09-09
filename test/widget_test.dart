import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:paraflight/main.dart';
import 'dart:io';
import 'package:paraflight/core/preferences/preferences_provider.dart';
import 'package:paraflight/core/storage/local_storage_service.dart'; // Изменение: Импорт нового сервиса

class MockLocalStorageService implements LocalStorageService {
  @override
  Future<void> init() async {}
  @override
  Future<List<File>> getGpxFiles() async => [];
  @override
  Future<String> saveTrack(String fileName, String content) async => '';
  @override
  Future<bool> fileExists(String fileName) async => false;
}

void main() {
  testWidgets('Smoke test for ParaFlightApp', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    PackageInfo.setMockInitialValues(
      appName: 'ParaFlight',
      packageName: 'com.example.paraflight',
      version: '1.16.29',
      buildNumber: '1',
      buildSignature: '',
    );

    final localStorageService = MockLocalStorageService(); // Изменение: мок

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorageService), // Изменение: провайдер
        ],
        child: const ParaFlightApp(),
      ),
    );

    // Wait for async operations to complete
    await tester.pumpAndSettle();

    // Verify that our title is present.
    expect(find.textContaining('ParaFlight'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paraflight/main.dart';
import 'dart:io';
import 'package:paraflight/core/preferences/preferences_provider.dart';
import 'package:paraflight/core/location/tracks_manager.dart';

class MockTracksManager implements TracksManager {
  @override
  Future<void> initialize(SharedPreferences prefs) async {}
  @override
  Future<Directory> getTracksDirectory() async => Directory('');
  @override
  Future<List<File>> getAvailableTracks() async => [];
  @override
  Future<File?> importTrack() async => null;
}

void main() {
  testWidgets('Smoke test for ParaFlightApp', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    PackageInfo.setMockInitialValues(
      appName: 'ParaFlight',
      packageName: 'com.example.paraflight',
      version: '1.15.2',
      buildNumber: '1',
      buildSignature: '',
    );

    final tracksManager = MockTracksManager();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tracksManagerProvider.overrideWithValue(tracksManager),
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

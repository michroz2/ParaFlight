// Версия: 0.1.0 | Цель: Менеджер треков для копирования из ресурсов и выбора файлов

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tracksManagerProvider = Provider<TracksManager>((ref) {
  return TracksManager();
});

class TracksManager {
  static const String _tracksDirName = 'tracks';

  Future<void> initialize(SharedPreferences prefs) async {
    final tracksDir = await getTracksDirectory();
    if (!await tracksDir.exists()) {
      await tracksDir.create(recursive: true);
    } // конец if

    // Читаем манифест ассетов для копирования файлов
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      
      final trackAssets = manifest.listAssets()
          .where((String key) => key.startsWith('assets/tracks/') && key.endsWith('.gpx'))
          .toList();

      for (final assetPath in trackAssets) {
        final fileName = path.basename(assetPath);
        final file = File(path.join(tracksDir.path, fileName));
        
        // Копируем файл из ресурсов, если его нет в файловой системе
        if (!await file.exists()) {
          final data = await rootBundle.load(assetPath);
          final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          await file.writeAsBytes(bytes);
        } // конец if
      } // конец for
    } catch (e) {
      // Игнорируем ошибку чтения AssetManifest, если файлов нет
      print('Ошибка чтения ресурсов треков: $e');
    } // конец try-catch
  }

  Future<Directory> getTracksDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return Directory(path.join(appDocDir.path, _tracksDirName));
  }

  Future<List<File>> getAvailableTracks() async {
    final tracksDir = await getTracksDirectory();
    if (!await tracksDir.exists()) {
      return [];
    }
    
    final List<File> files = [];
    final entities = await tracksDir.list().toList();
    for (final entity in entities) {
      if (entity is File && entity.path.toLowerCase().endsWith('.gpx')) {
        files.add(entity);
      }
    }
    return files;
  }

  Future<File?> importTrack() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gpx'],
      );

      if (files.isNotEmpty && files.first.path != null) {
        final File pickedFile = File(files.first.path!);
        final tracksDir = await getTracksDirectory();
        
        final fileName = path.basename(pickedFile.path);
        final newPath = path.join(tracksDir.path, fileName);
        
        final importedFile = await pickedFile.copy(newPath);
        return importedFile;
      }
    } catch (e) {
      print('Ошибка при импорте файла: $e');
    }
    return null;
  }
} // конец класса TracksManager

// Версия: 0.1.0 | Цель: Сервис для работы с локальной файловой системой (чтение и запись треков в публичную папку)

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Новое: Провайдер для сервиса хранилища
final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

class LocalStorageService {
  Future<String> _getTracksDirectoryPath() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      if (dir != null) {
        // dir.path обычно выглядит так: /storage/emulated/0/Android/data/com.package/files
        final path = dir.path;
        final index = path.indexOf('/Android/');
        if (index != -1) {
          final root = path.substring(0, index);
          return '$root/Documents/ParaFlight/Tracks';
        }
      } // конец if
      return '/storage/emulated/0/Documents/ParaFlight/Tracks'; // Fallback
    } else {
      // Для iOS или других платформ используем стандартную папку документов
      final appDocDir = await getApplicationDocumentsDirectory();
      return '${appDocDir.path}/ParaFlight/Tracks';
    } // конец if-else
  } // конец метода _getTracksDirectoryPath

  // Новое: Инициализация с запросом прав и созданием папки
  Future<void> init() async {
    if (Platform.isAndroid) {
      // Запрашиваем полный доступ к файлам на Android 11+
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        await Permission.manageExternalStorage.request();
      } // конец if
      
      // Запрашиваем обычный доступ для старых Android
      var storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        await Permission.storage.request();
      } // конец if
    } // конец if

    final dirPath = await _getTracksDirectoryPath();
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    } // конец if
  } // конец метода init

  // Новое: Метод получения всех GPX файлов
  Future<List<File>> getGpxFiles() async {
    final dirPath = await _getTracksDirectoryPath();
    final dir = Directory(dirPath);
    
    if (!await dir.exists()) {
      return [];
    } // конец if

    final List<File> files = [];
    final entities = await dir.list().toList();
    
    for (final entity in entities) {
      if (entity is File && entity.path.toLowerCase().endsWith('.gpx')) {
        files.add(entity);
      } // конец if
    } // конец for
    
    return files;
  } // конец метода getGpxFiles

  // Новое: Проверка существования файла
  Future<bool> fileExists(String fileName) async {
    final dirPath = await _getTracksDirectoryPath();
    final file = File('$dirPath/$fileName');
    return file.exists();
  } // конец метода fileExists

  // Новое: Метод сохранения трека
  Future<String> saveTrack(String fileName, String content) async {
    final dirPath = await _getTracksDirectoryPath();
    final dir = Directory(dirPath);
    
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    } // конец if

    final file = File('$dirPath/$fileName');
    await file.writeAsString(content);
    return file.path;
  } // конец метода saveTrack
} // конец класса LocalStorageService

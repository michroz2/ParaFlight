/// Сущность, представляющая данные геолокации
class LocationEntity {
  /// Широта в градусах
  final double latitude;

  /// Долгота в градусах
  final double longitude;

  /// Высота над уровнем моря в метрах
  final double altitude;

  /// Скорость движения в м/с
  final double speed;

  /// Направление движения (курс) в градусах
  final double heading;

  /// Временная метка получения координат
  final DateTime timestamp;

  /// Конструктор для создания неизменяемой сущности
  const LocationEntity({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.heading,
    required this.timestamp,
  });
}

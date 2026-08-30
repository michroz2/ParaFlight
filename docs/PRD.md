# Product Requirements Document (PRD)
**Project:** ParaFlight
**Status:** Approved (v3.0 - Architecture Finalized)

## 1. Vision
Приложение используется пилотами Парамоторов (Powered Paraglider) во время полёта как приборная доска.

## 2. Target Platforms
- Android-смартфоны
- Android-планшеты (с учетом возможной ландшафтной ориентации)

## 3. Minimum Viable Product (MVP)
- **F-00: Ядро геолокации** - Единый интерфейс LocationService (Dependency Injection) для GPS, BLE и KML/GPX симуляторов.
- **F-01: Главный экран** - Отображается карта (flutter_map), трек от места старта, время, скорость, высота.
- **F-02: Ветер** - Вычисляется непрерывно на основе поступающих данных GPS. Алгоритм и мат. модель зафиксированы как исследовательская задача.

## 4. Technical Constraints
- **Architecture Pattern:** Feature-First (Clean Architecture)
- **State Management:** Riverpod

// =============================================================================
// Файл:    save_track_dialog.dart
// Проект:  ParaFlight
// Версия:  0.1.0
// Цель:    Диалог сохранения трека с выбором имени файла
// Изменения:
//   0.1.0 - Первичная реализация
// =============================================================================
import 'package:flutter/material.dart';

class SaveTrackDialog extends StatefulWidget {
  final int flightCount;
  final int totalPoints;

  const SaveTrackDialog({
    super.key,
    required this.flightCount,
    required this.totalPoints,
  });

  @override
  State<SaveTrackDialog> createState() => _SaveTrackDialogState();
}

class _SaveTrackDialogState extends State<SaveTrackDialog> {
  bool _cleanUpExtra = false;
  bool _splitFlights = false;

  @override
  Widget build(BuildContext context) {
    if (widget.flightCount == 0) {
      return AlertDialog(
        title: const Text('Записать трек?'),
        content: Text(
          'В текущем треке нет зафиксированных полетов.\nВсего точек: ${widget.totalPoints}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop({'action': 'abort'}), // Изменение: отмена действия
            child: const Text('Вернуться'), // Новое: кнопка возврата
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop({'action': 'erase'}), // Изменение: стирание
            child: const Text('Стереть'), // Изменение: переименована кнопка
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(
              context,
            ).pop({'action': 'save', 'cleanUpExtra': false, 'splitFlights': false}), // Изменение: добавлено 'action': 'save'
            child: const Text('Записать'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Записать трек?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Зафиксировано полетов: ${widget.flightCount}'),
          Text('Всего точек: ${widget.totalPoints}'),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Очистить лишнее'),
            subtitle: const Text('Оставить только полеты и немного земли'),
            value: _cleanUpExtra,
            onChanged: (val) {
              setState(() {
                _cleanUpExtra = val ?? false;
                if (_cleanUpExtra) {
                  // При включении очистки, если полетов несколько, они будут разделены
                  _splitFlights = false;
                }
              });
            },
          ),
          if (widget.flightCount > 1)
            CheckboxListTile(
              title: const Text('Разбить на отдельные полёты'),
              value: _cleanUpExtra ? true : _splitFlights,
              enabled: !_cleanUpExtra,
              onChanged: (val) {
                if (!_cleanUpExtra) {
                  setState(() => _splitFlights = val ?? false);
                }
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop({'action': 'abort'}), // Изменение: отмена действия
          child: const Text('Вернуться'), // Новое: кнопка возврата
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop({'action': 'erase'}), // Изменение: стирание
          child: const Text('Стереть'), // Изменение: переименована кнопка
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'action': 'save', // Изменение: добавлено 'action': 'save'
              'cleanUpExtra': _cleanUpExtra,
              'splitFlights':
                  _cleanUpExtra ||
                  _splitFlights, // Если cleanUpExtra, то всегда сплитим (по логике)
            });
          },
          child: const Text('Записать'),
        ),
      ],
    );
  }
}

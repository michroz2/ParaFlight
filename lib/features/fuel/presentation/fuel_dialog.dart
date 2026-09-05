// Версия: 0.2.0 | Цель: Диалоговое окно управления топливом (Glove-Friendly BottomSheet)

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/fuel_provider.dart';
import 'widgets/repeating_icon_button.dart';

class FuelDialog extends ConsumerStatefulWidget {
  const FuelDialog({super.key});

  @override
  ConsumerState<FuelDialog> createState() => _FuelDialogState();
}

class _FuelDialogState extends ConsumerState<FuelDialog> {
  late double remainder;
  late double added;
  late double tankCapacity;
  late double lastFlightDurationHours;
  
  // Начальное значение для поля "Добавлено" (на случай выноса в настройки)
  final double _initialAddedValue = 0.0;

  @override
  void initState() {
    super.initState();
    final fuelState = ref.read(fuelProvider);
    remainder = fuelState.remainder;
    tankCapacity = fuelState.tankCapacity;
    lastFlightDurationHours = fuelState.lastFlightDurationHours;
    added = _initialAddedValue;
  }

  double get inTank => remainder + added;

  String _formatDuration(double hours) {
    if (hours <= 0) return "Нет данных";
    final int h = hours.floor();
    final int m = ((hours - h) * 60).round();
    if (h > 0) {
      return "$h ч $m мин";
    }
    return "$m мин";
  }

  @override
  Widget build(BuildContext context) {
    final isOverflow = inTank > tankCapacity;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок
          const Text(
            'Топливо (л)',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // Инфо-блок
          Text(
            'Крайний полёт: ${_formatDuration(lastFlightDurationHours)}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Блок Остатка
          _buildRow('Остаток:', remainder, (val) {
            setState(() {
              remainder = min(max(0.0, val), tankCapacity);
            });
          }),
          const SizedBox(height: 16),
          
          // Блок Добавлено
          _buildRow('Добавлено:', added, (val) {
            setState(() {
              added = max(0.0, val);
            });
          }),
          const SizedBox(height: 24),
          
          // Кнопка Полный бак
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  added = max(0.0, tankCapacity - remainder);
                });
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'ПОЛНЫЙ БАК (${tankCapacity.toStringAsFixed(1)} л)',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Итог
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'В баке: ',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                inTank.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isOverflow ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          Visibility(
            visible: isOverflow,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Внимание: превышена ёмкость бака!',
                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Подвал (кнопки)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('ОТМЕНА', style: TextStyle(fontSize: 20)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(fuelProvider.notifier).updateFuel(remainder, added);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('ПОДТВЕРДИТЬ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RepeatingIconButton(
              icon: Icons.remove_circle,
              onTap: () {
                // Шаг 0.1, округляем во избежание проблем с плавающей точкой
                final nextVal = double.parse((value - 0.1).toStringAsFixed(1));
                if (nextVal >= 0.0) {
                  onChanged(nextVal);
                }
              },
            ),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            RepeatingIconButton(
              icon: Icons.add_circle,
              onTap: () {
                final nextVal = double.parse((value + 0.1).toStringAsFixed(1));
                onChanged(nextVal);
              },
            ),
          ],
        ),
      ],
    );
  }
}

// Версия: 0.2.0 | Цель: Диалоговое окно управления топливом (Glove-Friendly BottomSheet)

import 'dart:math';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/fuel_provider.dart';
import 'widgets/repeating_icon_button.dart';
import '../../../core/location/location_state.dart';

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
  late double initialRemainder;
  
  // Начальное значение для поля "Добавлено" (на случай выноса в настройки)
  final double _initialAddedValue = 0.0;

  @override
  void initState() {
    super.initState();
    final fuelState = ref.read(fuelProvider);
    remainder = fuelState.remainder;
    initialRemainder = fuelState.remainder;
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
    final fuelState = ref.watch(fuelProvider);
    final isSimulator = ref.watch(dataSourceProvider) == DataSource.simulator;

    // Динамический расчет расхода
    double dynamicConsumption = fuelState.averageConsumption;
    if (lastFlightDurationHours > 0 && remainder != initialRemainder) {
      dynamicConsumption = fuelState.averageConsumption + ((initialRemainder - remainder) / lastFlightDurationHours);
    }

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height,
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 10,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок
              const Text(
                'Топливо (л)',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              
              // Инфо-блок
              if (lastFlightDurationHours <= 0)
                const Text(
                  'Крайний полёт: Нет данных',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.center,
                )
              else
                Column(
                  children: [
                    Text(
                      'Крайний полёт: ${_formatDuration(lastFlightDurationHours)}, Остаток: ${initialRemainder.toStringAsFixed(1)} л',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              if (lastFlightDurationHours <= 0)
              Text(
                'Расход: ${fuelState.averageConsumption.toStringAsFixed(1)} л/ч',
                style: const TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ) 
              else 
              Text(
                'Расход: ${fuelState.averageConsumption.toStringAsFixed(1)} л/ч >> Новый расход: ${dynamicConsumption.toStringAsFixed(1)} л/ч',
                style: const TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),

            // Блок Остатка
            _buildRow('Остаток (уточнить!):', remainder, (val) {
              setState(() {
                remainder = min(max(0.0, val), tankCapacity);
              });
            }),
            const SizedBox(height: 6),
            
            // Блок Добавлено
            _buildRow('Добавлено:', added, (val) {
              setState(() {
                added = max(0.0, val);
              });
            }),
            const SizedBox(height: 6),
            
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
                  'ПОЛНЫЙ БАК! (${tankCapacity.toStringAsFixed(1)} л)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 6),
            
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
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  'Превышена ёмкость бака!',
                  style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Подвал (кнопки)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('ОТМЕНА', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(fuelProvider.notifier).updateFuel(remainder, added, isSimulator);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('ПОДТВЕРДИТЬ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildRow(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
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

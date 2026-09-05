// Версия: 0.1.0 | Цель: Диалоговое окно управления топливом

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/fuel_provider.dart';

class FuelDialog extends ConsumerStatefulWidget {
  const FuelDialog({super.key});

  @override
  ConsumerState<FuelDialog> createState() => _FuelDialogState();
}

class _FuelDialogState extends ConsumerState<FuelDialog> {
  late double remainder;
  double added = 0.0;
  late double tankCapacity;

  @override
  void initState() {
    super.initState();
    final fuelState = ref.read(fuelProvider);
    remainder = fuelState.remainder;
    tankCapacity = fuelState.tankCapacity;
  }

  double get inTank => remainder + added;

  @override
  Widget build(BuildContext context) {
    final isOverflow = inTank > tankCapacity;

    return AlertDialog(
      title: const Text('Топливо (л)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow('Остаток:', remainder, (val) {
            setState(() {
              remainder = val;
            });
          }),
          const SizedBox(height: 16),
          _buildRow('Добавлено:', added, (val) {
            setState(() {
              added = val;
            });
          }),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'В баке:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                inTank.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isOverflow ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          if (isOverflow)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Внимание: превышена ёмкость бака!',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(fuelProvider.notifier).updateFuel(remainder, added);
            Navigator.of(context).pop();
          },
          child: const Text('ОК'),
        ),
      ],
    );
  }

  Widget _buildRow(String label, double value, ValueChanged<double> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                if (value >= 0.5) onChanged(value - 0.5);
              },
            ),
            SizedBox(
              width: 50,
              child: Text(
                value.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                onChanged(value + 0.5);
              },
            ),
          ],
        ),
      ],
    );
  }
}

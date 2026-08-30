import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/location/location_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ParaFlight'),
      ),
      body: locationAsync.when(
        data: (location) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Широта: ${location.latitude}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                'Долгота: ${location.longitude}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                'Высота: ${location.altitude} м',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                'Скорость: ${location.speed} м/с',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Text('Ошибка: $error'),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: ParaFlightApp(),
    ),
  );
}

class ParaFlightApp extends StatelessWidget {
  const ParaFlightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'ParaFlight',
      home: DashboardScreen(),
    );
  }
}

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';

@RoutePage()
class MmCalendarHomePage extends StatelessWidget {
  const MmCalendarHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MM Calendar'),
      ),
      body: const Center(
        child: Text('MM Calendar Home Page'),
      ),
    );
  }
}

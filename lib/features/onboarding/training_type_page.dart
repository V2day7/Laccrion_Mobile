import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TrainingTypePage extends StatefulWidget {
  const TrainingTypePage({super.key});

  @override
  State<TrainingTypePage> createState() => _TrainingTypePageState();
}

class _TrainingTypePageState extends State<TrainingTypePage> {
  String _selected = 'strength';

  Widget _card(String key, String title, IconData icon) {
    final selected = _selected == key;
    return GestureDetector(
      onTap: () => setState(() => _selected = key),
      child: Card(
        color: selected ? Colors.blue.shade50 : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: selected
              ? BorderSide(color: Colors.blue.shade200)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40),
              const SizedBox(height: 8),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Training Type')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Pick the training style that fits you',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _card('strength', 'Strength', Icons.fitness_center),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _card('cardio', 'Cardio', Icons.directions_run),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _card('hybrid', 'Hybrid', Icons.auto_awesome),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('This helps us suggest starter targets and plans.'),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => context.go('/onboarding/bmi'),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

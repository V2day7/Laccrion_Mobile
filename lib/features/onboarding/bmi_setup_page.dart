import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

double _calcBmi(double kg, double cm) {
  if (cm <= 0) return 0;
  final m = cm / 100.0;
  return kg / (m * m);
}

class BmiSetupPage extends StatefulWidget {
  const BmiSetupPage({super.key});

  @override
  State<BmiSetupPage> createState() => _BmiSetupPageState();
}

class _BmiSetupPageState extends State<BmiSetupPage> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  double get _bmi {
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final h = double.tryParse(_heightCtrl.text) ?? 0;
    return _calcBmi(w, h);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your BMI')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Enter your current height and weight',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _heightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('BMI'),
                      Text(_bmi.isNaN ? '—' : _bmi.toStringAsFixed(1)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        // Placeholder save: real save happens in Phase 2
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'BMI saved (placeholder). Proceeding...',
                            ),
                          ),
                        );
                        context.go('/home');
                      },
                      child: const Text('Save and Continue'),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'onboarding_controller.dart';

class BmiSetupPage extends ConsumerStatefulWidget {
  const BmiSetupPage({super.key});

  @override
  ConsumerState<BmiSetupPage> createState() => _BmiSetupPageState();
}

class _BmiSetupPageState extends ConsumerState<BmiSetupPage> {
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  double? _bmiPreview;

  void _recalc() {
    final h = double.tryParse(_heightCtrl.text.trim());
    final w = double.tryParse(_weightCtrl.text.trim());
    if (h == null || w == null || h <= 0 || w <= 0) {
      setState(() => _bmiPreview = null);
      return;
    }
    final hm = h / 100.0;
    setState(() => _bmiPreview = w / (hm * hm));
  }

  String _category(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Future<void> _finish() async {
    final h = double.tryParse(_heightCtrl.text.trim());
    final w = double.tryParse(_weightCtrl.text.trim());

    if (h == null || w == null || h <= 0 || w <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid height and weight.')),
      );
      return;
    }

    final ctrl = ref.read(onboardingControllerProvider.notifier);

    try {
      await ctrl.submitBmiAndGenerateTargets(heightCm: h, weightKg: w);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to finish onboarding: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(onboardingControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('BMI Setup')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 6),
              const Text(
                'Enter your height and weight',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _heightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                        ),
                        onChanged: (_) => _recalc(),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                        ),
                        onChanged: (_) => _recalc(),
                      ),
                      const SizedBox(height: 14),
                      if (_bmiPreview != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'BMI',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${_bmiPreview!.toStringAsFixed(1)} • ${_category(_bmiPreview!)}',
                            ),
                          ],
                        )
                      else
                        Text(
                          'BMI preview will appear here',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: st.loading ? null : _finish,
                  child: st.loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Finish'),
                ),
              ),
              const SizedBox(height: 10),
              if (st.error != null)
                Text(
                  st.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

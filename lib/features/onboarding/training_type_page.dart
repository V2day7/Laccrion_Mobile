import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'onboarding_controller.dart';

class TrainingTypePage extends ConsumerWidget {
  const TrainingTypePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);

    Future<void> onContinue() async {
      try {
        await ctrl.persistTrainingType();
        if (context.mounted) context.go('/onboarding/bmi');
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save training type: $e')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Training')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 6),
              const Text(
                'What training do you want to focus on?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              _OptionCard(
                title: 'Strength',
                subtitle: 'Weights • progressive overload',
                icon: Icons.fitness_center,
                selected: st.trainingType == 'strength',
                onTap: () => ctrl.setTrainingTypeLocal('strength'),
              ),
              const SizedBox(height: 10),
              _OptionCard(
                title: 'Cardio',
                subtitle: 'Endurance • conditioning',
                icon: Icons.directions_run,
                selected: st.trainingType == 'cardio',
                onTap: () => ctrl.setTrainingTypeLocal('cardio'),
              ),
              const SizedBox(height: 10),
              _OptionCard(
                title: 'Hybrid',
                subtitle: 'Strength + cardio mix',
                icon: Icons.bolt,
                selected: st.trainingType == 'hybrid',
                onTap: () => ctrl.setTrainingTypeLocal('hybrid'),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: st.loading ? null : onContinue,
                  child: st.loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
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

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? primary : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.08),
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: selected
            ? const Icon(Icons.check_circle)
            : const Icon(Icons.circle_outlined),
      ),
    );
  }
}

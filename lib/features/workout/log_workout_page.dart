import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/workout/workout_controller.dart';

class LogWorkoutPage extends ConsumerStatefulWidget {
  const LogWorkoutPage({super.key});

  @override
  ConsumerState<LogWorkoutPage> createState() => _LogWorkoutPageState();
}

class _LogWorkoutPageState extends ConsumerState<LogWorkoutPage> {
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutControllerProvider);
    final ctrl = ref.read(workoutControllerProvider.notifier);

    if (!_loaded) {
      _loaded = true;
      Future.microtask(() async {
        await ctrl.loadTodayFromWeeklyTargets();
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Today’s Workout')),
      body: SafeArea(
        child: state.loading && state.exercises.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HeaderCard(
                    onFinish: state.loading
                        ? null
                        : () async {
                            final workoutId = await ctrl.finishWorkoutAndSave();
                            if (!mounted) return;

                            if (workoutId == null) {
                              final err =
                                  ref.read(workoutControllerProvider).error ??
                                  'Save failed.';
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(err)));
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Workout saved! +25 XP'),
                              ),
                            );

                            // ✅ Router-safe: go back home
                            context.go('/home');
                          },
                    error: state.error,
                  ),
                  const SizedBox(height: 12),
                  if (state.exercises.isEmpty)
                    const _EmptyState()
                  else
                    ...List.generate(state.exercises.length, (i) {
                      final ex = state.exercises[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ExerciseCard(
                          index: i,
                          name: ex.name,
                          gifUrl: ex.gifUrl,
                          target:
                              '${ex.targetSets} × ${ex.targetReps} • ${ex.targetWeight.toStringAsFixed(0)} kg',
                          setsCount: ex.sets.length,
                          onAddSet: state.loading ? null : () => ctrl.addSet(i),
                          onRemoveSet: state.loading
                              ? null
                              : () => ctrl.removeLastSet(i),
                          setRows: List.generate(ex.sets.length, (s) {
                            final set = ex.sets[s];
                            return _SetRow(
                              setNumber: set.setNumber,
                              reps: set.reps,
                              weight: set.weight,
                              enabled: !state.loading,
                              onRepsChanged: (v) {
                                final parsed = int.tryParse(v) ?? 0;
                                ctrl.updateSetReps(i, s, parsed);
                              },
                              onWeightChanged: (v) {
                                final parsed = double.tryParse(v) ?? 0.0;
                                ctrl.updateSetWeight(i, s, parsed);
                              },
                            );
                          }),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.onFinish, required this.error});
  final VoidCallback? onFinish;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loaded from Weekly Targets (first 5)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Log your actual reps/weight then finish to save.',
              style: TextStyle(color: Colors.white.withOpacity(.8)),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onFinish,
                child: const Text('Finish & Save Workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'No weekly targets found for this week.\n\nGo to onboarding to generate them, then come back.',
          style: TextStyle(color: Colors.white.withOpacity(.85)),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.index,
    required this.name,
    required this.gifUrl,
    required this.target,
    required this.setRows,
    required this.setsCount,
    required this.onAddSet,
    required this.onRemoveSet,
  });

  final int index;
  final String name;
  final String? gifUrl;
  final String target;
  final List<Widget> setRows;
  final int setsCount;
  final VoidCallback? onAddSet;
  final VoidCallback? onRemoveSet;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _GifThumb(url: gifUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Target: $target',
                        style: TextStyle(color: Colors.white.withOpacity(.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...setRows,
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onRemoveSet,
                  icon: const Icon(Icons.remove),
                  label: const Text('Remove'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onAddSet,
                  icon: const Icon(Icons.add),
                  label: const Text('Add set'),
                ),
                const Spacer(),
                Text(
                  '$setsCount sets',
                  style: TextStyle(color: Colors.white.withOpacity(.7)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GifThumb extends StatelessWidget {
  const _GifThumb({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: 64,
        height: 64,
        color: Colors.white.withOpacity(.06),
        child: (url == null || url!.isEmpty)
            ? Icon(Icons.fitness_center, color: Colors.white.withOpacity(.75))
            : Image.network(
                url!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
                errorBuilder: (context, error, stack) {
                  debugPrint('GIF load failed: $url -> $error');
                  return Icon(
                    Icons.broken_image,
                    color: Colors.white.withOpacity(.75),
                  );
                },
              ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.enabled,
    required this.onRepsChanged,
    required this.onWeightChanged,
  });

  final int setNumber;
  final int reps;
  final double weight;
  final bool enabled;
  final ValueChanged<String> onRepsChanged;
  final ValueChanged<String> onWeightChanged;

  @override
  Widget build(BuildContext context) {
    final repsCtrl = TextEditingController(text: reps.toString());
    final weightCtrl = TextEditingController(text: weight.toStringAsFixed(0));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              'Set $setNumber',
              style: TextStyle(color: Colors.white.withOpacity(.85)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: repsCtrl,
              enabled: enabled,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
              onChanged: onRepsChanged,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: weightCtrl,
              enabled: enabled,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'kg'),
              onChanged: onWeightChanged,
            ),
          ),
        ],
      ),
    );
  }
}

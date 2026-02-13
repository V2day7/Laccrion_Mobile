import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/exercisedb_service.dart';

final workoutControllerProvider =
    StateNotifierProvider<WorkoutController, WorkoutState>((ref) {
      return WorkoutController(ref);
    });

final exerciseDbProvider = Provider<ExerciseDbService>(
  (ref) => ExerciseDbService(),
);

class WorkoutDraftSet {
  final int setNumber;
  final int reps;
  final double weight;

  WorkoutDraftSet({
    required this.setNumber,
    required this.reps,
    required this.weight,
  });

  WorkoutDraftSet copyWith({int? reps, double? weight}) => WorkoutDraftSet(
    setNumber: setNumber,
    reps: reps ?? this.reps,
    weight: weight ?? this.weight,
  );
}

class WorkoutDraftExercise {
  final String name;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final String? exerciseApiId;
  final String? gifUrl;
  final List<WorkoutDraftSet> sets;

  WorkoutDraftExercise({
    required this.name,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    required this.sets,
    this.exerciseApiId,
    this.gifUrl,
  });

  WorkoutDraftExercise copyWith({
    String? exerciseApiId,
    String? gifUrl,
    List<WorkoutDraftSet>? sets,
  }) {
    return WorkoutDraftExercise(
      name: name,
      targetSets: targetSets,
      targetReps: targetReps,
      targetWeight: targetWeight,
      sets: sets ?? this.sets,
      exerciseApiId: exerciseApiId ?? this.exerciseApiId,
      gifUrl: gifUrl ?? this.gifUrl,
    );
  }
}

class WorkoutState {
  final bool loading;
  final String? error;
  final List<WorkoutDraftExercise> exercises;

  const WorkoutState({
    required this.loading,
    required this.exercises,
    this.error,
  });

  factory WorkoutState.initial() =>
      const WorkoutState(loading: false, exercises: []);

  WorkoutState copyWith({
    bool? loading,
    String? error,
    List<WorkoutDraftExercise>? exercises,
  }) {
    return WorkoutState(
      loading: loading ?? this.loading,
      error: error,
      exercises: exercises ?? this.exercises,
    );
  }
}

class WorkoutController extends StateNotifier<WorkoutState> {
  WorkoutController(this.ref) : super(WorkoutState.initial());
  final Ref ref;

  DateTime _weekStartMonday(DateTime now) {
    final d = DateTime(now.year, now.month, now.day);
    final diff = d.weekday - DateTime.monday;
    return d.subtract(Duration(days: diff));
  }

  String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> loadTodayFromWeeklyTargets() async {
    state = state.copyWith(loading: true, error: null);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      final weekStart = _weekStartMonday(DateTime.now());
      final weekStartStr = _dateOnly(weekStart);

      final targets = await client
          .from('training_targets')
          .select()
          .eq('user_id', user.id)
          .eq('week_start', weekStartStr)
          .order('created_at', ascending: true);

      final list = (targets as List)
          .cast<Map<String, dynamic>>()
          .take(5)
          .toList();

      var draft = list.map((t) {
        final name = (t['exercise_name'] ?? '').toString();
        final ts = (t['target_sets'] as num?)?.toInt() ?? 3;
        final tr = (t['target_reps'] as num?)?.toInt() ?? 10;
        final tw = (t['target_weight'] as num?)?.toDouble() ?? 0.0;

        final sets = List.generate(
          ts,
          (i) => WorkoutDraftSet(setNumber: i + 1, reps: tr, weight: tw),
        );

        return WorkoutDraftExercise(
          name: name,
          targetSets: ts,
          targetReps: tr,
          targetWeight: tw,
          sets: sets,
        );
      }).toList();

      final api = ref.read(exerciseDbProvider);

      for (var i = 0; i < draft.length; i++) {
        final ex = draft[i];

        final match = await api.searchBestMatchByName(ex.name);

        if (match != null && match.gifUrl != null && match.gifUrl!.isNotEmpty) {
          draft[i] = ex.copyWith(exerciseApiId: match.id, gifUrl: match.gifUrl);

          print("Matched GIF for ${ex.name}: ${match.gifUrl}");
        } else {
          print("No GIF match for ${ex.name}");
        }
      }

      state = state.copyWith(loading: false, exercises: draft);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void updateSetReps(int exerciseIndex, int setIndex, int reps) {
    final ex = state.exercises[exerciseIndex];
    final newSets = [...ex.sets];
    newSets[setIndex] = newSets[setIndex].copyWith(reps: reps);
    final newExercises = [...state.exercises];
    newExercises[exerciseIndex] = ex.copyWith(sets: newSets);
    state = state.copyWith(exercises: newExercises);
  }

  void updateSetWeight(int exerciseIndex, int setIndex, double weight) {
    final ex = state.exercises[exerciseIndex];
    final newSets = [...ex.sets];
    newSets[setIndex] = newSets[setIndex].copyWith(weight: weight);
    final newExercises = [...state.exercises];
    newExercises[exerciseIndex] = ex.copyWith(sets: newSets);
    state = state.copyWith(exercises: newExercises);
  }

  void addSet(int exerciseIndex) {
    final ex = state.exercises[exerciseIndex];
    final next = ex.sets.length + 1;
    final newSets = [
      ...ex.sets,
      WorkoutDraftSet(
        setNumber: next,
        reps: ex.targetReps,
        weight: ex.targetWeight,
      ),
    ];
    final newExercises = [...state.exercises];
    newExercises[exerciseIndex] = ex.copyWith(sets: newSets);
    state = state.copyWith(exercises: newExercises);
  }

  void removeLastSet(int exerciseIndex) {
    final ex = state.exercises[exerciseIndex];
    if (ex.sets.length <= 1) return;
    final newSets = [...ex.sets]..removeLast();
    final newExercises = [...state.exercises];
    newExercises[exerciseIndex] = ex.copyWith(sets: newSets);
    state = state.copyWith(exercises: newExercises);
  }

  int _levelFromXp(int xp) {
    if (xp < 100) return 1;
    if (xp < 250) return 2;
    if (xp < 500) return 3;
    if (xp < 1000) return 4;
    return 5;
  }

  Future<int?> finishWorkoutAndSave() async {
    state = state.copyWith(loading: true, error: null);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      // 1) workouts
      final workoutRow = await client
          .from('workouts')
          .insert({
            'user_id': user.id,
            'workout_date': _dateOnly(DateTime.now()),
            'workout_name': 'Today’s Workout',
            'notes': null,
          })
          .select('id')
          .single();

      final workoutId = (workoutRow['id'] as num).toInt();

      // 2) workout_exercises
      final exRows = List.generate(state.exercises.length, (i) {
        final ex = state.exercises[i];
        return {
          'workout_id': workoutId,
          'exercise_name': ex.name,
          'exercise_api_id': ex.exerciseApiId,
          'gif_url': ex.gifUrl,
          'order_index': i,
        };
      });

      final insertedExercises = await client
          .from('workout_exercises')
          .insert(exRows)
          .select('id, order_index');

      final inserted = (insertedExercises as List).cast<Map<String, dynamic>>();

      // sort by order_index so we match the draft
      inserted.sort(
        (a, b) => (a['order_index'] as num).toInt().compareTo(
          (b['order_index'] as num).toInt(),
        ),
      );

      // 3) workout_sets
      final setsToInsert = <Map<String, dynamic>>[];
      for (var i = 0; i < state.exercises.length; i++) {
        final exId = (inserted[i]['id'] as num).toInt();
        for (final s in state.exercises[i].sets) {
          setsToInsert.add({
            'exercise_id': exId,
            'set_number': s.setNumber,
            'reps': s.reps,
            'weight': s.weight,
          });
        }
      }

      if (setsToInsert.isNotEmpty) {
        await client.from('workout_sets').insert(setsToInsert);
      }

      // 4) Update XP/Level
      final prof = await client
          .from('profiles')
          .select('xp')
          .eq('id', user.id)
          .single();
      final currentXp = (prof['xp'] as num?)?.toInt() ?? 0;
      final newXp = currentXp + 25;
      final newLevel = _levelFromXp(newXp);

      await client
          .from('profiles')
          .update({'xp': newXp, 'level': newLevel})
          .eq('id', user.id);

      state = state.copyWith(loading: false);
      return workoutId;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return null;
    }
  }
}

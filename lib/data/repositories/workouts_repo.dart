import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class WorkoutsRepo {
  SupabaseClient get _db => SupabaseService.client;

  Future<int> createWorkout({
    required String userId,
    required DateTime date,
    required String workoutName,
    String? notes,
  }) async {
    final inserted = await _db
        .from('workouts')
        .insert({
          'user_id': userId,
          'workout_date': date.toIso8601String().substring(0, 10),
          'workout_name': workoutName,
          'notes': notes,
        })
        .select('id')
        .single();

    return (inserted['id'] as num).toInt();
  }

  Future<List<Map<String, dynamic>>> addWorkoutExercises({
    required int workoutId,
    required List<Map<String, dynamic>> exercises,
  }) async {
    // exercises expects rows with:
    // workout_id, exercise_name, exercise_api_id?, gif_url?, order_index
    final rows = exercises.map((e) => {...e, 'workout_id': workoutId}).toList();

    final inserted = await _db
        .from('workout_exercises')
        .insert(rows)
        .select('id, exercise_name, exercise_api_id, gif_url, order_index');

    return (inserted as List).cast<Map<String, dynamic>>();
  }

  Future<void> addWorkoutSets({
    required List<Map<String, dynamic>> sets,
  }) async {
    // sets expects rows with:
    // exercise_id, set_number, reps, weight
    if (sets.isEmpty) return;
    await _db.from('workout_sets').insert(sets);
  }

  Future<List<Map<String, dynamic>>> listWorkoutsForUser(String userId) async {
    final res = await _db
        .from('workouts')
        .select('id, workout_date, workout_name, notes, created_at')
        .eq('user_id', userId)
        .order('workout_date', ascending: false);

    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getWorkoutDetail(int workoutId) async {
    // 1) workout
    final workout = await _db
        .from('workouts')
        .select('id, user_id, workout_date, workout_name, notes, created_at')
        .eq('id', workoutId)
        .single();

    // 2) exercises
    final exercises = await _db
        .from('workout_exercises')
        .select(
          'id, workout_id, exercise_name, exercise_api_id, gif_url, order_index, created_at',
        )
        .eq('workout_id', workoutId)
        .order('order_index', ascending: true);

    final exerciseList = (exercises as List).cast<Map<String, dynamic>>();

    // 3) sets
    final exerciseIds = exerciseList.map((e) => e['id']).toList();
    List<Map<String, dynamic>> sets = [];
    if (exerciseIds.isNotEmpty) {
      final resSets = await _db
          .from('workout_sets')
          .select('id, exercise_id, set_number, reps, weight, created_at')
          .inFilter('exercise_id', exerciseIds)
          .order('set_number', ascending: true);

      sets = (resSets as List).cast<Map<String, dynamic>>();
    }

    return {'workout': workout, 'exercises': exerciseList, 'sets': sets};
  }
}

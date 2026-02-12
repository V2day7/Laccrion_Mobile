import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class TrainingTargetsRepo {
  SupabaseClient get _client => SupabaseService.client;

  Future<void> replaceWeekTargets({
    required String userId,
    required DateTime weekStart,
    required List<Map<String, dynamic>> targets,
  }) async {
    final weekStartStr = _toDateOnly(weekStart);

    // Delete existing targets for that week
    await _client
        .from('training_targets')
        .delete()
        .eq('user_id', userId)
        .eq('week_start', weekStartStr);

    if (targets.isEmpty) return;

    // Insert new targets
    final rows = targets
        .map((t) => {...t, 'user_id': userId, 'week_start': weekStartStr})
        .toList();

    await _client.from('training_targets').insert(rows);
  }

  String _toDateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

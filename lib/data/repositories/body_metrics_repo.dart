import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class BodyMetricsRepo {
  SupabaseClient get _client => SupabaseService.client;

  /// Upsert by (user_id, week_start) unique constraint
  Future<void> upsertWeeklyMetrics({
    required String userId,
    required DateTime weekStart,
    required double weightKg,
    required double heightCm,
    required double bmi,
  }) async {
    final weekStartStr = _toDateOnly(weekStart);

    await _client.from('body_metrics').upsert({
      'user_id': userId,
      'week_start': weekStartStr,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'bmi': bmi,
    }, onConflict: 'user_id,week_start');
  }

  String _toDateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

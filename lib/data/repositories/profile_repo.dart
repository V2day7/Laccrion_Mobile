import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class ProfileRepo {
  SupabaseClient get _client => SupabaseService.client;

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    return await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  Future<void> updateTrainingType({
    required String userId,
    required String trainingType,
  }) async {
    await _client
        .from('profiles')
        .update({
          'training_type': trainingType,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  Future<void> updateHeightCm({
    required String userId,
    required double heightCm,
  }) async {
    await _client
        .from('profiles')
        .update({
          'height_cm': heightCm,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  Future<void> setOnboardingDone({
    required String userId,
    required bool done,
  }) async {
    await _client
        .from('profiles')
        .update({
          'onboarding_done': done,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  Future<AuthResponse> signUpWithEmail(String email, String password) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signInWithEmail(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return res;
  }

  /// Create profile ONLY if it doesn't exist (prevents XP/level reset).
  Future<void> ensureProfileExists(String userId) async {
    final existing = await fetchProfile(userId);
    if (existing != null) return;

    // Insert defaults only once.
    // If two calls race, one may fail with duplicate key — that's okay.
    try {
      await _client.from('profiles').insert({
        'id': userId,
        'training_type': 'strength',
        'onboarding_done': false,
        'xp': 0,
        'level': 1,
      });
    } catch (_) {
      // Ignore duplicate insert errors if it was created by another call.
    }
  }
}

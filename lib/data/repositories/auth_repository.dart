import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  // ---- AUTH ----
  Future<AuthResponse> signUpWithEmail(String email, String password) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signInWithEmail(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  // ---- PROFILE ----
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return res;
  }

  Future<void> ensureProfileExists(String userId) async {
    // MUST be called only when authenticated (auth.uid() exists),
    // because RLS requires id = auth.uid().
    await _client.from('profiles').upsert({
      'id': userId,
      'training_type': 'strength',
      'onboarding_done': false,
      'xp': 0,
      'level': 1,
    });
  }
}

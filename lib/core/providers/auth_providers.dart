import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/supabase_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthState {
  final User? user;
  final Map<String, dynamic>? profile;
  AuthState({this.user, this.profile});
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  AuthController(this._repo) : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      final profile = await _repo.fetchProfile(user.id);
      state = AuthState(user: user, profile: profile);
    } else {
      state = AuthState(user: null, profile: null);
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final res = await _repo.signInWithEmail(email, password);
      final user = res.user;
      if (user == null) return 'invalid_login';

      await _repo.ensureProfileExists(user.id);

      await refreshProfile();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp(String email, String password) async {
    try {
      final res = await _repo.signUpWithEmail(email, password);

      // If confirm email is ON, session can be null
      if (res.session == null) {
        return 'confirm_email';
      }

      final user = res.user;
      if (user == null) return 'no_user';

      // Ensure profile exists AFTER we have a session
      await _repo.ensureProfileExists(user.id);

      await refreshProfile();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = AuthState(user: null, profile: null);
  }

  Future<void> refreshProfile() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      final profile = await _repo.fetchProfile(user.id);
      state = AuthState(user: user, profile: profile);
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final repo = ref.read(authRepositoryProvider);
    return AuthController(repo);
  },
);

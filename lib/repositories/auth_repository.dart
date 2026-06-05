import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Signs up a new user and sets their display name in the profiles table.
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final userId = response.user?.id;
    if (userId != null) {
      await _supabase
          .from('profiles')
          .update({'display_name': displayName})
          .eq('id', userId);
    }
  }

  /// Signs in an existing user with email and password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Returns the currently authenticated user, or null if not signed in.
  User? get currentUser => _supabase.auth.currentUser;

  /// Emits an [AuthState] event whenever authentication state changes.
  Stream<AuthState> get authStateStream => _supabase.auth.onAuthStateChange;
}

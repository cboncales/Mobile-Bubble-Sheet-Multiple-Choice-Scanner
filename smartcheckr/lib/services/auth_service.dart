import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class AuthService {
  // Get current user
  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  // Check if user is authenticated
  bool get isAuthenticated => getCurrentUser() != null;

  // Sign in with email and password
  Future<User> signIn(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Login failed');
      }
      
      return response.user!;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Sign up with email, password, and display name
  Future<User> signUp(String email, String password, String displayName) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
          'role': 'instructor', // Set role for instructors
        },
      );
      
      if (response.user == null) {
        throw Exception('Registration failed');
      }
      
      return response.user!;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  // Get user display name
  String? getUserDisplayName() {
    final user = getCurrentUser();
    if (user?.userMetadata?['display_name'] != null) {
      return user!.userMetadata!['display_name'] as String;
    }
    return user?.email?.split('@').first; // Fallback to email prefix
  }

  // Get user email
  String? getUserEmail() {
    return getCurrentUser()?.email;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
} 
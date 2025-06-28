import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../shared/data/models/profile_model.dart';
import '../../../../core/config/supabase_config.dart';

abstract class AuthDataSource {
  Future<ProfileModel?> signInWithGoogle();
  Future<ProfileModel?> signInWithApple();
  Future<void> signOut();
  Future<ProfileModel?> getCurrentUser();
  Stream<AuthState> get authStateChanges;
}

class SupabaseAuthDataSource implements AuthDataSource {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  SupabaseAuthDataSource({
    required SupabaseClient supabase,
    required GoogleSignIn googleSignIn,
  })  : _supabase = supabase,
        _googleSignIn = googleSignIn;

  @override
  Future<ProfileModel?> signInWithGoogle() async {
    try {
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Sign in with Supabase using Google credentials
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user != null) {
        return await _getProfile(response.user!.id);
      }
      
      return null;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  @override
  Future<ProfileModel?> signInWithApple() async {
    try {
      // Sign in with Apple
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'your.app.bundle.id',
          redirectUri: Uri.parse(SupabaseConfig.authRedirectUrl),
        ),
      );

      // Sign in with Supabase using Apple credentials
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
      );

      if (response.user != null) {
        return await _getProfile(response.user!.id);
      }
      
      return null;
    } catch (e) {
      print('Error signing in with Apple: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  @override
  Future<ProfileModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        return await _getProfile(user.id);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  @override
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<ProfileModel?> _getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return ProfileModel.fromJson(response);
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }
}
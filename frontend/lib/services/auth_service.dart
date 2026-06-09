import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Mevcut kullanıcı
  User? get currentUser => _supabase.auth.currentUser;

  // Oturum durumu stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Email + Şifre ile kayıt
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'full_name': '$firstName $lastName',
      },
    );

    return response;
  }

  // Email + Şifre ile giriş
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Google ile giriş
  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      queryParams: {'prompt': 'consent'},
    );
  }

  // Çıkış
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Profil bilgilerini getir
  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return response;
    } catch (_) {
      return null;
    }
  }
}

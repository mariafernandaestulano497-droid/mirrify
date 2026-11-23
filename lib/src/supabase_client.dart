import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Variável para modo de administração na demonstração/uso
  static bool isAdminMode = false;

  // Auth ---------------------------------------------------------------
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String preferredStyle,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'nome': name,
        'estilo_preferido': preferredStyle,
        'tipo_usuario': 'usuario',
      },
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> resetPassword({
    required String email,
  }) async {
    await client.auth.resetPasswordForEmail(email);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => client.auth.currentUser;

  static String? get userPreferredStyle {
    final meta = currentUser?.userMetadata;
    return meta?['estilo_preferido'] as String? ?? 'Maquiagem Natural';
  }
}

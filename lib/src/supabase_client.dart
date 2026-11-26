import 'package:flutter/material.dart';
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

  // Adicionado para buscar o tipo de usuário na tabela profiles
  static Future<String?> getUserRole() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      // Busca na tabela 'profiles' a coluna 'tipo_usuario' usando o ID do usuário logado
      final response = await client
          .from('profiles')
          .select('tipo_usuario')
          .eq('id', user.id) // Certifique-se de que na tabela a coluna de ID se chama 'id'
          .maybeSingle(); // Use maybeSingle() para evitar erro caso o perfil não exista

      if (response == null) return null;
      
      return response['tipo_usuario'] as String?;
    } catch (e) {
      debugPrint('Erro ao buscar role: $e');
      return null;
    }
  }

  static User? get currentUser => client.auth.currentUser;

  static String? get userPreferredStyle {
    final meta = currentUser?.userMetadata;
    return meta?['estilo_preferido'] as String? ?? 'Maquiagem Natural';
  }
}
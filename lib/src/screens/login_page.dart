import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../supabase_client.dart';
import '../utils/validators.dart';
import '../widgets/mirrify_logo.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';
import 'simulator_page.dart';
import 'admin_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _navigateToSimulator() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, anim, __) => const SimulatorPage(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // --- NOVO MÉTODO PARA PÁGINA DE ADMIN ---
  void _navigateToAdminPage() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        // Substitua pela sua página de Admin real
        pageBuilder: (_, anim, __) => const AdminPage(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });

    try {
      // 1. Faz o login
      await SupabaseService.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      
      if (!mounted) return;

      // 2. Verifica o tipo de usuário (Role)
      final tipoUsuario = await SupabaseService.getUserRole();

      if (!mounted) return;

      // 3. Redireciona baseado no tipo de usuário
      if (tipoUsuario == 'administrador') {
        _navigateToAdminPage();
      } else {
        // Se for 'usuario' ou null (caso não tenha perfil ainda), vai pro simulador
        _navigateToSimulator(); 
      }

    } on AuthException catch (error) {
      if (!mounted) return;
      final message = error.message.toLowerCase().contains('email not confirmed')
          ? 'Confirme seu e-mail antes de entrar. Verifique sua caixa de spam.'
          : (error.message.toLowerCase().contains('invalid login credentials')
              ? 'E-mail ou senha incorretos. Verifique suas credenciais e tente novamente.'
              : error.message);
      setState(() { _errorMsg = message; _loading = false; });
    } catch (e) { // Mudei o catch para mostrar o erro real se falhar a busca no banco
      if (!mounted) return;
      setState(() { 
        _errorMsg = 'Erro ao fazer login ou buscar perfil. Detalhes: $e'; 
        _loading = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MirrifyBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth > 440 ? 400.0 : constraints.maxWidth;
                return SizedBox(
                  width: cardWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MirrifyBrandHeader(
                        starSize: 48,
                        titleSize: 26,
                        showSubtitle: true,
                      ),
                      const SizedBox(height: 26),

                      // Card de Login
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.93),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7897E4).withOpacity(0.18),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: const Color(0xFFA688F1).withOpacity(0.12),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Entrar na sua conta',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2C2448),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Espelho Inteligente • Lumière Cosméticos',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppPalette.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // E-mail
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14.5, color: const Color(0xFF2C2448)),
                                  decoration: InputDecoration(
                                    labelText: 'E-mail',
                                    hintText: 'seu@email.com',
                                    prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppPalette.periwinkle, size: 20),
                                  ),
                                  validator: Validators.email,
                                ),
                                const SizedBox(height: 16),

                                // Senha
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscurePassword,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14.5, color: const Color(0xFF2C2448)),
                                  decoration: InputDecoration(
                                    labelText: 'Senha',
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppPalette.violet, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: AppPalette.textMuted,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: Validators.password,
                                ),

                                // Esqueci a senha
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                                    ),
                                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                                    child: Text(
                                      'Esqueceu a senha?',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppPalette.secondary,
                                      ),
                                    ),
                                  ),
                                ),

                                // Erro
                                if (_errorMsg != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFECEC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFFCDD2)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline_rounded, color: Color(0xFFD32F2F), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMsg!,
                                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFFC62828)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                // Botão Entrar
                                Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: AppPalette.brandGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppPalette.violet.withOpacity(0.4),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Entrar no Espelho',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Link Cadastro
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Não tem uma conta?',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: const Color(0xFF4C3E75)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SignupPage()),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Cadastre-se',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppPalette.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
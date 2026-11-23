import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../supabase_client.dart';
import '../utils/validators.dart';
import '../widgets/mirrify_logo.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Campo extra obrigatório pelo briefing da Fábrica do Futuro / Lumière: Estilo Preferido
  String _preferredStyle = 'Maquiagem Natural';
  final List<String> _styleOptions = [
    'Maquiagem Natural',
    'Glamour & Festa',
    'Cabelo Iluminado',
    'Cachos & Volume',
    'Cortes Modernos',
    'Vibrante & Ousado',
  ];

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await SupabaseService.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        name: _nameCtrl.text.trim(),
        preferredStyle: _preferredStyle,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppPalette.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text(
            'Cadastro realizado com sucesso! Verifique seu e-mail.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMsg = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Erro inesperado ao realizar cadastro.';
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth > 460 ? 430.0 : constraints.maxWidth;

                return SizedBox(
                  width: cardWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header com botão voltar
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFF382A6A),
                                size: 22,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const Spacer(),
                          const MirrifySparkle(
                            size: 32,
                            color: AppPalette.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'MIRRIFY',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 4.0,
                              color: const Color(0xFF382A6A),
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Card
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
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 30,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Crie sua conta',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2C2448),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Preencha seus dados e escolha seu estilo preferido',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    color: AppPalette.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Nome completo
                                TextFormField(
                                  controller: _nameCtrl,
                                  textCapitalization: TextCapitalization.words,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    color: const Color(0xFF2C2448),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Nome completo',
                                    hintText: 'Seu nome e sobrenome',
                                    prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      color: AppPalette.periwinkle,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Informe seu nome';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // E-mail
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    color: const Color(0xFF2C2448),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'E-mail',
                                    hintText: 'seu@email.com',
                                    prefixIcon: const Icon(
                                      Icons.alternate_email_rounded,
                                      color: AppPalette.periwinkle,
                                      size: 20,
                                    ),
                                  ),
                                  validator: Validators.email,
                                ),
                                const SizedBox(height: 16),

                                // CAMPO EXTRA: Estilo Preferido (Dropdown estilizado)
                                DropdownButtonFormField<String>(
                                  value: _preferredStyle,
                                  isExpanded: true,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    color: const Color(0xFF2C2448),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Estilo Preferido',
                                    prefixIcon: const Icon(
                                      Icons.auto_awesome_rounded,
                                      color: AppPalette.violet,
                                      size: 20,
                                    ),
                                    fillColor: Colors.white,
                                  ),
                                  dropdownColor: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  items: _styleOptions.map((style) {
                                    return DropdownMenuItem<String>(
                                      value: style,
                                      child: Text(
                                        style,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFF2C2448),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _preferredStyle = value);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Senha
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscurePassword,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    color: const Color(0xFF2C2448),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Senha',
                                    hintText: 'Mínimo 6 caracteres',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: AppPalette.violet,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: AppPalette.textMuted,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: Validators.password,
                                ),
                                const SizedBox(height: 16),

                                // Confirmar Senha
                                TextFormField(
                                  controller: _confirmCtrl,
                                  obscureText: _obscureConfirm,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    color: const Color(0xFF2C2448),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Confirmar senha',
                                    hintText: 'Repita a senha',
                                    prefixIcon: const Icon(
                                      Icons.shield_outlined,
                                      color: AppPalette.violet,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: AppPalette.textMuted,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirm = !_obscureConfirm;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Confirme sua senha';
                                    }
                                    if (value != _passwordCtrl.text) {
                                      return 'Senhas não coincidem';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                if (_errorMsg != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFECEC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFFCDD2)),
                                    ),
                                    child: Text(
                                      _errorMsg!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        color: const Color(0xFFC62828),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // Botão Cadastrar
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
                                    onPressed: _loading ? null : _signup,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Concluir cadastro',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.check_circle_outline_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
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

                      // Botão já tem conta
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Já possui cadastro?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                color: const Color(0xFF4C3E75),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Fazer login',
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

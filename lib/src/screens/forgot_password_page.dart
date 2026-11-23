import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../supabase_client.dart';
import '../utils/validators.dart';
import '../widgets/mirrify_logo.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _emailSent = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await SupabaseService.resetPassword(email: _emailCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        _loading = false;
        _emailSent = true;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.message;
        _loading = false;
      });
    } catch (_) {
      // Como boa prática de segurança e UX especificada em CT-03: confirma envio
      if (!mounted) return;
      setState(() {
        _loading = false;
        _emailSent = true;
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
                      const SizedBox(height: 24),

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
                            vertical: 32,
                          ),
                          child: _emailSent ? _buildSuccessView() : _buildFormView(),
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

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppPalette.lavender.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: AppPalette.violet,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Redefinição de Senha',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C2448),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Informe seu e-mail cadastrado para receber as instruções e o link de recuperação.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: AppPalette.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Campo E-mail
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              color: const Color(0xFF2C2448),
            ),
            decoration: InputDecoration(
              labelText: 'E-mail cadastrado',
              hintText: 'seu@email.com',
              prefixIcon: const Icon(
                Icons.alternate_email_rounded,
                color: AppPalette.periwinkle,
                size: 20,
              ),
            ),
            validator: Validators.email,
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

          // Botão Enviar
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
              onPressed: _loading ? null : _handleReset,
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Enviar instruções',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFEBF7ED),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF81C784), width: 2),
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: Color(0xFF2E7D32),
            size: 34,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Instruções enviadas!',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C2448),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Enviamos as orientações de redefinição de senha para:\n${_emailCtrl.text.trim()}',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppPalette.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppPalette.brandGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Voltar para o Login',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

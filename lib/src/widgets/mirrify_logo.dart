import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// Ícone estilizado da estrela de 4 pontas (Four-pointed Star / Sparkle) do Mirrify
class MirrifySparkle extends StatelessWidget {
  final double size;
  final Color? color;

  const MirrifySparkle({
    Key? key,
    this.size = 56,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SparklePainter(
          color: color ?? AppPalette.secondary,
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;

  _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // Curvatura orgânica da estrela de 4 pontas como no design do Mirrify
    final path = Path();
    path.moveTo(cx, 0); // Topo
    path.quadraticBezierTo(cx, cy * 0.72, w, cy); // Para a direita
    path.quadraticBezierTo(cx * 1.28, cy, cx, h); // Para o fundo
    path.quadraticBezierTo(cx, cy * 1.28, 0, cy); // Para a esquerda
    path.quadraticBezierTo(cx * 0.72, cy, cx, 0); // Volta ao topo
    path.close();

    // Sombra suave / brilho
    final shadowPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, shadowPaint);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Logo completo do Mirrify com Tipografia idêntica à imagem
class MirrifyBrandHeader extends StatelessWidget {
  final double starSize;
  final double titleSize;
  final bool showSubtitle;

  const MirrifyBrandHeader({
    Key? key,
    this.starSize = 54,
    this.titleSize = 28,
    this.showSubtitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MirrifySparkle(
          size: starSize,
          color: AppPalette.secondary,
        ),
        SizedBox(height: starSize * 0.35),
        Text(
          'MIRRIFY',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: titleSize,
            fontWeight: FontWeight.w500,
            letterSpacing: 8.0,
            color: const Color(0xFF382A6A),
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 10),
          Text(
            'YOUR REFLECTION, REIMAGINED.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.8,
              color: const Color(0xFF4C3E75),
            ),
          ),
        ],
      ],
    );
  }
}

/// Fundo fluido decorativo com ondas e cores suaves [#ebf7ed], [#CDB7ED], [#7897E4], [#A688F1]
class MirrifyBackground extends StatelessWidget {
  final Widget child;

  const MirrifyBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base de gradiente pastel
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEBF7ED), // mint claro
                Color(0xFFECE7FA), // suave
                Color(0xFFE2DBF7), // lavanda clara
                Color(0xFFD6C8F4), // lavanda
              ],
              stops: [0.0, 0.35, 0.7, 1.0],
            ),
          ),
        ),
        // Ondas fluidas decorativas como na imagem
        Positioned.fill(
          child: CustomPaint(
            painter: _MirrifyWavesPainter(),
          ),
        ),
        // Conteúdo
        SafeArea(child: child),
      ],
    );
  }
}

class _MirrifyWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Onda superior/lateral direita translúcida
    final topWavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.white.withOpacity(0.45),
          const Color(0xFFCDB7ED).withOpacity(0.2),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final topPath = Path();
    topPath.moveTo(w * 0.35, 0);
    topPath.quadraticBezierTo(w * 0.85, h * 0.22, w, h * 0.42);
    topPath.lineTo(w, 0);
    topPath.close();
    canvas.drawPath(topPath, topPathWave(w, h, topWavePaint));

    // Onda inferior esquerda (lilás vibrante suave)
    final bottomPath1 = Path();
    bottomPath1.moveTo(0, h * 0.62);
    bottomPath1.quadraticBezierTo(w * 0.4, h * 0.82, w, h * 0.78);
    bottomPath1.lineTo(w, h);
    bottomPath1.lineTo(0, h);
    bottomPath1.close();

    final bottomPaint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          const Color(0xFFA688F1).withOpacity(0.38),
          const Color(0xFF7897E4).withOpacity(0.25),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.6, w, h * 0.4));
    canvas.drawPath(bottomPath1, bottomPaint1);

    // Onda inferior profunda azul/lavanda
    final bottomPath2 = Path();
    bottomPath2.moveTo(0, h * 0.75);
    bottomPath2.quadraticBezierTo(w * 0.48, h * 0.94, w, h * 0.88);
    bottomPath2.lineTo(w, h);
    bottomPath2.lineTo(0, h);
    bottomPath2.close();

    final bottomPaint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFCDB7ED).withOpacity(0.55),
          const Color(0xFF7897E4).withOpacity(0.65),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.75, w, h * 0.25));
    canvas.drawPath(bottomPath2, bottomPaint2);
  }

  Paint topPathWave(double w, double h, Paint p) => p;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

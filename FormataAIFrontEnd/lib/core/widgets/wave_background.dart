import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Fundo decorativo com ondas geométricas — dá identidade visual ao app.
/// Posiciona ondas no topo e embaixo como conectores visuais.
class WaveBackground extends StatelessWidget {
  final Widget child;

  const WaveBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Container(
      color: bg,
      child: Stack(
        children: [
          // Onda superior — cobre todo o header até abaixo do stats card
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: CustomPaint(painter: _TopWavePainter(isDark: isDark)),
          ),
          // Onda inferior — fixa no fundo da tela
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 140,
            child: CustomPaint(painter: _BottomWavePainter(isDark: isDark)),
          ),
          // Conteúdo
          child,
        ],
      ),
    );
  }
}

class _TopWavePainter extends CustomPainter {
  final bool isDark;
  _TopWavePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final color1 = isDark
        ? AppColors.waveDark.withValues(alpha: 0.55)
        : AppColors.waveLight.withValues(alpha: 0.45);
    final color2 = isDark
        ? AppColors.accent.withValues(alpha: 0.07)
        : AppColors.accent.withValues(alpha: 0.05);

    // Primeira camada — onda suave e larga
    final p1 = Paint()
      ..color = color1
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height * 0.65)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.9,
        size.width * 0.5,
        size.height * 0.5,
        size.width * 0.75,
        size.height * 0.72,
      )
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.82,
        size.width * 0.95,
        size.height * 0.55,
        size.width,
        size.height * 0.6,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path1, p1);

    // Segunda camada (mais sutil, mais alta)
    final p2 = Paint()
      ..color = color2
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height * 0.45)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.7,
        size.width * 0.65,
        size.height * 0.2,
        size.width,
        size.height * 0.5,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path2, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomWavePainter extends CustomPainter {
  final bool isDark;
  _BottomWavePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final color = isDark
        ? AppColors.waveDark.withValues(alpha: 0.4)
        : AppColors.waveLight.withValues(alpha: 0.35);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Onda simples que sobe do rodapé — só na parte baixa
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.45)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.15,
        size.width * 0.6,
        size.height * 0.65,
        size.width,
        size.height * 0.3,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

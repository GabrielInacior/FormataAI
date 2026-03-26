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
          // Onda superior
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            height: 220,
            child: CustomPaint(painter: _TopWavePainter(isDark: isDark)),
          ),
          // Onda inferior
          Positioned(
            bottom: -20,
            left: 0,
            right: 0,
            height: 160,
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
        ? AppColors.waveDark.withValues(alpha: 0.6)
        : AppColors.waveLight.withValues(alpha: 0.5);
    final color2 = isDark
        ? AppColors.accent.withValues(alpha: 0.08)
        : AppColors.accent.withValues(alpha: 0.06);

    // Primeira camada
    final p1 = Paint()
      ..color = color1
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height * 0.55)
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.85,
        size.width * 0.45,
        size.height * 0.3,
        size.width * 0.7,
        size.height * 0.6,
      )
      ..cubicTo(
        size.width * 0.85,
        size.height * 0.75,
        size.width * 0.95,
        size.height * 0.35,
        size.width,
        size.height * 0.45,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path1, p1);

    // Segunda camada (mais sutil)
    final p2 = Paint()
      ..color = color2
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height * 0.35)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.65,
        size.width * 0.6,
        size.height * 0.15,
        size.width,
        size.height * 0.4,
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
        ? AppColors.waveDark.withValues(alpha: 0.5)
        : AppColors.waveLight.withValues(alpha: 0.4);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.4)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.1,
        size.width * 0.5,
        size.height * 0.7,
        size.width * 0.75,
        size.height * 0.3,
      )
      ..cubicTo(
        size.width * 0.9,
        size.height * 0.1,
        size.width,
        size.height * 0.5,
        size.width,
        size.height * 0.35,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Container neumórfico reutilizável — base de todos os elementos visuais.
/// `isPressed` cria o efeito "afundado". Suporta profundidade 3D variável.
class NeuContainer extends StatelessWidget {
  const NeuContainer({
    super.key,
    required this.child,
    this.isPressed = false,
    this.borderRadius = 20,
    this.padding,
    this.width,
    this.height,
    this.margin,
    this.depth = 1.0,
  });

  final Widget child;
  final bool isPressed;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final double depth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final shadowDark = isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;
    final shadowLight = isDark
        ? AppColors.darkShadowLight
        : AppColors.lightShadowLight;

    final d = depth.clamp(0.0, 2.0);
    final blurPressed = 6.0 * d;
    final offsetPressed = 2.0 * d;
    final blurNormal = 18.0 * d;
    final offsetNormal = 8.0 * d;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: isDark
            ? Border.all(
                color: AppColors.darkShadowLight.withValues(alpha: 0.25),
                width: 0.5,
              )
            : null,
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: shadowDark.withValues(alpha: isDark ? 0.8 : 1.0),
                  offset: Offset(offsetPressed, offsetPressed),
                  blurRadius: blurPressed,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: shadowLight.withValues(alpha: isDark ? 0.4 : 1.0),
                  offset: Offset(-offsetPressed, -offsetPressed),
                  blurRadius: blurPressed,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: shadowDark.withValues(alpha: isDark ? 0.9 : 1.0),
                  offset: Offset(offsetNormal, offsetNormal),
                  blurRadius: blurNormal,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: shadowLight.withValues(alpha: isDark ? 0.5 : 1.0),
                  offset: Offset(-offsetNormal, -offsetNormal),
                  blurRadius: blurNormal,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: child,
    );
  }
}

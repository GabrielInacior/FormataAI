import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Botão primário preenchido com gradiente (para ações principais).
class NeuPrimaryButton extends StatefulWidget {
  const NeuPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  @override
  State<NeuPrimaryButton> createState() => _NeuPrimaryButtonState();
}

class _NeuPrimaryButtonState extends State<NeuPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: widget.onPressed != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onPressed != null
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width ?? double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _isPressed
                ? [AppColors.primaryDark, AppColors.accent]
                : [AppColors.accent, AppColors.primaryDark],
          ),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    offset: const Offset(0, 6),
                    blurRadius: 20,
                  ),
                  BoxShadow(
                    color:
                        (isDark
                                ? AppColors.darkShadowDark
                                : AppColors.lightShadowDark)
                            .withValues(alpha: 0.3),
                    offset: const Offset(4, 4),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

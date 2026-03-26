import 'package:flutter/material.dart';

/// Paleta de cores do FormataAI — Neumorphism arroxeado com profundidade 3D
abstract final class AppColors {
  // ─── Primárias ────────────────────────────────
  static const primary = Color(0xFF7B7FB8);
  static const primaryLight = Color(0xFF9DA0D0);
  static const primaryDark = Color(0xFF3D4180);
  static const accent = Color(0xFF4C5FE0);
  static const accentLight = Color(0xFF6B7CF0);

  // ─── Light Theme ──────────────────────────────
  static const lightBg = Color(0xFFDFE2EE);
  static const lightSurface = Color(0xFFE8EBF5);
  static const lightShadowDark = Color(0xFFB8BDD0);
  static const lightShadowLight = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF252740);
  static const lightTextSecondary = Color(0xFF6E71A3);

  // ─── Dark Theme (melhor contraste) ────────────
  static const darkBg = Color(0xFF1A1A2E);
  static const darkSurface = Color(0xFF222240);
  static const darkShadowDark = Color(0xFF0F0F1E);
  static const darkShadowLight = Color(0xFF2A2A4E);
  static const darkText = Color(0xFFE8EAFF);
  static const darkTextSecondary = Color(0xFF9EA2CC);

  // ─── Shapes (formas decorativas) ──────────────
  static const waveLight = Color(0xFFCDD1E5);
  static const waveDark = Color(0xFF282850);

  // ─── Status ───────────────────────────────────
  static const success = Color(0xFF50C878);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFFBBF24);
}

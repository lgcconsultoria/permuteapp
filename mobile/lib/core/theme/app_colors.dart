import 'package:flutter/material.dart';

/// Identidade visual PermuteApp
/// Conceito: troca, valor, fluxo — teal profundo + âmbar (UP$)
class AppColors {
  AppColors._();

  // Primária — teal (confiança, fintech, fluxo)
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryWash = Color(0xFFE6FAFA);

  // Acento — âmbar (UP$, crédito, valor)
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentWash = Color(0xFFFEF3C7);

  // Semânticas
  static const Color credit = Color(0xFF059669);
  static const Color debit = Color(0xFFDC2626);

  // Superfície
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8F9FA);
  static const Color surfaceAlt = Color(0xFFEFF1F5);

  // Tipografia
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Bordas
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFF0D9488);

  // Gradientes
  static const LinearGradient walletGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
  );
}

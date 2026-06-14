import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color primary;
  final Color primarySoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color danger;
  final Color chip;
  final Color shadow;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.primary,
    required this.primarySoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.chip,
    required this.shadow,
  });

  static AppColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppColors>() ??
        (theme.brightness == Brightness.light
            ? AppTheme.lightColors
            : AppTheme.darkColors);
  }

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? primary,
    Color? primarySoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? warning,
    Color? danger,
    Color? chip,
    Color? shadow,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      chip: chip ?? this.chip,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

class AppTheme {
  static const darkColors = AppColors(
    background: Color(0xFF050816),
    surface: Color(0xFF12172A),
    surfaceAlt: Color(0xFF1A1D28),
    border: Color(0xFF27304A),
    primary: Color(0xFF8B93FF),
    primarySoft: Color(0xFFC7CCFF),
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    textMuted: Colors.white54,
    success: Color(0xFF00FF85),
    warning: Color(0xFFFFB84D),
    danger: Color(0xFFEF4444),
    chip: Color(0xFF0B1020),
    shadow: Colors.black,
  );

  static const lightColors = AppColors(
    background: Color(0xFFF6F8FC),
    surface: Colors.white,
    surfaceAlt: Color(0xFFF1F5F9),
    border: Color(0xFFD8E0EE),
    primary: Color(0xFF4F46E5),
    primarySoft: Color(0xFFE7E9FF),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF64748B),
    success: Color(0xFF0E8F52),
    warning: Color(0xFFD97706),
    danger: Color(0xFFDC2626),
    chip: Color(0xFFEFF3FA),
    shadow: Color(0xFF94A3B8),
  );

  static ThemeData dark() {
    return _build(
      brightness: Brightness.dark,
      colors: darkColors,
      scaffoldBackgroundColor: darkColors.background,
    );
  }

  static ThemeData light() {
    return _build(
      brightness: Brightness.light,
      colors: lightColors,
      scaffoldBackgroundColor: lightColors.background,
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required AppColors colors,
    required Color scaffoldBackgroundColor,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: brightness,
      primary: colors.primary,
      surface: colors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(color: colors.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceAlt,
        contentTextStyle: TextStyle(color: colors.textPrimary),
      ),
    );
  }
}

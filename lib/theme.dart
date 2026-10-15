import 'package:flutter/material.dart';

/* Paleta idêntica ao mockup (mockup/app.html) */
class AppColors {
  // dark
  static const darkBg = Color(0xFF0C0D0F);
  static const darkSurface = Color(0xFF151719);
  static const darkSurface2 = Color(0xFF1D2023);
  static const darkLine = Color(0xFF262A2E);
  static const darkText = Color(0xFFF2F4F5);
  static const darkDim = Color(0xFF969CA2);
  static const darkDimmer = Color(0xFF6A7075);
  // light
  static const lightBg = Color(0xFFF3F4F6);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFECEEF1);
  static const lightLine = Color(0xFFE3E6EA);
  static const lightText = Color(0xFF101316);
  static const lightDim = Color(0xFF6B7278);
  static const lightDimmer = Color(0xFF9AA0A6);
  // comum
  static const accent = Color(0xFF4EA8FF);
  static const accentSoft = Color(0x244EA8FF);
  static const heat = Color(0xFFFF9166);
  static const ok = Color(0xFF43D18C);
  static const warn = Color(0xFFFFC24D);
  static const danger = Color(0xFFFF4D4F);
  static const white = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        bg: AppColors.darkBg,
        surface: AppColors.darkSurface,
        surface2: AppColors.darkSurface2,
        line: AppColors.darkLine,
        text: AppColors.darkText,
        dim: AppColors.darkDim,
        dimmer: AppColors.darkDimmer,
      );

  static ThemeData light() => _build(
        brightness: Brightness.light,
        bg: AppColors.lightBg,
        surface: AppColors.lightSurface,
        surface2: AppColors.lightSurface2,
        line: AppColors.lightLine,
        text: AppColors.lightText,
        dim: AppColors.lightDim,
        dimmer: AppColors.lightDimmer,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color surface2,
    required Color line,
    required Color text,
    required Color dim,
    required Color dimmer,
  }) {
    final base = ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: text,
        error: AppColors.danger,
        onError: Colors.white,
        outline: line,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
        fontFamily: 'Roboto',
      ),
      dividerColor: line,
      extensions: [AppPalette(bg: bg, surface: surface, surface2: surface2, line: line, text: text, dim: dim, dimmer: dimmer)],
    );
  }
}

/* paleta viva acessível via context.palette() */
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg, surface, surface2, line, text, dim, dimmer;
  const AppPalette({required this.bg, required this.surface, required this.surface2, required this.line, required this.text, required this.dim, required this.dimmer});

  @override
  AppPalette copyWith({Color? bg, Color? surface, Color? surface2, Color? line, Color? text, Color? dim, Color? dimmer}) => AppPalette(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surface2: surface2 ?? this.surface2,
        line: line ?? this.line,
        text: text ?? this.text,
        dim: dim ?? this.dim,
        dimmer: dimmer ?? this.dimmer,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) => other is AppPalette ? other : this;
}

extension PaletteX on BuildContext {
  AppPalette palette() => Theme.of(this).extension<AppPalette>()!;
}

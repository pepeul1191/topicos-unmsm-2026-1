// configs/theme.dart
import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff596a5d),
      surfaceTint: Color(0xff596a5d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffdceedc),
      onPrimaryContainer: Color(0xff172119),
      secondary: Color(0xffb6cabc),
      onSecondary: Color(0xff21342a),
      secondaryContainer: Color(0xffd2e7d8),
      onSecondaryContainer: Color(0xff0e1f16),
      tertiary: Color(0xff596a5d),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffdceedc),
      onTertiaryContainer: Color(0xff172119),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xffe2e2e2),
      onSurface: Color(0xff191c1a),
      onSurfaceVariant: Color(0xff404843),
      outline: Color(0xff707973),
      outlineVariant: Color(0xffbfc8c1),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2e312f),
      inversePrimary: Color(0xffc0d2c1),
      primaryFixed: Color(0xffdceedc),
      onPrimaryFixed: Color(0xff162019),
      primaryFixedDim: Color(0xffc0d2c1),
      onPrimaryFixedVariant: Color(0xff415245),
      secondaryFixed: Color(0xffd2e7d8),
      onSecondaryFixed: Color(0xff051e15),
      secondaryFixedDim: Color(0xffb6cbbc),
      onSecondaryFixedVariant: Color(0xff35493e),
      tertiaryFixed: Color(0xffdceedc),
      onTertiaryFixed: Color(0xff162019),
      tertiaryFixedDim: Color(0xffc0d2c1),
      onTertiaryFixedVariant: Color(0xff415245),
      surfaceDim: Color(0xffc3c4c2),
      surfaceBright: Color(0xffe2e2e2),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffbfcfa),
      surfaceContainer: Color(0xfff5f6f4),
      surfaceContainerHigh: Color(0xffeff0ee),
      surfaceContainerHighest: Color(0xffe9eae8),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff3d4e41),
      surfaceTint: Color(0xff596a5d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff6f8073),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff314539),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff809588),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff3d4e41),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff6f8073),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xffe2e2e2),
      onSurface: Color(0xff151816),
      onSurfaceVariant: Color(0xff3c443f),
      outline: Color(0xff58605b),
      outlineVariant: Color(0xff737c76),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2e312f),
      inversePrimary: Color(0xffc0d2c1),
      primaryFixed: Color(0xff6f8073),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff56675b),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff809588),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff667b6e),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff6f8073),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff56675b),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffafb1ae),
      surfaceBright: Color(0xffe2e2e2),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffbfcfa),
      surfaceContainer: Color(0xffeff0ee),
      surfaceContainerHigh: Color(0xffe3e4e2),
      surfaceContainerHighest: Color(0xffd8d9d7),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff1b2d21),
      surfaceTint: Color(0xff596a5d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff3e4f42),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff0d2419),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff34483c),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff1b2d21),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff3e4f42),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xffe2e2e2),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff222a25),
      outlineVariant: Color(0xff3f4742),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2e312f),
      inversePrimary: Color(0xffc0d2c1),
      primaryFixed: Color(0xff3e4f42),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff27392c),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff34483c),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff1d3126),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff3e4f42),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff27392c),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffa1a3a1),
      surfaceBright: Color(0xffe2e2e2),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff6f7f5),
      surfaceContainer: Color(0xffe9eae8),
      surfaceContainerHigh: Color(0xffdbdcdb),
      surfaceContainerHighest: Color(0xffcdcfcd),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffc0d2c1),
      surfaceTint: Color(0xffc0d2c1),
      onPrimary: Color(0xff2a3c2f),
      primaryContainer: Color(0xff415245),
      onPrimaryContainer: Color(0xffdceedc),
      secondary: Color(0xffb6cbbc),
      onSecondary: Color(0xff1f3328),
      secondaryContainer: Color(0xff35493e),
      onSecondaryContainer: Color(0xffd2e7d8),
      tertiary: Color(0xffc0d2c1),
      onTertiary: Color(0xff2a3c2f),
      tertiaryContainer: Color(0xff415245),
      onTertiaryContainer: Color(0xffdceedc),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff111412),
      onSurface: Color(0xffe9eae8),
      onSurfaceVariant: Color(0xffbfc8c1),
      outline: Color(0xff8a928c),
      outlineVariant: Color(0xff404843),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe9eae8),
      inversePrimary: Color(0xff596a5d),
      primaryFixed: Color(0xffdceedc),
      onPrimaryFixed: Color(0xff162019),
      primaryFixedDim: Color(0xffc0d2c1),
      onPrimaryFixedVariant: Color(0xff415245),
      secondaryFixed: Color(0xffd2e7d8),
      onSecondaryFixed: Color(0xff051e15),
      secondaryFixedDim: Color(0xffb6cbbc),
      onSecondaryFixedVariant: Color(0xff35493e),
      tertiaryFixed: Color(0xffdceedc),
      onTertiaryFixed: Color(0xff162019),
      tertiaryFixedDim: Color(0xffc0d2c1),
      onTertiaryFixedVariant: Color(0xff415245),
      surfaceDim: Color(0xff111412),
      surfaceBright: Color(0xff373a38),
      surfaceContainerLowest: Color(0xff0c0f0d),
      surfaceContainerLow: Color(0xff191c1a),
      surfaceContainer: Color(0xff1d201e),
      surfaceContainerHigh: Color(0xff282b29),
      surfaceContainerHighest: Color(0xff333633),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffd4e7d5),
      surfaceTint: Color(0xffc0d2c1),
      onPrimary: Color(0xff0b1c13),
      primaryContainer: Color(0xff8ba48e),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffcbdfd1),
      onSecondary: Color(0xff001b12),
      secondaryContainer: Color(0xffa4b9ac),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffd4e7d5),
      onTertiary: Color(0xff0b1c13),
      tertiaryContainer: Color(0xff8ba48e),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff111412),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffd5ddd6),
      outline: Color(0xffabb3ad),
      outlineVariant: Color(0xff8a928c),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe9eae8),
      inversePrimary: Color(0xff435447),
      primaryFixed: Color(0xffdceedc),
      onPrimaryFixed: Color(0xff011008),
      primaryFixedDim: Color(0xffc0d2c1),
      onPrimaryFixedVariant: Color(0xff314236),
      secondaryFixed: Color(0xffd2e7d8),
      onSecondaryFixed: Color(0xff00130c),
      secondaryFixedDim: Color(0xffb6cbbc),
      onSecondaryFixedVariant: Color(0xff24382d),
      tertiaryFixed: Color(0xffdceedc),
      onTertiaryFixed: Color(0xff011008),
      tertiaryFixedDim: Color(0xffc0d2c1),
      onTertiaryFixedVariant: Color(0xff314236),
      surfaceDim: Color(0xff111412),
      surfaceBright: Color(0xff434643),
      surfaceContainerLowest: Color(0xff050806),
      surfaceContainerLow: Color(0xff1b1e1c),
      surfaceContainer: Color(0xff252927),
      surfaceContainerHigh: Color(0xff313431),
      surfaceContainerHighest: Color(0xff3c3f3d),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffecffee),
      surfaceTint: Color(0xffc0d2c1),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffbccebd),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffecffee),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffb2c7b9),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffecffee),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffbccebd),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff111412),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffe9f1ea),
      outlineVariant: Color(0xffbbc4bd),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe9eae8),
      inversePrimary: Color(0xff435447),
      primaryFixed: Color(0xffe1f3e2),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffc0d2c1),
      onPrimaryFixedVariant: Color(0xff011008),
      secondaryFixed: Color(0xffd7ecdd),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffb6cbbc),
      onSecondaryFixedVariant: Color(0xff00130c),
      tertiaryFixed: Color(0xffe1f3e2),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffc0d2c1),
      onTertiaryFixedVariant: Color(0xff011008),
      surfaceDim: Color(0xff111412),
      surfaceBright: Color(0xff4f524f),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1d201e),
      surfaceContainer: Color(0xff2e312f),
      surfaceContainerHigh: Color(0xff393c3a),
      surfaceContainerHighest: Color(0xff454846),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        textTheme: textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        scaffoldBackgroundColor: colorScheme.surface,
        canvasColor: colorScheme.surface,
      );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
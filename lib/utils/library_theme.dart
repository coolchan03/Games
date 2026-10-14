import 'package:flutter/material.dart';
import '../providers/library_style_provider.dart';

/// Layout and palette presets share typography and never shrink hit targets.
ThemeData applyLibraryStyle(ThemeData base, LibraryStyle style) {
  final compact = style == LibraryStyle.compact;
  final colors = style == LibraryStyle.colorful
      ? ColorScheme.fromSeed(seedColor: const Color(0xFF007F82),
          brightness: base.brightness, dynamicSchemeVariant: DynamicSchemeVariant.vibrant)
      : base.colorScheme;
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(compact ? 10 : 20));
  final button = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: 12)),
    shape: WidgetStatePropertyAll(shape),
    tapTargetSize: MaterialTapTargetSize.padded,
  );
  return base.copyWith(
    colorScheme: colors,
    scaffoldBackgroundColor: style == LibraryStyle.colorful ? colors.surface : base.scaffoldBackgroundColor,
    cardTheme: base.cardTheme.copyWith(
      margin: EdgeInsets.symmetric(vertical: compact ? 4 : 8),
      shape: shape, elevation: 0,
      color: style == LibraryStyle.colorful ? colors.surfaceContainerLow : null),
    filledButtonTheme: FilledButtonThemeData(style: button),
    elevatedButtonTheme: ElevatedButtonThemeData(style: button),
    outlinedButtonTheme: OutlinedButtonThemeData(style: button),
    textButtonTheme: TextButtonThemeData(style: button),
    listTileTheme: base.listTileTheme.copyWith(
      contentPadding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: compact ? 0 : 4)),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(compact ? 8 : 14)),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 14 : 18)),
  );
}

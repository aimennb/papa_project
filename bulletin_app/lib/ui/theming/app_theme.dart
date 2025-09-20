import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  return FlexThemeData.light(
    scheme: FlexScheme.gold,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 12,
    subThemesData: const FlexSubThemesData(
      defaultRadius: 14,
      elevatedButtonRadius: 16,
      inputDecoratorBorderType: FlexInputBorderType.outline,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'Roboto',
  );
}

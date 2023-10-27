import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// A custom notification class to signal changes in theme settings.
class ThemeSettingChange extends Notification {
  ThemeSettingChange({required this.settings});

  final ThemeSettings settings;
}

/// A custom [PageTransitionsBuilder] that provides no animation between pages.
class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

/// An inherited widget that provides access to theme-related settings and configurations.
class ThemeProvider extends InheritedWidget {
  const ThemeProvider(
      {super.key,
      required this.settings,
      required this.lightDynamic,
      required this.darkDynamic,
      required super.child});

  final ValueNotifier<ThemeSettings> settings;
  final ColorScheme? lightDynamic;
  final ColorScheme? darkDynamic;

  final pageTransitionsTheme = const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
      TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
      TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
    },
  );

  Color custom(CustomColor custom) {
    if (custom.blend) {
      return blend(custom.color);
    } else {
      return custom.color;
    }
  }

  Color blend(Color targetColor) {
    return Color(
        Blend.harmonize(targetColor.value, settings.value.sourceColor.value));
  }

  Color source(Color? target) {
    Color source = settings.value.sourceColor;
    if (target != null) {
      source = blend(target);
    }
    return source;
  }

  /// Creates [ColorScheme] based on brightness and targetColor
  ColorScheme colors(Brightness brightness, Color? targetColor) {
    final dynamicPrimary = brightness == Brightness.light
        ? lightDynamic?.primary
        : darkDynamic?.primary;
    final seedColor = dynamicPrimary ?? source(targetColor);
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
  }

  ShapeBorder get shapeMedium => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      );

  CardTheme cardTheme(ColorScheme colors) {
    return CardTheme(
      elevation: 0,
      color: colors.surfaceVariant,
      shape: shapeMedium,
      clipBehavior: Clip.antiAlias,
    );
  }

  ListTileThemeData listTileTheme(ColorScheme colors) {
    return ListTileThemeData(
      shape: shapeMedium,
      selectedColor: colors.secondary,
    );
  }

  AppBarTheme appBarTheme(ColorScheme colors) {
    return AppBarTheme(
      elevation: 0,
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
    );
  }

  TabBarTheme tabBarTheme(ColorScheme colors) {
    return TabBarTheme(
      labelColor: colors.secondary,
      unselectedLabelColor: colors.onSurfaceVariant,
      indicator: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.secondary,
            width: 2,
          ),
        ),
      ),
    );
  }

  BottomAppBarTheme bottomAppBarTheme(ColorScheme colors) {
    return BottomAppBarTheme(
      color: colors.surface,
      elevation: 0,
    );
  }

  BottomNavigationBarThemeData bottomNavigationBarTheme(ColorScheme colors) {
    return BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: colors.surfaceVariant,
      selectedItemColor: colors.onSurface,
      unselectedItemColor: colors.onSurfaceVariant,
      elevation: 0,
      landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
    );
  }

  NavigationRailThemeData navigationRailTheme(
      ColorScheme colors, TextTheme? textTheme) {
    return NavigationRailThemeData(
      backgroundColor: colors.surfaceVariant,
      indicatorColor: colors.primary,
      selectedIconTheme: IconThemeData(color: colors.onPrimary),
      unselectedIconTheme: IconThemeData(color: colors.onSurfaceVariant),
      selectedLabelTextStyle:
          textTheme?.bodyLarge?.copyWith(color: colors.primary),
      unselectedLabelTextStyle:
          textTheme?.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
    );
  }

  DrawerThemeData drawerTheme(ColorScheme colors) {
    return DrawerThemeData(
      backgroundColor: colors.surfaceVariant,
    );
  }

  PopupMenuThemeData popupMenuThemeDataTheme(ColorScheme colors) {
    return PopupMenuThemeData(
      elevation: 8,
      shape: shapeMedium,
      color: colors.surfaceVariant,
    );
  }

  TextTheme? fromTextTheme(ColorScheme colors, TextTheme? textTheme) {
    if (textTheme == null) return null;

    return textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(color: colors.onSurface),
      displayMedium: textTheme.displayMedium?.copyWith(color: colors.onSurface),
      displaySmall: textTheme.displaySmall?.copyWith(color: colors.onSurface),
      headlineLarge: textTheme.headlineLarge?.copyWith(color: colors.onSurface),
      headlineMedium:
          textTheme.headlineMedium?.copyWith(color: colors.onSurface),
      headlineSmall: textTheme.headlineSmall?.copyWith(color: colors.onSurface),
      titleLarge: textTheme.titleLarge?.copyWith(color: colors.onSurface),
      titleMedium: textTheme.titleMedium?.copyWith(color: colors.onSurface),
      titleSmall: textTheme.titleSmall?.copyWith(color: colors.onSurface),
      labelLarge: textTheme.labelLarge?.copyWith(color: colors.onSurface),
      labelMedium: textTheme.labelMedium?.copyWith(color: colors.onSurface),
      labelSmall: textTheme.labelSmall?.copyWith(color: colors.onSurface),
      bodyLarge: textTheme.bodyLarge?.copyWith(color: colors.onSurface),
      bodyMedium: textTheme.bodyMedium?.copyWith(color: colors.onSurface),
      bodySmall: textTheme.bodySmall?.copyWith(color: colors.onSurface),
    );
  }

  ThemeData light([Color? targetColor, TextTheme? textTheme]) {
    final c = colors(Brightness.light, targetColor);
    return ThemeData.light(useMaterial3: true).copyWith(
      pageTransitionsTheme: pageTransitionsTheme,
      colorScheme: c,
      appBarTheme: appBarTheme(c),
      cardTheme: cardTheme(c),
      listTileTheme: listTileTheme(c),
      bottomAppBarTheme: bottomAppBarTheme(c),
      bottomNavigationBarTheme: bottomNavigationBarTheme(c),
      navigationRailTheme: navigationRailTheme(c, textTheme),
      tabBarTheme: tabBarTheme(c),
      drawerTheme: drawerTheme(c),
      popupMenuTheme: popupMenuThemeDataTheme(c),
      scaffoldBackgroundColor: c.background,
      textTheme: fromTextTheme(c, textTheme),
      primaryColor: c.primary,
      primaryColorLight:
          Color.alphaBlend(Colors.white.withAlpha(0x66), c.primary),
      primaryColorDark:
          Color.alphaBlend(Colors.black.withAlpha(0x66), c.primary),
      secondaryHeaderColor:
          Color.alphaBlend(Colors.white.withAlpha(0xCC), c.primary),
      canvasColor: c.background,
      cardColor: c.surface,
      dialogBackgroundColor: c.surface,
      indicatorColor: c.onPrimary,
      dividerColor: c.onSurface.withOpacity(0.12),
      applyElevationOverlayColor: false,
      visualDensity: VisualDensity.standard,
    );
  }

  ThemeData dark([Color? targetColor, TextTheme? textTheme]) {
    final c = colors(Brightness.dark, targetColor);
    return ThemeData.dark(useMaterial3: true).copyWith(
      pageTransitionsTheme: pageTransitionsTheme,
      colorScheme: c,
      appBarTheme: appBarTheme(c),
      cardTheme: cardTheme(c),
      listTileTheme: listTileTheme(c),
      bottomAppBarTheme: bottomAppBarTheme(c),
      bottomNavigationBarTheme: bottomNavigationBarTheme(c),
      navigationRailTheme: navigationRailTheme(c, textTheme),
      tabBarTheme: tabBarTheme(c),
      drawerTheme: drawerTheme(c),
      popupMenuTheme: popupMenuThemeDataTheme(c),
      scaffoldBackgroundColor: c.background,
      textTheme: fromTextTheme(c, textTheme),
      primaryColor: c.primary,
      primaryColorLight:
          Color.alphaBlend(Colors.white.withAlpha(0x59), c.primary),
      primaryColorDark:
          Color.alphaBlend(Colors.black.withAlpha(0x72), c.primary),
      secondaryHeaderColor:
          Color.alphaBlend(Colors.black.withAlpha(0x99), c.primary),
      canvasColor: c.surfaceVariant,
      cardColor: c.surface,
      dialogBackgroundColor: c.surface,
      indicatorColor: c.onBackground,
      dividerColor: c.onSurface.withOpacity(0.12),
      applyElevationOverlayColor: true,
      visualDensity: VisualDensity.standard,
    );
  }

  ThemeMode themeMode() {
    return settings.value.themeMode;
  }

  ThemeData theme(BuildContext context, [Color? targetColor]) {
    final brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.light
        ? light(targetColor)
        : dark(targetColor);
  }

  static ThemeProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>()!;
  }

  @override
  bool updateShouldNotify(covariant ThemeProvider oldWidget) {
    return oldWidget.settings != settings;
  }
}

/// A class representing theme settings.
class ThemeSettings {
  ThemeSettings({
    required this.sourceColor,
    required this.themeMode,
  });

  final Color sourceColor;
  final ThemeMode themeMode;
}

/// Generates a random color.
Color randomColor() {
  return Color(Random().nextInt(0xFFFFFFFF));
}

/// Custom Colors
const linkColor = CustomColor(
  name: 'Link Color',
  color: Color(0xFF00B0FF),
);

/// A class representing a custom color with an optional blend property.
class CustomColor {
  const CustomColor({
    required this.name,
    required this.color,
    this.blend = true,
  });

  final String name;
  final Color color;
  final bool blend;

  /// Returns the custom color's value based on the provider's settings
  Color value(ThemeProvider provider) {
    return provider.custom(this);
  }
}

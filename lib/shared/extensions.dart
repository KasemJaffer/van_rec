import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

import 'package:van_rec/shared/providers/theme.dart';

extension TypographyUtils on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => GoogleFonts.montserratTextTheme(theme.textTheme);

  ColorScheme get colors => theme.colorScheme;

  TextStyle? get displayLarge =>
      textTheme.displayLarge?.copyWith(color: colors.onSurface);

  TextStyle? get displayMedium =>
      textTheme.displayMedium?.copyWith(color: colors.onSurface);

  TextStyle? get displaySmall =>
      textTheme.displaySmall?.copyWith(color: colors.onSurface);

  TextStyle? get headlineLarge =>
      textTheme.headlineLarge?.copyWith(color: colors.onSurface);

  TextStyle? get headlineMedium =>
      textTheme.headlineMedium?.copyWith(color: colors.onSurface);

  TextStyle? get headlineSmall =>
      textTheme.headlineSmall?.copyWith(color: colors.onSurface);

  TextStyle? get titleLarge =>
      textTheme.titleLarge?.copyWith(color: colors.onSurface);

  TextStyle? get titleMedium =>
      textTheme.titleMedium?.copyWith(color: colors.onSurface);

  TextStyle? get titleSmall =>
      textTheme.titleSmall?.copyWith(color: colors.onSurface);

  TextStyle? get labelLarge =>
      textTheme.labelLarge?.copyWith(color: colors.onSurface);

  TextStyle? get labelMedium =>
      textTheme.labelMedium?.copyWith(color: colors.onSurface);

  TextStyle? get labelSmall =>
      textTheme.labelSmall?.copyWith(color: colors.onSurface);

  TextStyle? get bodyLarge =>
      textTheme.bodyLarge?.copyWith(color: colors.onSurface);

  TextStyle? get bodyMedium =>
      textTheme.bodyMedium?.copyWith(color: colors.onSurface);

  TextStyle? get bodySmall =>
      textTheme.bodySmall?.copyWith(color: colors.onSurface);

  Color colorFor(int id) {
    final provider = ThemeProvider.of(this);
    final mode = provider.themeMode();
    final source = provider.custom(
      CustomColor(
        name: '$id',
        color: Color(Random(id).nextInt(0xFFFFFFFF)),
      ),
    );
    ThemeData theme;
    if (mode == ThemeMode.dark) {
      theme = provider.dark(source, textTheme);
    } else {
      theme = provider.light(source, textTheme);
    }
    return theme.colorScheme.primaryContainer;
  }

  BoxDecoration get stylizedButtonDecoration {
    return BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(50)),
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          colors.secondary,
          colors.tertiary,
        ],
      ),
    );
  }

  BoxDecoration get splashDecoration {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colors.primaryContainer,
          colors.secondaryContainer,
          colors.tertiaryContainer,
        ],
      ),
    );
  }
}

extension BreakpointUtils on BoxConstraints {
  bool get isTablet => maxWidth > 730;

  bool get isDesktop => maxWidth > 1200;

  bool get isMobile => !isTablet && !isDesktop;
}

extension DurationString on String {
  /// Assumes a string (roughly) of the format '\d{1,2}:\d{2}'
  Duration toDuration() {
    final chunks = split(':');
    if (chunks.length == 1) {
      throw Exception('Invalid duration string: $this');
    } else if (chunks.length == 2) {
      return Duration(
        minutes: int.parse(chunks[0].trim()),
        seconds: int.parse(chunks[1].trim()),
      );
    } else if (chunks.length == 3) {
      return Duration(
        hours: int.parse(chunks[0].trim()),
        minutes: int.parse(chunks[1].trim()),
        seconds: int.parse(chunks[2].trim()),
      );
    } else {
      throw Exception('Invalid duration string: $this');
    }
  }
}

extension HumanizedDuration on Duration {
  String toHumanizedString() {
    final s = '${inSeconds % 60}'.padLeft(2, '0');
    String m = '${inMinutes % 60}';
    if (inHours > 0 || inMinutes == 0) {
      m = m.padLeft(2, '0');
    }
    String value = '$m:$s';
    if (inHours > 0) {
      value = '$inHours:$m:$s';
    }
    return value;
  }
}

extension StringE on String? {
  String? assertEmail([bool throwException = false]) {
    String? message;
    if (this == null || this!.trim().isEmpty) {
      message = "Email cannot be empty.";
    } else if (!emailPattern.hasMatch(this!.trim())) {
      message = "Invalid Email.";
    }

    if (message != null && throwException) {
      throw Exception(message);
    }

    return message;
  }

  String? assertPassword([bool throwException = false]) {
    String? message;

    if (this == null || this!.trim().isEmpty) {
      message = "Password cannot be empty.";
    } else if (this!.trim().length < 6) {
      message = "Password cannot be less than 6 characters.";
    }

    if (message != null && throwException) {
      throw Exception(message);
    }
    return message;
  }

  String? assertNotEmpty([String name = "Field", bool throwException = false]) {
    String? message;

    if (this == null || this!.trim().isEmpty) {
      message = "$name cannot be empty.";
    }

    if (message != null && throwException) {
      throw Exception(message);
    }
    return message;
  }

  String? assertJson([bool throwException = false]) {
    String? message;

    if (this == null || this!.trim().isEmpty) {
      message = "Json cannot be empty.";
      if (throwException) throw Exception(message);
      return message;
    }

    try {
      jsonDecode(this!);
    } catch (e) {
      if (throwException) {
        rethrow;
      }
      message = e.toString();
    }
    return message;
  }

  String? assertJsonObject([bool throwException = false]) {
    String? message;

    if (this == null || this!.trim().isEmpty) {
      message = "Json cannot be empty.";
      if (throwException) throw Exception(message);
      return message;
    }

    try {
      final j = jsonDecode(this!);
      if (j is List) {
        message = "Json cannot be of type List.";
        if (throwException) throw Exception(message);
      }
    } catch (e) {
      if (throwException) {
        rethrow;
      }
      message = e.toString();
    }
    return message;
  }
}

final emailPattern = RegExp(
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');


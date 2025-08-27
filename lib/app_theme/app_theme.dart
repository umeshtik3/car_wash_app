import 'package:flutter/material.dart';

/// App design tokens mapped from htmls/styles.css
/// Colors, typography, spacing, radii, and shadows.
/// Two themes are exposed: light and dark.

class AppColors {
  // Base palette (from CSS variables)
  static const Color primary = Color(0xFF000000);
  static const Color secondary = Color(0xFFFFD700);
  static const Color accent = Color(0xFF00FF00);
  static const Color background = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF808080);
  static const Color error = Color(0xFFFF0000);
  static const Color success = Color(0xFF008000);
  static const Color info = Color(0xFF0000FF);
  static const Color warning = Color(0xFFFFA500);
  static const Color discount = Color(0xFFFF4500);
  static const Color border = Color(0xFFD3D3D3);
  static const Color placeholder = Color(0xFFA9A9A9);

  // Dark equivalents (derived sensibly for Material)
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkBorder = Color(0xFF2E2E2E);
  static const Color darkPlaceholder = Color(0xFF8E8E8E);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadii {
  static const BorderRadius small = BorderRadius.all(Radius.circular(4));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(8));
  static const BorderRadius large = BorderRadius.all(Radius.circular(16));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

class AppShadows {
  static const List<BoxShadow> small = <BoxShadow>[
    BoxShadow(color: Color(0x1F000000), blurRadius: 3, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> medium = <BoxShadow>[
    BoxShadow(color: Color(0x29000000), blurRadius: 6, offset: Offset(0, 3)),
  ];
  static const List<BoxShadow> large = <BoxShadow>[
    BoxShadow(color: Color(0x30000000), blurRadius: 20, offset: Offset(0, 10)),
  ];
}

class AppTextStyles {
  // From CSS tokens
  static const double h1Size = 24;
  static const double h2Size = 20;
  static const double h3Size = 18;
  static const double bodySize = 14;
  static const double captionSize = 12;

  static const double h1LineHeight = 32; // approximate via height
  static const double h2LineHeight = 28;
  static const double h3LineHeight = 24;
  static const double bodyLineHeight = 20;
  static const double captionLineHeight = 16;

  static TextTheme textTheme({required bool isDark}) {
    final Color primaryText = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final Color secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return TextTheme(
      headlineSmall: TextStyle( // h1
        fontSize: h1Size,
        fontWeight: FontWeight.w700,
        height: h1LineHeight / h1Size,
        color: primaryText,
        fontFamily: 'Roboto',
      ),
      titleLarge: TextStyle( // h2
        fontSize: h2Size,
        fontWeight: FontWeight.w600,
        height: h2LineHeight / h2Size,
        color: primaryText,
        fontFamily: 'Roboto',
      ),
      titleMedium: TextStyle( // h3
        fontSize: h3Size,
        fontWeight: FontWeight.w500,
        height: h3LineHeight / h3Size,
        color: primaryText,
        fontFamily: 'Roboto',
      ),
      bodyMedium: TextStyle(
        fontSize: bodySize,
        fontWeight: FontWeight.w400,
        height: bodyLineHeight / bodySize,
        color: primaryText,
        fontFamily: 'Roboto',
      ),
      bodySmall: TextStyle( // caption
        fontSize: captionSize,
        fontWeight: FontWeight.w400,
        height: captionLineHeight / captionSize,
        color: secondaryText,
        fontFamily: 'Roboto',
      ),
      labelLarge: TextStyle(
        fontSize: bodySize,
        fontWeight: FontWeight.w500,
        color: primaryText,
        fontFamily: 'Roboto',
      ),
    );
  }
}

class AppTheme {
  static ThemeData light() {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      tertiary: AppColors.accent,
      onTertiary: AppColors.textPrimary,
    );

    final TextTheme textTheme = AppTextStyles.textTheme(isDark: false);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      inputDecorationTheme: _inputDecorationTheme(isDark: false),
      elevatedButtonTheme: _elevatedButtonTheme(isDark: false),
      textButtonTheme: _textButtonTheme(isDark: false),
      cardTheme: CardThemeData(
        color: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.medium),
        elevation: 0,
        shadowColor: const Color(0x1F000000),
        margin: EdgeInsets.zero,
      ),
      dividerColor: AppColors.border,
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }

  static ThemeData dark() {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.darkTextPrimary,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      tertiary: AppColors.accent,
      onTertiary: AppColors.darkTextPrimary,
    );

    final TextTheme textTheme = AppTextStyles.textTheme(isDark: true);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: textTheme,
      inputDecorationTheme: _inputDecorationTheme(isDark: true),
      elevatedButtonTheme: _elevatedButtonTheme(isDark: true),
      textButtonTheme: _textButtonTheme(isDark: true),
      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.medium),
        elevation: 0,
        shadowColor: Color(0x33000000),
        margin: EdgeInsets.zero,
      ),
      dividerColor: AppColors.darkBorder,
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({required bool isDark}) {
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final Color focusColor = AppColors.primary;
    final Color labelColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final Color hintColor = isDark ? AppColors.darkPlaceholder : AppColors.placeholder;

    OutlineInputBorder outline(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: AppRadii.small,
      borderSide: BorderSide(color: color, width: width),
    );

    return InputDecorationTheme(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      border: outline(borderColor),
      enabledBorder: outline(borderColor),
      focusedBorder: outline(focusColor, 1.2),
      errorBorder: outline(AppColors.error),
      focusedErrorBorder: outline(AppColors.error, 1.2),
      labelStyle: TextStyle(color: labelColor),
      hintStyle: TextStyle(color: hintColor),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme({required bool isDark}) {
    final Color background = AppColors.primary;
    final Color foreground = Colors.white;
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(background),
        foregroundColor: WidgetStateProperty.all<Color>(foreground),
        elevation: WidgetStateProperty.all<double>(0),
        padding: WidgetStateProperty.all<EdgeInsets>(
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          const RoundedRectangleBorder(borderRadius: AppRadii.medium),
        ),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme({required bool isDark}) {
    final Color foreground = AppColors.primary;
    return TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(foreground),
        overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
            return AppColors.primary.withValues(alpha: 0.06);
          }
          return null;
        }),
        padding: WidgetStateProperty.all<EdgeInsets>(
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          const RoundedRectangleBorder(borderRadius: AppRadii.medium),
        ),
      ),
    );
  }
}

/// Convenience extensions and helper widgets styles
extension ContextTheme on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
}



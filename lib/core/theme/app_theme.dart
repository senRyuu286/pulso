import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'pulso_theme_extension.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryL,
      onPrimary: Color(0xFFFFFFFF),
      secondary: AppColors.secondaryL,
      onSecondary: AppColors.onSecondaryL,
      surface: AppColors.surfaceL,
      onSurface: AppColors.textPrimaryL,
      surfaceContainerHighest: AppColors.surfaceInsetL,
      onSurfaceVariant: AppColors.textSecondaryL,
      outline: AppColors.dividerL,
      outlineVariant: AppColors.dividerL,
      error: Color(0xFFE8172C),
      onError: Color(0xFFFFFFFF),
      shadow: Color(0x00000000),
      scrim: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surfaceL,
      extensions: const [PulsoThemeExtension.light],
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceL,
        foregroundColor: AppColors.textPrimaryL,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.headline.copyWith(
          color: AppColors.textPrimaryL,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryL),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceInsetL,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryL, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryL, width: 1.5),
        ),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textPlaceholderL),
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondaryL),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryL,
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 52),
          textStyle: AppTextStyles.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryL,
          side: const BorderSide(color: AppColors.primaryL, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 52),
          textStyle: AppTextStyles.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryL,
          textStyle: AppTextStyles.label,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceL,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.dividerL, width: 0.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerL,
        thickness: 0.5,
        space: 0,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(color: AppColors.textPrimaryL),
        headlineLarge: AppTextStyles.headline.copyWith(color: AppColors.textPrimaryL),
        titleLarge: AppTextStyles.title.copyWith(color: AppColors.textPrimaryL),
        bodyLarge: AppTextStyles.body.copyWith(color: AppColors.textPrimaryL),
        bodyMedium: AppTextStyles.body.copyWith(color: AppColors.textPrimaryL),
        bodySmall: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryL),
        labelLarge: AppTextStyles.label.copyWith(color: AppColors.textPrimaryL),
        labelSmall: AppTextStyles.timestamp.copyWith(color: AppColors.textSecondaryL),
      ),
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryD,
      onPrimary: Color(0xFFFFFFFF),
      secondary: AppColors.secondaryD,
      onSecondary: AppColors.onSecondaryD,
      surface: AppColors.surfaceD,
      onSurface: AppColors.textPrimaryD,
      surfaceContainerHighest: AppColors.surfaceInsetD,
      onSurfaceVariant: AppColors.textSecondaryD,
      outline: AppColors.dividerD,
      outlineVariant: AppColors.dividerD,
      error: Color(0xFFFF3347),
      onError: Color(0xFFFFFFFF),
      shadow: Color(0x00000000),
      scrim: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surfaceD,
      extensions: const [PulsoThemeExtension.dark],
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceD,
        foregroundColor: AppColors.textPrimaryD,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.headline.copyWith(
          color: AppColors.textPrimaryD,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryD),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceInsetD,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryD, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryD, width: 1.5),
        ),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textPlaceholderD),
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondaryD),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryD,
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 52),
          textStyle: AppTextStyles.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryD,
          side: const BorderSide(color: AppColors.primaryD, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 52),
          textStyle: AppTextStyles.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryD,
          textStyle: AppTextStyles.label,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceRaisedD,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.dividerD, width: 0.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerD,
        thickness: 0.5,
        space: 0,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(color: AppColors.textPrimaryD),
        headlineLarge: AppTextStyles.headline.copyWith(color: AppColors.textPrimaryD),
        titleLarge: AppTextStyles.title.copyWith(color: AppColors.textPrimaryD),
        bodyLarge: AppTextStyles.body.copyWith(color: AppColors.textPrimaryD),
        bodyMedium: AppTextStyles.body.copyWith(color: AppColors.textPrimaryD),
        bodySmall: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryD),
        labelLarge: AppTextStyles.label.copyWith(color: AppColors.textPrimaryD),
        labelSmall: AppTextStyles.timestamp.copyWith(color: AppColors.textSecondaryD),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

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
      surfaceContainerHighest: AppColors.surfaceRaisedL,
      onSurfaceVariant: AppColors.textSecondaryL,
      outline: AppColors.dividerL,
      outlineVariant: AppColors.dividerL,
      error: Color(0xFFFF5261),
      onError: Color(0xFFFFFFFF),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'DM Sans',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surfaceL,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceL,
        foregroundColor: AppColors.textPrimaryL,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.title.copyWith(
          color: AppColors.textPrimaryL,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryL),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceRaisedL,
        selectedItemColor: AppColors.primaryL,
        unselectedItemColor: AppColors.textSecondaryL,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceInsetL,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
          borderSide: BorderSide(
            color: AppColors.primaryL.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        hintStyle: AppTextStyles.body.copyWith(
          color: AppColors.textPlaceholderL,
        ),
        labelStyle: AppTextStyles.body.copyWith(
          color: AppColors.textSecondaryL,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryL,
          foregroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 52),
          textStyle: AppTextStyles.label,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceRaisedL,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(
          color: AppColors.textPrimaryL,
        ),
        headlineLarge: AppTextStyles.headline.copyWith(
          color: AppColors.textPrimaryL,
        ),
        titleLarge: AppTextStyles.title.copyWith(
          color: AppColors.textPrimaryL,
        ),
        bodyLarge: AppTextStyles.body.copyWith(
          color: AppColors.textPrimaryL,
        ),
        bodyMedium: AppTextStyles.body.copyWith(
          color: AppColors.textPrimaryL,
        ),
        labelLarge: AppTextStyles.label.copyWith(
          color: AppColors.textPrimaryL,
        ),
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
      surfaceContainerHighest: AppColors.surfaceRaisedD,
      onSurfaceVariant: AppColors.textSecondaryD,
      outline: AppColors.dividerD,
      outlineVariant: AppColors.dividerD,
      error: Color(0xFFFF5261),
      onError: Color(0xFFFFFFFF),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'DM Sans',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surfaceD,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceD,
        foregroundColor: AppColors.textPrimaryD,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.title.copyWith(
          color: AppColors.textPrimaryD,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryD),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceRaisedD,
        selectedItemColor: AppColors.primaryD,
        unselectedItemColor: AppColors.textSecondaryD,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceInsetD,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
          borderSide: BorderSide(
            color: AppColors.primaryD.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        hintStyle: AppTextStyles.body.copyWith(
          color: AppColors.textPlaceholderD,
        ),
        labelStyle: AppTextStyles.body.copyWith(
          color: AppColors.textSecondaryD,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryD,
          foregroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 52),
          textStyle: AppTextStyles.label,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceRaisedD,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(
          color: AppColors.textPrimaryD,
        ),
        headlineLarge: AppTextStyles.headline.copyWith(
          color: AppColors.textPrimaryD,
        ),
        titleLarge: AppTextStyles.title.copyWith(
          color: AppColors.textPrimaryD,
        ),
        bodyLarge: AppTextStyles.body.copyWith(
          color: AppColors.textPrimaryD,
        ),
        bodyMedium: AppTextStyles.body.copyWith(
          color: AppColors.textPrimaryD,
        ),
        labelLarge: AppTextStyles.label.copyWith(
          color: AppColors.textPrimaryD,
        ),
      ),
    );
  }
}
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Rounded-square avatar used across all screens.
///
/// Matches the design: rounded corners (16dp), red border ring, initials
/// fallback when no image is available.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.size,
    this.avatarUrl,
    this.username,
    this.showBorder = true,
  });

  final double size;
  final String? avatarUrl;
  final String? username;

  /// Whether to show the red border ring. Set false for very small avatars.
  final bool showBorder;

  static const double _borderWidth = 2.0;
  static const double _borderRadius = 14.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryD : AppColors.primaryL;
    final borderColor = showBorder ? primary : Colors.transparent;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: borderColor, width: _borderWidth),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_borderRadius - _borderWidth),
        child: _AvatarContent(
          size: size,
          avatarUrl: avatarUrl,
          username: username,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _AvatarContent extends StatelessWidget {
  const _AvatarContent({
    required this.size,
    required this.isDark,
    this.avatarUrl,
    this.username,
  });

  final double size;
  final String? avatarUrl;
  final String? username;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fallback = _Fallback(size: size, username: username, isDark: isDark);

    if (avatarUrl == null || avatarUrl!.isEmpty) return fallback;

    return CachedNetworkImage(
      imageUrl: avatarUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.size,
    required this.isDark,
    this.username,
  });

  final double size;
  final String? username;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surfaceInsetD : AppColors.surfaceInsetL;
    final fg = isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL;

    final initial = (username?.isNotEmpty == true)
        ? username![0].toUpperCase()
        : null;

    return Container(
      width: size,
      height: size,
      color: bg,
      child: Center(
        child: initial != null
            ? Text(
                initial,
                style: AppTextStyles.label.copyWith(
                  color: fg,
                  fontSize: size * 0.38,
                  height: 1,
                ),
              )
            : Icon(Icons.person_rounded, size: size * 0.55, color: fg),
      ),
    );
  }
}

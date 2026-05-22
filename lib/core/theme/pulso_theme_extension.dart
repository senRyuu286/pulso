import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Pulso-specific design tokens that have no direct Material [ColorScheme] slot.
///
/// Register in [ThemeData.extensions] for both light and dark themes.
/// Access in widgets via [context.pulso].
///
/// Tokens already covered by [ColorScheme]:
///   primary       → cs.primary
///   surface       → cs.surface
///   surfaceRaised → cs.surfaceContainerHighest
///   textPrimary   → cs.onSurface
///   textSecondary → cs.onSurfaceVariant
@immutable
class PulsoThemeExtension extends ThemeExtension<PulsoThemeExtension> {
  const PulsoThemeExtension({
    required this.surfaceInset,
    required this.primaryMuted,
    required this.primarySoft,
    required this.amber,
    required this.textPlaceholder,
  });

  final Color surfaceInset;
  final Color primaryMuted;
  final Color primarySoft;
  final Color amber;
  final Color textPlaceholder;

  static const light = PulsoThemeExtension(
    surfaceInset:    AppColors.surfaceInsetL,
    primaryMuted:    AppColors.primaryMutedL,
    primarySoft:     AppColors.primarySoftL,
    amber:           AppColors.amberL,
    textPlaceholder: AppColors.textPlaceholderL,
  );

  static const dark = PulsoThemeExtension(
    surfaceInset:    AppColors.surfaceInsetD,
    primaryMuted:    AppColors.primaryMutedD,
    primarySoft:     AppColors.primarySoftD,
    amber:           AppColors.amberD,
    textPlaceholder: AppColors.textPlaceholderD,
  );

  @override
  PulsoThemeExtension copyWith({
    Color? surfaceInset,
    Color? primaryMuted,
    Color? primarySoft,
    Color? amber,
    Color? textPlaceholder,
  }) {
    return PulsoThemeExtension(
      surfaceInset:    surfaceInset    ?? this.surfaceInset,
      primaryMuted:    primaryMuted    ?? this.primaryMuted,
      primarySoft:     primarySoft     ?? this.primarySoft,
      amber:           amber           ?? this.amber,
      textPlaceholder: textPlaceholder ?? this.textPlaceholder,
    );
  }

  @override
  PulsoThemeExtension lerp(PulsoThemeExtension? other, double t) {
    if (other == null) return this;
    return PulsoThemeExtension(
      surfaceInset:    Color.lerp(surfaceInset,    other.surfaceInset,    t)!,
      primaryMuted:    Color.lerp(primaryMuted,    other.primaryMuted,    t)!,
      primarySoft:     Color.lerp(primarySoft,     other.primarySoft,     t)!,
      amber:           Color.lerp(amber,           other.amber,           t)!,
      textPlaceholder: Color.lerp(textPlaceholder, other.textPlaceholder, t)!,
    );
  }
}

/// Convenience accessor — avoids writing [Theme.of(context).extension<PulsoThemeExtension>()!]
/// in every build method.
extension PulsoContext on BuildContext {
  PulsoThemeExtension get pulso =>
      Theme.of(this).extension<PulsoThemeExtension>()!;
}

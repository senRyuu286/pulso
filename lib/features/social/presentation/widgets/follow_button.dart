import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pulso_theme_extension.dart';
import '../providers/follow_notifier.dart';

/// Follow / Unfollow button — design spec section 5.8.
///
/// Unfollowed → Raised neumorphic, "Follow" in primary.
/// Following  → Inset  neumorphic, "Following" in text-secondary.
/// Transition: custom painter interpolates shadow values over 200ms.
class FollowButton extends ConsumerStatefulWidget {
  const FollowButton({
    super.key,
    required this.targetUserId,
    this.width = double.infinity,
  });

  final String targetUserId;
  final double width;

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _morph;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _morph = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(followNotifierProvider.notifier).load(widget.targetUserId);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _syncAnimation(FollowState followState) {
    if (followState is FollowLoaded) {
      if (followState.isFollowing && _ctrl.value < 1.0) {
        _ctrl.forward();
      } else if (!followState.isFollowing && _ctrl.value > 0.0) {
        _ctrl.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = ref.watch(followNotifierProvider);
    final followState = map[widget.targetUserId] ?? const FollowChecking();

    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAnimation(followState));

    return AnimatedBuilder(
      animation: _morph,
      builder: (context, _) {
        final isFollowing = followState is FollowLoaded && followState.isFollowing;
        return _FollowSurface(
          t: _morph.value,
          isLoading: followState is FollowChecking,
          isFollowing: isFollowing,
          width: widget.width,
          onTap: followState is FollowLoaded
              ? () => ref.read(followNotifierProvider.notifier).toggle(widget.targetUserId)
              : null,
        );
      },
    );
  }
}

class _FollowSurface extends StatelessWidget {
  const _FollowSurface({
    required this.t,
    required this.isLoading,
    required this.isFollowing,
    required this.width,
    required this.onTap,
  });

  final double t; // 0 = raised/unfollowed, 1 = inset/following
  final bool isLoading;
  final bool isFollowing;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pulso = context.pulso;

    final bg = Color.lerp(cs.surfaceContainerHighest, pulso.surfaceInset, t)!;
    final labelColor = Color.lerp(cs.primary, cs.onSurfaceVariant, t)!;

    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: isFollowing ? 'Unfollow' : 'Follow',
        button: true,
        child: CustomPaint(
          painter: _MorphShadowPainter(
            t: t,
            bg: bg,
            shadowLight: pulso.shadowLight,
            shadowDark: pulso.shadowDark,
            blur: pulso.shadowBlur,
          ),
          child: SizedBox(
            width: width,
            height: 48,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: labelColor),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        isFollowing ? 'Following' : 'Follow',
                        key: ValueKey(isFollowing),
                        style: AppTextStyles.label.copyWith(color: labelColor),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Interpolates between outset (raised) shadows at t=0 and inset shadows at t=1.
class _MorphShadowPainter extends CustomPainter {
  const _MorphShadowPainter({
    required this.t,
    required this.bg,
    required this.shadowLight,
    required this.shadowDark,
    required this.blur,
  });

  final double t;
  final Color bg;
  final Color shadowLight;
  final Color shadowDark;
  final double blur;

  static const double _offset = 6.0;
  static const double _radius = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(_radius),
    );

    canvas.drawRRect(rrect, Paint()..color = bg);

    final outsetOpacity = 1.0 - t;
    final insetOpacity  = t;

    if (outsetOpacity > 0) {
      canvas.drawRRect(
        rrect.shift(const Offset(-_offset, -_offset)),
        Paint()
          ..color = shadowLight.withValues(alpha: outsetOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
      canvas.drawRRect(
        rrect.shift(const Offset(_offset, _offset)),
        Paint()
          ..color = shadowDark.withValues(alpha: outsetOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }

    if (insetOpacity > 0) {
      canvas.save();
      canvas.clipRRect(rrect);
      _drawInner(canvas, size, shadowDark.withValues(alpha: insetOpacity), const Offset(_offset, _offset));
      _drawInner(canvas, size, shadowLight.withValues(alpha: insetOpacity), const Offset(-_offset, -_offset));
      canvas.restore();
    }
  }

  void _drawInner(Canvas canvas, Size size, Color color, Offset dir) {
    const pad = 600.0;
    final huge = Rect.fromLTWH(-pad, -pad, size.width + pad * 2, size.height + pad * 2);
    final shifted = RRect.fromRectAndRadius(
      (Offset.zero & size).shift(dir),
      const Radius.circular(_radius),
    );
    final path = Path()
      ..addRect(huge)
      ..addRRect(shifted)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2),
    );
  }

  @override
  bool shouldRepaint(_MorphShadowPainter old) =>
      old.t != t || old.bg != bg;
}

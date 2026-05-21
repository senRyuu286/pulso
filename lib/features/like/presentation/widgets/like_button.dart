import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../feed/domain/models/post.dart';
import '../../../feed/presentation/providers/feed_notifier.dart';

/// Full Pulso heartbeat like button — design spec section 5.2 + 6.
///
/// Phase 1 — Tap down   (80ms):  scale 0.92
/// Phase 2 — Release    (150ms): scale 1.0, icon swaps
/// Phase 3 — Burst      (250ms): 6-dot particle ring in primary coral (liking only)
/// Phase 4 — Count      (200ms): count slides up via AnimatedSwitcher
class LikeButton extends ConsumerStatefulWidget {
  const LikeButton({super.key, required this.post});

  final Post post;

  @override
  ConsumerState<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<LikeButton>
    with TickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final AnimationController _burstCtrl;

  late final Animation<double> _scale;
  late final Animation<double> _burstAnim;

  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();

    _pressCtrl = AnimationController(vsync: this, value: 1.0);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );

    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _burstAnim = CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(LikeButton old) {
    super.didUpdateWidget(old);
    if (!old.post.isLikedByMe && widget.post.isLikedByMe) {
      _burstCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    _burstCtrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_isAnimating) return;
    _isAnimating = true;

    await _pressCtrl.animateTo(
      0.0,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
    );

    ref.read(feedNotifierProvider.notifier).toggleLike(widget.post);
    await _pressCtrl.animateTo(
      1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );

    _isAnimating = false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLiked = widget.post.isLikedByMe;

    return Semantics(
      label: isLiked ? 'Unlike post' : 'Like post',
      button: true,
      child: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _burstAnim,
                      builder: (_, _) => _ParticleBurst(
                        progress: _burstAnim.value,
                        color: cs.primary,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeOut,
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                        key: ValueKey(isLiked),
                        color: isLiked ? cs.primary : cs.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              ClipRect(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Text(
                    '${widget.post.likesCount}',
                    key: ValueKey(widget.post.likesCount),
                    style: AppTextStyles.label.copyWith(
                      color: isLiked ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 6-dot particle ring expanding from center in primary coral.
class _ParticleBurst extends StatelessWidget {
  const _ParticleBurst({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: progress > 0
          ? CustomPaint(painter: _ParticlePainter(progress: progress, color: color))
          : null,
    );
  }
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const count = 6;
    const maxRadius = 15.0;
    const dotRadius = 2.5;
    final center = Offset(size.width / 2, size.height / 2);

    final paint = Paint()
      ..color = color.withValues(alpha: 1.0 - progress)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi - math.pi / 2;
      final dist = maxRadius * progress;
      final pos = center + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
      final radius = dotRadius * (1 - progress * 0.6);
      canvas.drawCircle(pos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

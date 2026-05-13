import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../providers/follow_notifier.dart';

class FollowButton extends ConsumerWidget {
  const FollowButton({
    super.key,
    required this.targetUserId,
    this.width = double.infinity,
  });

  final String targetUserId;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final map = ref.watch(followNotifierProvider);
    final followState = map[targetUserId] ?? const FollowChecking();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(followNotifierProvider.notifier).load(targetUserId);
    });

    final cs = Theme.of(context).colorScheme;
    final isFollowing = followState is FollowLoaded && followState.isFollowing;
    final isLoading = followState is FollowChecking;

    final bg = isFollowing ? cs.surfaceContainerHighest : cs.primary;
    final labelColor = isFollowing ? cs.onSurfaceVariant : Colors.white;

    return Semantics(
      label: isFollowing ? 'Unfollow' : 'Follow',
      button: true,
      child: GestureDetector(
        onTap: followState is FollowLoaded
            ? () => ref.read(followNotifierProvider.notifier).toggle(targetUserId)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: width,
          height: 44,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
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
    );
  }
}

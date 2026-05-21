import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/post.dart';
import '../providers/repost_notifier.dart';

class RepostButton extends ConsumerStatefulWidget {
  const RepostButton({super.key, required this.post});

  final Post post;

  @override
  ConsumerState<RepostButton> createState() => _RepostButtonState();
}

class _RepostButtonState extends ConsumerState<RepostButton> {
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(repostNotifierProvider.notifier).ensureLoaded(
            widget.post.id,
            seedCount: widget.post.repostsCount,
            seedIsReposted: widget.post.isRepostedByMe,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final repostState = ref.watch(
      repostNotifierProvider.select((map) => map[widget.post.id]),
    );

    final isReposted = repostState is RepostLoaded
        ? repostState.isRepostedByMe
        : widget.post.isRepostedByMe;
    final count = repostState is RepostLoaded
        ? repostState.count
        : widget.post.repostsCount;

    return GestureDetector(
      onTap: () =>
          ref.read(repostNotifierProvider.notifier).toggleRepost(widget.post.id),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isReposted
                  ? Icons.repeat_rounded
                  : Icons.repeat_outlined,
              size: 20,
              color: isReposted ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: AppTextStyles.label.copyWith(
                color: isReposted ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

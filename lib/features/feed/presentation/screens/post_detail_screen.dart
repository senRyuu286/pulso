import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/data/providers/auth_providers.dart';
import '../../../comments/presentation/providers/comment_notifier.dart';
import '../../../comments/presentation/widgets/comment_card.dart';
import '../../data/providers/feed_providers.dart';
import '../../domain/models/post.dart';
import '../providers/repost_notifier.dart';
import '../widgets/like_button.dart';
import '../widgets/repost_button.dart';

// Provider that fetches a post by ID (used when navigating from notifications)
final _postDetailProvider = FutureProvider.family<Post, String>(
  (ref, postId) => ref.read(feedRepositoryProvider).fetchPostById(postId),
);

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.postId,
    this.initialPost,
  });

  final String postId;
  final Post? initialPost;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _sending = false;
  bool _requestedLoad = false;
  late final CommentNotifier _commentNotifier;

  @override
  void initState() {
    super.initState();
    _commentNotifier = ref.read(commentNotifierProvider.notifier);
  }

  @override
  void dispose() {
    _commentController.dispose();
    final postId = widget.postId;
    super.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _commentNotifier.clear(postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // If we have an initial post, use it; otherwise load from network
    final postAsync = widget.initialPost != null
        ? AsyncData<Post>(widget.initialPost!)
        : ref.watch(_postDetailProvider(widget.postId));

    return Scaffold(
      body: postAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: cs.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Unable to load post.',
                  style: AppTextStyles.body.copyWith(color: cs.onSurfaceVariant)),
              TextButton(
                onPressed: () => ref.refresh(_postDetailProvider(widget.postId)),
                child: Text('Retry',
                    style: AppTextStyles.label.copyWith(color: cs.primary)),
              ),
            ],
          ),
        ),
        data: (post) => _PostDetailBody(
          post: post,
          commentController: _commentController,
          sending: _sending,
          requestedLoad: _requestedLoad,
          onLoadRequested: () => setState(() => _requestedLoad = true),
          onSend: _submit,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_sending) return;
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    await ref
        .read(commentNotifierProvider.notifier)
        .addComment(postId: widget.postId, content: text);
    if (!mounted) return;
    _commentController.clear();
    setState(() => _sending = false);
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _PostDetailBody extends ConsumerStatefulWidget {
  const _PostDetailBody({
    required this.post,
    required this.commentController,
    required this.sending,
    required this.requestedLoad,
    required this.onLoadRequested,
    required this.onSend,
  });

  final Post post;
  final TextEditingController commentController;
  final bool sending;
  final bool requestedLoad;
  final VoidCallback onLoadRequested;
  final VoidCallback onSend;

  @override
  ConsumerState<_PostDetailBody> createState() => _PostDetailBodyState();
}

class _PostDetailBodyState extends ConsumerState<_PostDetailBody> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.requestedLoad) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onLoadRequested();
      ref.read(commentNotifierProvider.notifier).ensureLoaded(widget.post.id);
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
    final commentState = ref.watch(
      commentNotifierProvider
          .select((map) => map[widget.post.id] ?? const CommentInitial()),
    );
    final commentCount = ref.watch(
      commentCountNotifierProvider.select((map) => map[widget.post.id] ?? 0),
    );
    final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    final canSubmit = (currentUserId ?? '').isNotEmpty && !widget.sending;

    return SafeArea(
      child: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────────────
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: cs.onSurface),
              ),
              Text('Post',
                  style: AppTextStyles.title.copyWith(color: cs.onSurface)),
            ],
          ),
          // ── Scrollable content ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              children: [
                // Full image
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: widget.post.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Caption
                if (widget.post.caption != null &&
                    widget.post.caption!.isNotEmpty) ...[
                  Text(
                    widget.post.caption!,
                    style: AppTextStyles.body.copyWith(color: cs.onSurface),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action row: like · comment count · repost
                Row(
                  children: [
                    LikeButton(post: widget.post),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 20, color: cs.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text('$commentCount',
                            style: AppTextStyles.label
                                .copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    RepostButton(post: widget.post),
                  ],
                ),
                const SizedBox(height: 16),

                Divider(color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
                const SizedBox(height: 4),

                // Comments list
                CommentsSection(
                  post: widget.post,
                  commentState: commentState,
                  currentUserId: currentUserId,
                ),
              ],
            ),
          ),

          // ── Comment input ─────────────────────────────────────────────────
          Divider(color: cs.onSurfaceVariant.withValues(alpha: 0.2), height: 1),
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: widget.commentController,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => canSubmit ? widget.onSend() : null,
                        style: AppTextStyles.body.copyWith(color: cs.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: AppTextStyles.body
                              .copyWith(color: cs.onSurfaceVariant),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: canSubmit ? widget.onSend : null,
                    icon: Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: canSubmit ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CommentsSection extends ConsumerWidget {
  const CommentsSection({
    super.key,
    required this.post,
    required this.commentState,
    required this.currentUserId,
  });

  final Post post;
  final CommentState commentState;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return switch (commentState) {
      CommentInitial() || CommentLoading() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator(color: cs.primary)),
        ),
      CommentError() => Center(
          child: Text('Unable to load comments.',
              style: AppTextStyles.body.copyWith(color: cs.onSurfaceVariant)),
        ),
      CommentLoaded(:final comments) when comments.isEmpty => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text('Be the first to comment.',
                style:
                    AppTextStyles.body.copyWith(color: cs.onSurfaceVariant)),
          ),
        ),
      CommentLoaded(:final comments) => Column(
          children: comments
              .map(
                (comment) => CommentCard(
                  comment: comment,
                  onLikeTap: (currentUserId ?? '').isNotEmpty
                      ? () => ref
                          .read(commentNotifierProvider.notifier)
                          .toggleCommentLike(
                              postId: post.id, comment: comment)
                      : null,
                  onDeleteTap: currentUserId != null &&
                          (currentUserId == comment.userId ||
                              currentUserId == post.userId)
                      ? () => ref
                          .read(commentNotifierProvider.notifier)
                          .deleteComment(
                              postId: post.id, commentId: comment.id)
                      : null,
                ),
              )
              .toList(),
        ),
    };
  }
}

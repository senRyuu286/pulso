import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pulso_theme_extension.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../auth/data/providers/auth_providers.dart';
import '../../../feed/domain/models/post.dart';
import '../providers/comment_notifier.dart';
import 'comment_card.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({super.key, required this.post});

  final Post post;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _controller = TextEditingController();
  bool _sending = false;
  late final CommentNotifier _notifier;
  late final CommentCountNotifier _countNotifier;
  bool _requestedLoad = false;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(commentNotifierProvider.notifier);
    _countNotifier = ref.read(commentCountNotifierProvider.notifier);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedLoad) return;
    _requestedLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifier.ensureLoaded(widget.post.id);
      _countNotifier.ensureLoaded(widget.post.id);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier.clear(widget.post.id);
    });
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    await _notifier.addComment(postId: widget.post.id, content: text);
    if (!mounted) return;
    _controller.clear();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pulso = context.pulso;
    final state = ref.watch(
      commentNotifierProvider
          .select((map) => map[widget.post.id] ?? const CommentInitial()),
    );
    final commentCount = ref.watch(
      commentCountNotifierProvider
          .select((map) => map[widget.post.id] ?? 0),
    );
    final currentUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final canSubmit = (currentUserId ?? '').isNotEmpty && !_sending;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Comments ($commentCount)',
                  style: AppTextStyles.title.copyWith(color: cs.onSurface),
                ),
                const SizedBox(height: 8),
                Divider(color: cs.onSurfaceVariant.withValues(alpha: 0.2), height: 1),
                Expanded(child: _buildBody(state, currentUserId)),
                Divider(color: cs.onSurfaceVariant.withValues(alpha: 0.2), height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: NeumorphicContainer(
                          state: NeumorphicState.inset,
                          borderRadius: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 3,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => canSubmit ? _submit() : null,
                            style: AppTextStyles.body.copyWith(color: cs.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: AppTextStyles.body.copyWith(
                                color: pulso.textPlaceholder,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      NeumorphicButton(
                        onPressed: canSubmit ? _submit : null,
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.send_rounded,
                          size: 18,
                          color: canSubmit ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(CommentState state, String? currentUserId) {
    final cs = Theme.of(context).colorScheme;
    return switch (state) {
      CommentInitial() || CommentLoading() => Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
      CommentError(:final exception) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  exception.message,
                  style: AppTextStyles.body.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                NeumorphicButton(
                  onPressed: () => _notifier.loadComments(widget.post.id),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text(
                    'Retry',
                    style: AppTextStyles.label.copyWith(color: cs.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      CommentLoaded(:final comments) when comments.isEmpty => Center(
          child: Text(
            'Be the first to comment.',
            style: AppTextStyles.body.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        CommentLoaded(:final comments) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          itemCount: comments.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final comment = comments[index];
            final canDelete = currentUserId != null &&
                (currentUserId == comment.userId ||
                    currentUserId == widget.post.userId);

            return CommentCard(
              comment: comment,
              onDeleteTap: canDelete
              ? () => _notifier.deleteComment(
                        postId: widget.post.id,
                        commentId: comment.id,
                      )
                  : null,
            );
          },
        ),
    };
  }
}

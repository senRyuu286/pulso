import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pulso_theme_extension.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../providers/feed_notifier.dart';
import '../widgets/image_picker_field.dart';

/// Post creation screen — design spec section 9.
///
/// Inset neumorphic image zone, caption field, primary full-width "Post" button.
class PostCreationScreen extends ConsumerStatefulWidget {
  const PostCreationScreen({super.key});

  @override
  ConsumerState<PostCreationScreen> createState() => _PostCreationScreenState();
}

class _PostCreationScreenState extends ConsumerState<PostCreationScreen> {
  File? _image;
  final _captionCtrl = TextEditingController();

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pulso = context.pulso;
    final creationState = ref.watch(postCreationNotifierProvider);
    final isLoading = creationState is PostCreationLoading;

    ref.listen(postCreationNotifierProvider, (prev, next) {
      if (next is PostCreationSuccess) {
        ref.read(postCreationNotifierProvider.notifier).reset();
        if (context.mounted) context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'New Post',
          style: AppTextStyles.title.copyWith(color: cs.onSurface),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImagePickerField(
              selectedImage: _image,
              onImageSelected: (f) => setState(() => _image = f),
            ),
            const SizedBox(height: 20),

            NeumorphicContainer(
              state: NeumorphicState.inset,
              borderRadius: 12,
              child: TextField(
                controller: _captionCtrl,
                maxLines: 4,
                minLines: 2,
                style: AppTextStyles.body.copyWith(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Write a caption…',
                  hintStyle: AppTextStyles.body.copyWith(color: pulso.textPlaceholder),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  fillColor: Colors.transparent,
                  filled: true,
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (creationState is PostCreationError) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  creationState.exception.message,
                  style: AppTextStyles.caption.copyWith(color: cs.error),
                ),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 16),

            _PostButton(
              isLoading: isLoading,
              enabled: _image != null && !isLoading,
              onTap: isLoading || _image == null
                  ? null
                  : () => ref.read(postCreationNotifierProvider.notifier).submit(
                        image: _image!,
                        caption: _captionCtrl.text.trim().isEmpty
                            ? null
                            : _captionCtrl.text.trim(),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostButton extends StatelessWidget {
  const _PostButton({
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  final bool isLoading;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return NeumorphicButton(
      borderRadius: 12,
      padding: EdgeInsets.zero,
      width: double.infinity,
      height: 52,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: enabled ? cs.primary : cs.primary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                'Post',
                style: AppTextStyles.title.copyWith(color: Colors.white),
              ),
      ),
    );
  }
}

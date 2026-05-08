import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/neumorphic_container.dart';

/// Inset neumorphic image drop-zone — design spec section 9.
///
/// Empty state: dashed primary-muted border, camera icon centered.
/// Filled state: shows the selected image with a replace overlay on tap.
class ImagePickerField extends StatefulWidget {
  const ImagePickerField({
    super.key,
    required this.onImageSelected,
    this.selectedImage,
  });

  final ValueChanged<File> onImageSelected;
  final File? selectedImage;

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  final _picker = ImagePicker();

  Future<void> _pick() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1440,
    );
    if (picked != null) {
      widget.onImageSelected(File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryMuted = isDark ? AppColors.primaryMutedD : AppColors.primaryMutedL;
    final textSecondary = isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL;
    final primary = isDark ? AppColors.primaryD : AppColors.primaryL;

    return GestureDetector(
      onTap: _pick,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: widget.selectedImage != null
            ? _FilledZone(image: widget.selectedImage!, primaryMuted: primaryMuted)
            : _EmptyZone(
                primaryMuted: primaryMuted,
                textSecondary: textSecondary,
                primary: primary,
              ),
      ),
    );
  }
}

class _EmptyZone extends StatelessWidget {
  const _EmptyZone({
    required this.primaryMuted,
    required this.textSecondary,
    required this.primary,
  });

  final Color primaryMuted;
  final Color textSecondary;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      state: NeumorphicState.inset,
      borderRadius: 20,
      child: Stack(
        children: [
          // Dashed border overlay
          CustomPaint(
            painter: _DashedBorderPainter(color: primaryMuted, radius: 20),
            child: const SizedBox.expand(),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt_outlined, size: 40, color: primaryMuted),
                const SizedBox(height: 12),
                Text(
                  'Tap to add a photo',
                  style: AppTextStyles.label.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilledZone extends StatelessWidget {
  const _FilledZone({required this.image, required this.primaryMuted});

  final File image;
  final Color primaryMuted;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(image, fit: BoxFit.cover),
          // Tap-to-replace overlay
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryMuted.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Change',
                style: AppTextStyles.caption.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 5.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

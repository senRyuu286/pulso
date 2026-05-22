import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pulso_theme_extension.dart';
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
    if (picked != null) widget.onImageSelected(File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pulso = context.pulso;

    return GestureDetector(
      onTap: _pick,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: widget.selectedImage != null
            ? _FilledZone(image: widget.selectedImage!, primaryMuted: pulso.primaryMuted)
            : _EmptyZone(primaryMuted: pulso.primaryMuted, textSecondary: cs.onSurfaceVariant),
      ),
    );
  }
}

class _EmptyZone extends StatelessWidget {
  const _EmptyZone({required this.primaryMuted, required this.textSecondary});

  final Color primaryMuted;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
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

/// Dashed rounded-rectangle border.
///
/// Segments are computed once on first [paint] for a given [Size] and cached —
/// [computeMetrics] + [extractPath] are NOT called on every animation frame.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dashWidth = 8.0;
  static const double _dashGap   = 5.0;
  static const double _strokeW   = 1.5;

  Size? _cachedSize;
  List<Path>? _segments;
  late Paint _paint;

  void _rebuild(Size size) {
    _cachedSize = size;
    _paint = Paint()
      ..color = color
      ..strokeWidth = _strokeW
      ..style = PaintingStyle.stroke;

    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        Radius.circular(radius),
      ));

    final segments = <Path>[];
    for (final metric in outline.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        segments.add(metric.extractPath(d, d + _dashWidth));
        d += _dashWidth + _dashGap;
      }
    }
    _segments = segments;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedSize != size) _rebuild(size);
    for (final seg in _segments!) {
      canvas.drawPath(seg, _paint);
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

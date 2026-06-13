import 'package:flutter/material.dart';

import '../models/pending_bounty_image.dart';
import '../services/bounty_image_service.dart';
import '../theme/app_theme.dart';

class BountyImagePicker extends StatelessWidget {
  final List<String> existingUrls;
  final List<PendingBountyImage> pendingImages;
  final VoidCallback onPick;
  final ValueChanged<String> onRemoveExisting;
  final ValueChanged<int> onRemovePending;
  final bool enabled;

  const BountyImagePicker({
    super.key,
    required this.existingUrls,
    required this.pendingImages,
    required this.onPick,
    required this.onRemoveExisting,
    required this.onRemovePending,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final count = existingUrls.length + pendingImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image_outlined, color: colors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'CODE SCREENSHOTS',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$count/$maxBountyImages',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'JPG, PNG, WebP, GIF or BMP. Maximum 5 MB per image.',
          style: TextStyle(color: colors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final url in existingUrls)
              _ImagePreview(
                image: NetworkImage(url),
                onRemove: enabled ? () => onRemoveExisting(url) : null,
              ),
            for (var index = 0; index < pendingImages.length; index++)
              _ImagePreview(
                image: MemoryImage(pendingImages[index].bytes),
                onRemove: enabled ? () => onRemovePending(index) : null,
              ),
            if (enabled && count < maxBountyImages)
              OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('UPLOAD'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  minimumSize: const Size(132, 92),
                  side: BorderSide(color: colors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final ImageProvider image;
  final VoidCallback? onRemove;

  const _ImagePreview({required this.image, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SizedBox(
      width: 108,
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border, width: 1.5),
              ),
              child: Image(image: image, fit: BoxFit.cover),
            ),
          ),
          if (onRemove != null)
            Positioned(
              right: -7,
              top: -7,
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: colors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 2),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

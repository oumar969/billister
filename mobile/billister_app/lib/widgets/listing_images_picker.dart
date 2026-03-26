import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// A widget that lets the user pick multiple images from camera or gallery,
/// reorder them by dragging, and delete individual images.
///
/// Compression is applied via [imageQuality] + [maxWidth]/[maxHeight] in the
/// [ImagePicker] call, so no additional compress package is needed.
class ListingImagesPicker extends StatelessWidget {
  final List<XFile> images;
  final ValueChanged<List<XFile>> onChanged;
  final bool enabled;

  static const int _maxImages = 10;

  // Compress to ≤ 1280 px on the longer side and 80 % JPEG quality.
  static const int _imageQuality = 80;
  static const double _maxDimension = 1280;

  const ListingImagesPicker({
    super.key,
    required this.images,
    required this.onChanged,
    this.enabled = true,
  });

  // ── Picking ──────────────────────────────────────────────────────────────

  Future<void> _pickFromCamera(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: _imageQuality,
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
    );
    if (file == null) return;
    onChanged([...images, file]);
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final remaining = _maxImages - images.length;
    if (remaining <= 0) return;

    final picker = ImagePicker();
    final List<XFile> files = await picker.pickMultiImage(
      imageQuality: _imageQuality,
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      limit: remaining,
    );
    if (files.isEmpty) return;
    onChanged([...images, ...files]);
  }

  void _showPickerSheet(BuildContext context) {
    if (images.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maks. 10 billeder tilladt')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tag billede'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickFromCamera(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Vælg fra galleri'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickFromGallery(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Reorder / delete ──────────────────────────────────────────────────────

  void _removeImage(int index) {
    final updated = [...images]..removeAt(index);
    onChanged(updated);
  }

  void _reorder(int oldIndex, int newIndex) {
    final updated = [...images];
    if (newIndex > oldIndex) newIndex--;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    onChanged(updated);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Billeder', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(width: 6),
            Text(
              '(${images.length}/$_maxImages)',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (images.isEmpty)
          OutlinedButton.icon(
            onPressed: enabled ? () => _showPickerSheet(context) : null,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Tilføj billeder'),
          )
        else ...[
          SizedBox(
            height: 120,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              onReorder: enabled ? _reorder : (_, __) {},
              itemCount: images.length,
              itemBuilder: (context, index) {
                return ReorderableDragStartListener(
                  key: ValueKey(images[index].path),
                  index: index,
                  enabled: enabled,
                  child: _ImageThumbnail(
                    file: images[index],
                    isFirst: index == 0,
                    enabled: enabled,
                    onDelete: () => _removeImage(index),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (images.length < _maxImages)
                TextButton.icon(
                  onPressed: enabled ? () => _showPickerSheet(context) : null,
                  icon: const Icon(Icons.add_photo_alternate, size: 18),
                  label: const Text('Tilføj billede'),
                ),
              const Spacer(),
              Text(
                'Træk for at sortere',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Thumbnail ───────────────────────────────────────────────────────────────

class _ImageThumbnail extends StatelessWidget {
  final XFile file;
  final bool isFirst;
  final bool enabled;
  final VoidCallback onDelete;

  const _ImageThumbnail({
    required this.file,
    required this.isFirst,
    required this.enabled,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(file.path),
              width: 100,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          if (isFirst)
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Forside',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ),
          if (enabled)
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

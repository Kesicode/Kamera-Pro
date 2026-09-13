/// Gallery screen — shows all captured photos with metadata.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../gallery/gallery_repository.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoAsync = ref.watch(galleryRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Gallery',
            style: TextStyle(fontFamily: 'SpaceMono', fontSize: 16)),
        backgroundColor: const Color(0xFF0A0A0A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: repoAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFE8C547)),
        ),
        error: (e, _) => Center(
          child: Text('Gallery unavailable\n$e',
              style: const TextStyle(color: Colors.white54, fontFamily: 'SpaceMono'),
              textAlign: TextAlign.center),
        ),
        data: (repo) {
          final items = repo.getAll();
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined,
                      color: Colors.white24, size: 48),
                  SizedBox(height: 12),
                  Text('No photos yet',
                      style: TextStyle(
                        color: Colors.white38,
                        fontFamily: 'SpaceMono',
                        fontSize: 14,
                      )),
                  SizedBox(height: 6),
                  Text('Tap the shutter button to take your first photo',
                      style: TextStyle(
                        color: Colors.white24,
                        fontFamily: 'SpaceMono',
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final meta = items[i];
              return GestureDetector(
                onTap: () => _showDetail(context, meta),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail
                    Image.asset(
                      meta.filePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1A1A1A),
                        child: const Icon(Icons.broken_image_outlined,
                            color: Colors.white24),
                      ),
                    ),
                    // AI badge
                    if (meta.aiGenerated)
                      Positioned(
                        top: 4, right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8C547),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('AI',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, dynamic meta) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (meta.rawCommand != null)
              Text('"${meta.rawCommand}"',
                  style: const TextStyle(
                    color: Color(0xFFE8C547),
                    fontFamily: 'SpaceMono',
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  )),
            const SizedBox(height: 12),
            _infoRow('ISO', meta.iso != null ? '${meta.iso}' : '—'),
            _infoRow('Shutter', meta.shutterLabel ?? '—'),
            _infoRow('WB', meta.whiteBalanceK != null ? '${meta.whiteBalanceK}K' : '—'),
            _infoRow('Zoom', meta.zoom != null ? '${meta.zoom!.toStringAsFixed(1)}x' : '—'),
            if (meta.educationalExplanation != null) ...[
              const SizedBox(height: 12),
              Text(meta.educationalExplanation!,
                  style: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    height: 1.6,
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontFamily: 'SpaceMono',
                  fontSize: 11,
                )),
          ),
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'SpaceMono',
                fontSize: 11,
              )),
        ],
      ),
    );
  }
}

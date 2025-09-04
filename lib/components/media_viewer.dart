// components/media_viewer.dart
import 'package:flutter/material.dart';
import '../models/incident_comment.dart';

class MediaViewer extends StatelessWidget {
  final List<CommentMedia> media;
  final bool isExpanded;

  const MediaViewer({super.key, required this.media, this.isExpanded = false});

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (media.length == 1) _buildSingleMedia(media.first),
        if (media.length > 1) _buildMediaGrid(media),
      ],
    );
  }

  //
  Widget _buildSingleMedia(CommentMedia mediaItem) {
    switch (mediaItem.type) {
      case MediaType.image:
        return Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              mediaItem.url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Icon(Icons.error_outline),
              ),
            ),
          ),
        );
      case MediaType.video:
        return Container(
          margin: const EdgeInsets.only(top: 8),
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // For a real app, you'd use a video player here
              // This is a placeholder
              Center(
                child: Icon(
                  Icons.play_circle_filled,
                  color: Colors.white.withOpacity(0.7),
                  size: 50,
                ),
              ),
              if (mediaItem.caption != null)
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    mediaItem.caption!,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMediaGrid(List<CommentMedia> media) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: media.length > 2 ? 2 : media.length,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final mediaItem = media[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: mediaItem.type == MediaType.image
                ? Image.network(mediaItem.url, fit: BoxFit.cover)
                : Stack(
                    children: [
                      // Placeholder for video thumbnail
                      Container(color: Colors.black),
                      const Center(
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

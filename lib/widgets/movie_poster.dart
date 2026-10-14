import 'package:flutter/material.dart';
import '../models/movie.dart';

class MoviePosterWidget extends StatelessWidget {
  final Movie movie;
  final double width;
  final double height;
  final double borderRadius;

  const MoviePosterWidget({
    super.key,
    required this.movie,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMissingImage = movie.posterUrl.isEmpty || movie.posterUrl.contains('unsplash');

    if (isMissingImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _buildDefaultNoImageIcon(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        movie.posterUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultNoImageIcon();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildDefaultNoImageIcon();
        },
      ),
    );
  }

  Widget _buildDefaultNoImageIcon() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
      ),
      padding: const EdgeInsets.all(6),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.movie_creation_outlined,
                    size: height > 100 ? 34 : 22,
                    color: Colors.white38,
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: height > 100 ? 38 : 24,
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.white54,
                          borderRadius: BorderRadius.circular(1),
                        ),
                        transform: Matrix4.rotationZ(-0.65),
                        transformAlignment: Alignment.center,
                      ),
                    ),
                  ),
                ],
              ),
              if (height > 60) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    movie.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: height > 100 ? 11 : 9,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

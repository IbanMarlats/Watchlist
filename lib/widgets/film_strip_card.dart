import 'package:flutter/material.dart';
import '../models/movie.dart';

class FilmStripCard extends StatelessWidget {
  final Movie movie;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onStatusTap;
  final double width;
  final double height;

  const FilmStripCard({
    super.key,
    required this.movie,
    required this.index,
    required this.onTap,
    this.onStatusTap,
    this.width = 150,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    final isWatched = movie.status == 'completed';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [

            Image.network(
              movie.posterUrl,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                color: const Color(0xFF1B1B26),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.movie_outlined, color: Colors.grey, size: 36),
                    SizedBox(height: 4),
                    Text('Affiche indisponible', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            ),

            if (onStatusTap != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onStatusTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isWatched
                          ? Colors.black.withValues(alpha: 0.8)
                          : Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isWatched ? Colors.white : Colors.white38,
                        width: isWatched ? 2.0 : 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.movie_rounded,
                      color: isWatched ? Colors.white : Colors.white60,
                      size: 15,
                    ),
                  ),
                ),
              ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.95),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${movie.year} • ${movie.duration}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

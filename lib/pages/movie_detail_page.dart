import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../widgets/movie_poster.dart';

class MovieDetailPage extends StatefulWidget {
  final Movie movie;
  final Function(Movie movie, String newStatus) onStatusChanged;
  final Function(Movie movie, String notes)? onSaveNotes;
  final VoidCallback onBack;
  final VoidCallback onOpenSettings;
  final String tmdbApiKey;

  const MovieDetailPage({
    super.key,
    required this.movie,
    required this.onStatusChanged,
    this.onSaveNotes,
    required this.onBack,
    required this.onOpenSettings,
    this.tmdbApiKey = '',
  });

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  late Movie _currentMovie;

  @override
  void initState() {
    super.initState();
    _currentMovie = widget.movie;
    _loadMovieDetailsIfNeeded();
  }

  @override
  void didUpdateWidget(covariant MovieDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.movie != oldWidget.movie) {
      setState(() {
        _currentMovie = widget.movie;
      });
    }
  }

  Future<void> _loadMovieDetailsIfNeeded() async {
    if (widget.tmdbApiKey.isNotEmpty && _currentMovie.id.startsWith('tmdb-')) {
      final rawId = int.tryParse(_currentMovie.id.replaceAll('tmdb-', '')) ?? 0;
      if (rawId > 0) {
        final fullMovie = await TmdbService.getMovieDetails(widget.tmdbApiKey, rawId);
        if (fullMovie != null && mounted) {
          setState(() {
            _currentMovie = fullMovie.copyWith(
              status: _currentMovie.status,
              userNotes: _currentMovie.userNotes,
            );
          });
        }
      }
    }
  }

  void _changeStatus(String newStatus) {
    setState(() {
      _currentMovie = _currentMovie.copyWith(status: newStatus);
    });
    widget.onStatusChanged(_currentMovie, newStatus);
  }

  Widget _buildDefaultBackdrop(Movie movie) {
    return Container(
      color: const Color(0xFF0F1017),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Icon(
                Icons.movie_rounded,
                size: 240,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_movies_rounded,
                size: 44,
                color: Colors.white38,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  movie.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = _currentMovie;
    final bool hasValidBackdrop = movie.backdropUrl.isNotEmpty && !movie.backdropUrl.contains('unsplash');

    return Scaffold(
      backgroundColor: const Color(0xFF12121D),
      body: CustomScrollView(
        slivers: [

          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: widget.onBack,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    onPressed: widget.onOpenSettings,
                    tooltip: 'Paramètres',
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasValidBackdrop)
                    Image.network(
                      movie.backdropUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => _buildDefaultBackdrop(movie),
                    )
                  else
                    _buildDefaultBackdrop(movie),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.5),
                          const Color(0xFF12121D),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MoviePosterWidget(
                        movie: movie,
                        width: 100,
                        height: 150,
                        borderRadius: 14,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            if (movie.originalTitle != movie.title) ...[
                              const SizedBox(height: 4),
                              Text(
                                movie.originalTitle,
                                style: TextStyle(color: Colors.grey[400], fontSize: 13, fontStyle: FontStyle.italic),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              '${movie.year} • ${movie.duration}',
                              style: TextStyle(color: Colors.grey[400], fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: movie.genres.map((genre) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    genre,
                                    style: TextStyle(color: Colors.grey[300], fontSize: 11),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Statut du film',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildStatusOptionButton(
                              context,
                              id: 'watch_later',
                              label: '⏳ À voir',
                              icon: Icons.bookmark_border_rounded,
                              color: Colors.white,
                              movie: movie,
                            ),
                            const SizedBox(width: 12),
                            _buildStatusOptionButton(
                              context,
                              id: 'completed',
                              label: '🎬 Vu',
                              icon: Icons.check_circle_outline_rounded,
                              color: Colors.white,
                              movie: movie,
                            ),
                          ],
                        ),
                        if (movie.status != 'none') ...[
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: () => _changeStatus('none'),
                            icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.grey),
                            label: const Text('Définir comme "Pas vu"', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Disponible sur',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: movie.platforms.map((platform) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161722),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.tv_rounded, size: 16, color: Colors.white70),
                            const SizedBox(width: 8),
                            Text(
                              platform,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Synopsis',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.synopsis,
                    style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Équipe & Distribution',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('Réalisateur : ${movie.director}', style: TextStyle(color: Colors.grey[300], fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: movie.cast.map((actor) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(actor[0], style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        label: Text(actor, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        backgroundColor: const Color(0xFF1E1E2C),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOptionButton(
    BuildContext context, {
    required String id,
    required String label,
    required IconData icon,
    required Color color,
    required Movie movie,
  }) {
    final isSelected = movie.status == id;

    return Expanded(
      child: GestureDetector(
        onTap: () => _changeStatus(isSelected ? 'none' : id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.15) : const Color(0xFF161722),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[400], size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[300],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../widgets/movie_poster.dart';
import '../widgets/clapperboard_header.dart';
import '../widgets/film_strip_card.dart';
import '../widgets/film_reel_divider.dart';
import '../widgets/import_movies_modal.dart';

class HomePage extends StatefulWidget {
  final List<Movie> movies;
  final Function(Movie) onMovieSelected;
  final Function(Movie movie, String newStatus) onStatusChanged;
  final VoidCallback onOpenSettings;
  final Function(List<Movie> moviesToAdd)? onBatchAddMovies;
  final Future<void> Function()? onRefresh;
  final String tmdbApiKey;

  const HomePage({
    super.key,
    required this.movies,
    required this.onMovieSelected,
    required this.onStatusChanged,
    required this.onOpenSettings,
    this.onBatchAddMovies,
    this.onRefresh,
    this.tmdbApiKey = '',
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadSavedViewPreference();
  }

  Future<void> _loadSavedViewPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIsGrid = prefs.getBool('watchlist_view_is_grid');
      if (savedIsGrid != null && mounted) {
        setState(() {
          _isGridView = savedIsGrid;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleViewMode() async {
    final newValue = !_isGridView;
    setState(() {
      _isGridView = newValue;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('watchlist_view_is_grid', newValue);
    } catch (_) {}
  }

  void _openImportModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ImportMoviesModal(
        existingMovies: widget.movies,
        tmdbApiKey: widget.tmdbApiKey,
        onAddMovies: (moviesToAdd) {
          if (widget.onBatchAddMovies != null) {
            widget.onBatchAddMovies!(moviesToAdd);
          }
        },
        onMovieSelected: widget.onMovieSelected,
      ),
    );
  }

  Future<void> _showConfirmWatchedDialog(BuildContext context, Movie movie) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D0E15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.2),
          ),
          title: const Text(
            'Marquer comme vu ?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
          ),
          content: Text(
            movie.title,
            style: TextStyle(color: Colors.grey[300], fontSize: 14, fontWeight: FontWeight.w500),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Non', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.onStatusChanged(movie, 'completed');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎬 "${movie.title}" marqué Vu !'),
                    backgroundColor: const Color(0xFF161722),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Oui', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final now = DateTime(today.year, today.month, today.day);

    final allWatchLater = widget.movies.where((m) => m.status == 'watch_later').toList();

    final releasedMovies = allWatchLater.where((m) {
      if (m.releaseDate == null) return true;
      return !m.releaseDate!.isAfter(now);
    }).toList();

    final unreleasedMovies = allWatchLater.where((m) {
      if (m.releaseDate == null) return false;
      return m.releaseDate!.isAfter(now);
    }).toList();

    final watchLaterMovies = [...releasedMovies, ...unreleasedMovies];
    final count = watchLaterMovies.length;
    final countText = '$count film${count > 1 ? 's' : ''}';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: const Color(0xFF161722),
          onRefresh: () async {
            if (widget.onRefresh != null) {
              await widget.onRefresh!();
            } else {
              await Future.delayed(const Duration(milliseconds: 500));
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [

              SliverToBoxAdapter(
                child: ClapperboardHeader(
                  title: 'Watchlist',
                  subtitle: countText,
                  onOpenSettings: widget.onOpenSettings,
                  actions: [
                    IconButton(
                      onPressed: _toggleViewMode,
                      icon: Icon(
                        _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      tooltip: _isGridView ? 'Vue liste' : 'Vue grille',
                    ),
                    IconButton(
                      onPressed: () => _openImportModal(context),
                      icon: const Icon(
                        Icons.file_upload_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      tooltip: 'Importer une liste de films',
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(
                child: FilmReelDivider(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              if (watchLaterMovies.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.movie_filter_outlined, size: 64, color: Colors.grey[700]),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun film à voir dans votre liste',
                          style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ajoutez des films depuis l\'onglet Recherche !',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_isGridView)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      childAspectRatio: 0.64,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final movie = watchLaterMovies[index];
                        return FilmStripCard(
                          movie: movie,
                          index: index,
                          onTap: () => widget.onMovieSelected(movie),
                          onStatusTap: () => _showConfirmWatchedDialog(context, movie),
                        );
                      },
                      childCount: watchLaterMovies.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final movie = watchLaterMovies[index];
                        return _buildListCard(context, movie);
                      },
                      childCount: watchLaterMovies.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              const SliverToBoxAdapter(
                child: FilmReelDivider(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, Movie movie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141524),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => widget.onMovieSelected(movie),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MoviePosterWidget(
                    movie: movie,
                    width: 54,
                    height: 80,
                    borderRadius: 12,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${movie.year} • ${movie.duration}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: movie.genres.take(2).map((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              genre,
                              style: TextStyle(color: Colors.grey[300], fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showConfirmWatchedDialog(context, movie),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.movie_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../widgets/movie_poster.dart';
import '../widgets/clapperboard_header.dart';

class SearchPage extends StatefulWidget {
  final List<Movie> movies;
  final Function(Movie) onMovieSelected;
  final Function(Movie movie, String newStatus) onStatusChanged;
  final VoidCallback onOpenSettings;
  final String tmdbApiKey;

  const SearchPage({
    super.key,
    required this.movies,
    required this.onMovieSelected,
    required this.onStatusChanged,
    required this.onOpenSettings,
    this.tmdbApiKey = '',
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Movie> _apiResults = [];
  bool _isLoadingApi = false;
  DateTime _customReleaseDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPopularMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPopularMovies() async {
    if (widget.tmdbApiKey.isNotEmpty && _searchQuery.isEmpty) {
      setState(() => _isLoadingApi = true);
      final popular = await TmdbService.getPopularMovies(widget.tmdbApiKey);
      if (mounted && _searchQuery.isEmpty) {
        setState(() {
          _apiResults = popular;
          _isLoadingApi = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) async {
    setState(() {
      _searchQuery = query;
    });

    if (query.trim().isEmpty) {
      _loadPopularMovies();
      return;
    }

    if (widget.tmdbApiKey.isNotEmpty && query.trim().length >= 2) {
      setState(() => _isLoadingApi = true);
      final results = await TmdbService.searchMovies(widget.tmdbApiKey, query);
      if (mounted) {
        setState(() {
          _apiResults = results;
          _isLoadingApi = false;
        });
      }
    }
  }

  Future<void> _pickCustomReleaseDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customReleaseDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2035),
      locale: const Locale('fr', 'FR'),
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Color(0xFF161722),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0F1017)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _customReleaseDate = picked;
      });
    }
  }

  String _formatDateStr(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }

  void _addCustomMovieToWatchlist(String title) {
    final newMovie = Movie(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      originalTitle: title,
      posterUrl: '',
      backdropUrl: '',
      year: _customReleaseDate.year,
      duration: '2h 00m',
      genres: ['Cinéma'],
      director: 'Inconnu',
      cast: ['Casting Principal'],
      synopsis: 'Film ajouté manuellement depuis la recherche.',
      platforms: ['Au cinéma'],
      gradientColors: [const Color(0xFF161722), const Color(0xFF000000)],
      icon: Icons.movie_rounded,
      releaseDate: _customReleaseDate,
      status: 'watch_later',
    );

    widget.onStatusChanged(newMovie, 'watch_later');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🍿 "$title" (${_formatDateStr(_customReleaseDate)}) ajouté à la Watchlist !'),
        backgroundColor: const Color(0xFF161722),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildAddCustomMovieCard(BuildContext context) {
    final title = _searchQuery.trim();
    if (title.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.movie_creation_outlined, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ajouter "$title" manuellement',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 10,
            children: [
              InkWell(
                onTap: () => _pickCustomReleaseDate(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Date de sortie : ', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _formatDateStr(_customReleaseDate),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => _addCustomMovieToWatchlist(title),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.black),
                label: const Text(
                  'Ajouter',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
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
    final List<Movie> searchResults = [];

    if (_apiResults.isNotEmpty) {
      for (var apiMovie in _apiResults) {
        final existingIndex = widget.movies.indexWhere((m) =>
            m.id == apiMovie.id || m.title.toLowerCase() == apiMovie.title.toLowerCase());
        if (existingIndex != -1) {
          searchResults.add(widget.movies[existingIndex]);
        } else {
          searchResults.add(apiMovie);
        }
      }
    } else {
      searchResults.addAll(widget.movies.where((movie) {
        if (_searchQuery.trim().isEmpty) return true;

        final query = _searchQuery.toLowerCase().trim();
        return movie.title.toLowerCase().contains(query) ||
            movie.director.toLowerCase().contains(query) ||
            movie.cast.any((c) => c.toLowerCase().contains(query)) ||
            movie.genres.any((g) => g.toLowerCase().contains(query));
      }));
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            SliverToBoxAdapter(
              child: ClapperboardHeader(
                title: 'Recherche',
                onOpenSettings: widget.onOpenSettings,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      autofocus: false,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un titre...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                        suffixIcon: _isLoadingApi
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                ),
                              )
                            : (_searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null),
                        filled: true,
                        fillColor: const Color(0xFF1E1E2C),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (widget.tmdbApiKey.isEmpty)
                      GestureDetector(
                        onTap: widget.onOpenSettings,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.movie_filter_rounded, color: Colors.blueAccent, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Connecter l\'API TMDB 🎬',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Ajoutez votre clé TMDB gratuite dans Paramètres ⚙️ pour chercher parmi 1 000 000+ films !',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            searchResults.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: _searchQuery.trim().isEmpty
                            ? Text(
                                'Rechercher un film dans votre catalogue ou TMDB',
                                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                              )
                            : _buildAddCustomMovieCard(context),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < searchResults.length) {
                            final movie = searchResults[index];
                            return _buildSearchListItem(context, movie);
                          } else {
                            return _buildAddCustomMovieCard(context);
                          }
                        },
                        childCount: _searchQuery.trim().isNotEmpty
                            ? searchResults.length + 1
                            : searchResults.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchListItem(BuildContext context, Movie movie) {
    final isWatched = movie.status == 'completed';
    final isWatchLater = movie.status == 'watch_later';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          onTap: () => widget.onMovieSelected(movie),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: MoviePosterWidget(
              movie: movie,
              width: 50,
              height: 75,
              borderRadius: 8,
            ),
          ),
          title: Text(
            movie.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${movie.year} • ${movie.duration} • ${movie.genres.take(2).join(', ')}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
          trailing: _buildStatusBadge(context, movie, isWatched, isWatchLater),
        ),
      ),
    );
  }

  void _showFastStatusSelector(BuildContext context, Movie movie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0E15),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Définir le statut du film :',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildFastOption(
                      ctx: ctx,
                      movie: movie,
                      statusId: 'watch_later',
                      label: 'À voir',
                      icon: Icons.bookmark_added_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    _buildFastOption(
                      ctx: ctx,
                      movie: movie,
                      statusId: 'completed',
                      label: 'Vu',
                      icon: Icons.check_circle_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    _buildFastOption(
                      ctx: ctx,
                      movie: movie,
                      statusId: 'none',
                      label: 'Pas vu',
                      icon: Icons.remove_circle_outline_rounded,
                      color: Colors.grey[400]!,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFastOption({
    required BuildContext ctx,
    required Movie movie,
    required String statusId,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = movie.status == statusId;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.of(ctx).pop();
          widget.onStatusChanged(movie, statusId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎬 "${movie.title}" passé à "$label" !',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.15) : const Color(0xFF161722),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[400], size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[300],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Movie movie, bool isWatched, bool isWatchLater) {
    Color btnBg = Colors.white.withValues(alpha: 0.08);
    Color borderColor = Colors.white38;
    Color iconColor = Colors.white;
    IconData iconData = Icons.add_rounded;

    if (isWatched) {
      btnBg = Colors.black.withValues(alpha: 0.8);
      borderColor = Colors.white;
      iconColor = Colors.white;
      iconData = Icons.movie_rounded;
    } else if (isWatchLater) {
      btnBg = Colors.white.withValues(alpha: 0.18);
      borderColor = Colors.white.withValues(alpha: 0.6);
      iconColor = Colors.white;
      iconData = Icons.bookmark_added_rounded;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (movie.status == 'none') {
          widget.onStatusChanged(movie, 'watch_later');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎬 "${movie.title}" ajouté à la Watchlist !',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              backgroundColor: const Color(0xFF161722),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          widget.onStatusChanged(movie, 'none');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎬 "${movie.title}" retiré de la Watchlist',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              backgroundColor: const Color(0xFF161722),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onLongPress: () => _showFastStatusSelector(context, movie),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: btnBg,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Icon(
          iconData,
          color: iconColor,
          size: 18,
        ),
      ),
    );
  }
}


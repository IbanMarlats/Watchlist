import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import 'movie_poster.dart';

class ImportParsedItem {
  final String rawLine;
  final String cleanTitle;
  final int? targetYear;

  ImportParsedItem({
    required this.rawLine,
    required this.cleanTitle,
    this.targetYear,
  });
}

class ImportSearchResult {
  final ImportParsedItem item;
  final Movie? matchedMovie;
  final bool isAlreadyInWatchlist;
  bool isSelected;

  ImportSearchResult({
    required this.item,
    this.matchedMovie,
    this.isAlreadyInWatchlist = false,
    this.isSelected = true,
  });
}

enum ImportStep { input, loading, results }

class ImportMoviesModal extends StatefulWidget {
  final List<Movie> existingMovies;
  final String tmdbApiKey;
  final Function(List<Movie> moviesToAdd) onAddMovies;
  final Function(Movie movie) onMovieSelected;

  const ImportMoviesModal({
    super.key,
    required this.existingMovies,
    required this.tmdbApiKey,
    required this.onAddMovies,
    required this.onMovieSelected,
  });

  @override
  State<ImportMoviesModal> createState() => _ImportMoviesModalState();
}

class _ImportMoviesModalState extends State<ImportMoviesModal> {
  final TextEditingController _textController = TextEditingController();
  ImportStep _currentStep = ImportStep.input;

  int _totalToAnalyze = 0;
  int _currentIndexAnalyzed = 0;

  List<ImportSearchResult> _searchResults = [];
  List<String> _unfoundTitles = [];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  List<ImportParsedItem> _parseInputText(String rawText) {
    final lines = rawText.split(RegExp(r'\r?\n'));
    final List<ImportParsedItem> items = [];

    for (var line in lines) {
      String s = line.trim();
      if (s.isEmpty) continue;

      if (s.startsWith('#') || s.startsWith('//') || s.startsWith('---')) continue;

      s = s.replaceAll(RegExp(r'^(?:\d+[\.\)\-]?|[\-\*•\>\+])\s*'), '').trim();

      if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
        if (s.length >= 2) {
          s = s.substring(1, s.length - 1).trim();
        }
      }

      if (s.isEmpty) continue;

      int? extractedYear;
      final yearMatch = RegExp(r'^(.*?)\s*[\(\[\{](\d{4})[\)\]\}]\s*$').firstMatch(s);
      if (yearMatch != null) {
        s = yearMatch.group(1)?.trim() ?? s;
        extractedYear = int.tryParse(yearMatch.group(2) ?? '');
      }

      if (s.length >= 2) {
        items.add(ImportParsedItem(
          rawLine: line,
          cleanTitle: s,
          targetYear: extractedYear,
        ));
      }
    }
    return items;
  }

  Future<void> _startBatchAnalysis(List<ImportParsedItem> parsedItems) async {
    if (parsedItems.isEmpty) return;

    setState(() {
      _currentStep = ImportStep.loading;
      _totalToAnalyze = parsedItems.length;
      _currentIndexAnalyzed = 0;
      _searchResults = [];
      _unfoundTitles = [];
    });

    final List<ImportSearchResult> results = [];
    final List<String> unfound = [];

    for (int i = 0; i < parsedItems.length; i++) {
      final item = parsedItems[i];
      if (mounted) {
        setState(() {
          _currentIndexAnalyzed = i + 1;
        });
      }

      Movie? matchedMovie;

      if (widget.tmdbApiKey.isNotEmpty) {
        final tmdbMatches = await TmdbService.searchMovies(widget.tmdbApiKey, item.cleanTitle);
        if (tmdbMatches.isNotEmpty) {
          if (item.targetYear != null) {
            matchedMovie = tmdbMatches.firstWhere(
              (m) => m.year == item.targetYear || (m.releaseDate != null && m.releaseDate!.year == item.targetYear),
              orElse: () => tmdbMatches.first,
            );
          } else {
            matchedMovie = tmdbMatches.first;
          }
        }
      }

      if (matchedMovie == null) {
        final queryLower = item.cleanTitle.toLowerCase();
        final localMatch = widget.existingMovies.firstWhere(
          (m) => m.title.toLowerCase() == queryLower || m.title.toLowerCase().contains(queryLower),
          orElse: () => Movie(
            id: 'imported-${DateTime.now().millisecondsSinceEpoch}-$i',
            title: item.cleanTitle,
            originalTitle: item.cleanTitle,
            posterUrl: '',
            backdropUrl: '',
            year: item.targetYear ?? 2026,
            duration: '2h 00m',
            genres: ['Cinéma'],
            director: 'Inconnu',
            cast: ['Casting Principal'],
            synopsis: 'Importé depuis une liste de notes.',
            platforms: ['Au cinéma'],
            gradientColors: [const Color(0xFF161722), const Color(0xFF000000)],
            icon: Icons.movie_rounded,
            status: 'watch_later',
          ),
        );

        if (widget.existingMovies.any((m) => m.title.toLowerCase() == queryLower)) {
          matchedMovie = localMatch;
        } else if (item.cleanTitle.length >= 2) {
          matchedMovie = localMatch;
        }
      }

      if (matchedMovie != null) {

        final isAlreadyAdded = widget.existingMovies.any(
          (m) => (m.id == matchedMovie!.id || m.title.toLowerCase() == matchedMovie.title.toLowerCase()) && m.status != 'none',
        );

        results.add(ImportSearchResult(
          item: item,
          matchedMovie: matchedMovie,
          isAlreadyInWatchlist: isAlreadyAdded,
          isSelected: !isAlreadyAdded,
        ));
      } else {
        unfound.add(item.cleanTitle);
      }
    }

    if (mounted) {
      setState(() {
        _searchResults = results;
        _unfoundTitles = unfound;
        _currentStep = ImportStep.results;
      });
    }
  }

  void _executeBatchAdd() {
    final moviesToAdd = _searchResults
        .where((r) => r.isSelected && r.matchedMovie != null)
        .map((r) => r.matchedMovie!)
        .toList();

    if (moviesToAdd.isNotEmpty) {
      widget.onAddMovies(moviesToAdd);
    }
    Navigator.of(context).pop();
  }

  void _openReplaceSearchModal(ImportSearchResult res, {bool isUnfound = false, String? unfoundTitle}) {
    final initialQuery = isUnfound ? (unfoundTitle ?? '') : res.item.cleanTitle;

    showDialog(
      context: context,
      builder: (dialogCtx) => _ReplaceMovieSearchModal(
        initialQuery: initialQuery,
        tmdbApiKey: widget.tmdbApiKey,
        existingMovies: widget.existingMovies,
        onMovieChosen: (newMovie) {
          setState(() {
            final isAlreadyAdded = widget.existingMovies.any(
              (m) => (m.id == newMovie.id || m.title.toLowerCase() == newMovie.title.toLowerCase()) && m.status != 'none',
            );

            if (isUnfound && unfoundTitle != null) {
              _unfoundTitles.remove(unfoundTitle);
              _searchResults.add(ImportSearchResult(
                item: ImportParsedItem(rawLine: unfoundTitle, cleanTitle: unfoundTitle),
                matchedMovie: newMovie,
                isAlreadyInWatchlist: isAlreadyAdded,
                isSelected: !isAlreadyAdded,
              ));
            } else {
              final idx = _searchResults.indexOf(res);
              if (idx != -1) {
                _searchResults[idx] = ImportSearchResult(
                  item: res.item,
                  matchedMovie: newMovie,
                  isAlreadyInWatchlist: isAlreadyAdded,
                  isSelected: !isAlreadyAdded,
                );
              }
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsedItems = _parseInputText(_textController.text);

    return Dialog(
      backgroundColor: const Color(0xFF0F1017),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Colors.white24, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 640),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Row(
                children: [
                  const Icon(Icons.playlist_add_rounded, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Importer une liste de films',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 16),

              if (_currentStep == ImportStep.input) ...[
                Text(
                  'Collez votre liste de films depuis vos Notes (1 film par ligne) :',
                  style: TextStyle(color: Colors.grey[300], fontSize: 13),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: "Exemple :\n1. Inception (2010)\n2. Interstellar\n- Dune: Part Two\nOppenheimer",
                      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF161722),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${parsedItems.length} film${parsedItems.length > 1 ? 's' : ''} détecté${parsedItems.length > 1 ? 's' : ''}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: parsedItems.isNotEmpty ? () => _startBatchAnalysis(parsedItems) : null,
                      icon: const Icon(Icons.search_rounded, size: 20, color: Colors.black),
                      label: const Text(
                        'Analyser',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],

              if (_currentStep == ImportStep.loading) ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 20),
                        Text(
                          'Analyse et recherche des films... ($_currentIndexAnalyzed / $_totalToAnalyze)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Recherche automatique des affiches et durées via TMDB',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_currentStep == ImportStep.results) ...[

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_searchResults.length} film${_searchResults.length > 1 ? 's' : ''} trouvé${_searchResults.length > 1 ? 's' : ''}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_unfoundTitles.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_unfoundTitles.length} non trouvé${_unfoundTitles.length > 1 ? 's' : ''}',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: ListView(
                    children: [
                      ..._searchResults.map((res) {
                        final movie = res.matchedMovie!;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161722),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: res.isSelected ? Colors.white.withValues(alpha: 0.4) : Colors.white10,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            child: Row(
                              children: [

                                Checkbox(
                                  value: res.isSelected,
                                  activeColor: Colors.white,
                                  checkColor: Colors.black,
                                  onChanged: res.isAlreadyInWatchlist
                                      ? null
                                      : (val) {
                                          setState(() {
                                            res.isSelected = val ?? false;
                                          });
                                        },
                                ),
                                const SizedBox(width: 2),

                                Expanded(
                                  child: InkWell(
                                    onTap: () => widget.onMovieSelected(movie),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                      child: Row(
                                        children: [
                                          MoviePosterWidget(
                                            movie: movie,
                                            width: 38,
                                            height: 56,
                                            borderRadius: 6,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  movie.title,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  res.isAlreadyInWatchlist
                                                      ? 'Déjà dans votre Watchlist'
                                                      : '${movie.year} • ${movie.duration}',
                                                  style: TextStyle(
                                                    color: res.isAlreadyInWatchlist ? Colors.amberAccent : Colors.grey[400],
                                                    fontSize: 11,
                                                    fontWeight: res.isAlreadyInWatchlist ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => _openReplaceSearchModal(res),
                                  icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.white),
                                  label: const Text(
                                    'Remplacer',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        );
                      }),

                      if (_unfoundTitles.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Films non identifiés automatiquement :',
                                style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ..._unfoundTitles.map(
                                (t) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text('• $t', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          _openReplaceSearchModal(
                                            ImportSearchResult(
                                              item: ImportParsedItem(rawLine: t, cleanTitle: t),
                                              matchedMovie: null,
                                            ),
                                            isUnfound: true,
                                            unfoundTitle: t,
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.search_rounded, color: Colors.white, size: 13),
                                              SizedBox(width: 4),
                                              Text('Rechercher', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _currentStep = ImportStep.input),
                      child: const Text('Modifier la liste', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: _searchResults.any((r) => r.isSelected) ? _executeBatchAdd : null,
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: Colors.black),
                      label: const Text(
                        'Ajouter',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplaceMovieSearchModal extends StatefulWidget {
  final String initialQuery;
  final String tmdbApiKey;
  final List<Movie> existingMovies;
  final Function(Movie movie) onMovieChosen;

  const _ReplaceMovieSearchModal({
    required this.initialQuery,
    required this.tmdbApiKey,
    required this.existingMovies,
    required this.onMovieChosen,
  });

  @override
  State<_ReplaceMovieSearchModal> createState() => _ReplaceMovieSearchModalState();
}

class _ReplaceMovieSearchModalState extends State<_ReplaceMovieSearchModal> {
  late TextEditingController _searchController;
  List<Movie> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _performSearch(widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      if (mounted) setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);

    List<Movie> tmdbResults = [];
    if (widget.tmdbApiKey.isNotEmpty) {
      tmdbResults = await TmdbService.searchMovies(widget.tmdbApiKey, q);
    }

    final queryLower = q.toLowerCase();
    final catalogMatches = widget.existingMovies
        .where((m) => m.title.toLowerCase().contains(queryLower))
        .toList();

    final combined = <Movie>[];
    for (var m in [...tmdbResults, ...catalogMatches]) {
      if (!combined.any((c) => c.id == m.id || c.title.toLowerCase() == m.title.toLowerCase())) {
        combined.add(m);
      }
    }

    if (mounted) {
      setState(() {
        _results = combined;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: const Color(0xFF0F1017),
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Colors.white24, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: BoxConstraints(maxHeight: mediaHeight * 0.85),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Remplacer le film',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                        ),
                        if (widget.initialQuery.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Recherche pour "${widget.initialQuery}"',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 16),

              TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                onChanged: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Taper le nom exact du film...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF161722),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 14),
                        Text('Recherche sur TMDB...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else if (_results.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'Aucun film correspondant trouvé pour "${_searchController.text}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final movie = _results[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161722),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              widget.onMovieChosen(movie);
                              Navigator.of(context).pop();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  MoviePosterWidget(
                                    movie: movie,
                                    width: 44,
                                    height: 64,
                                    borderRadius: 8,
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
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${movie.year} • ${movie.duration}',
                                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                        ),
                                        if (movie.director.isNotEmpty && movie.director != 'Inconnu') ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Réal : ${movie.director}',
                                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Choisir',
                                      style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../widgets/movie_poster.dart';
import '../widgets/clapperboard_header.dart';

class MovieChoicePage extends StatefulWidget {
  final List<Movie> movies;
  final Function(Movie) onMovieSelected;
  final Function(Movie movie, String newStatus) onStatusChanged;
  final VoidCallback onOpenSettings;

  const MovieChoicePage({
    super.key,
    required this.movies,
    required this.onMovieSelected,
    required this.onStatusChanged,
    required this.onOpenSettings,
  });

  @override
  State<MovieChoicePage> createState() => _MovieChoicePageState();
}

class _MovieChoicePageState extends State<MovieChoicePage> with SingleTickerProviderStateMixin {
  final Set<String> _selectedGenres = {};
  bool _isGenreDropdownOpen = false;
  int _maxDurationMinutes = 240;
  int _activeSubTab = 0;
  String _listSortDate = 'none';
  String _listSortDuration = 'none';

  late AnimationController _wheelController;
  double _currentAngle = 0.0;
  bool _isSpinning = false;
  Movie? _winningMovie;

  final List<Color> _sliceColors = [
    const Color(0xFF7D5FFF),
    const Color(0xFFFF3838),
    const Color(0xFF17C0EB),
    const Color(0xFFFF9F1A),
    const Color(0xFFFF4D4D),
    const Color(0xFF32FF7E),
    const Color(0xFF18DCFF),
    const Color(0xFFFF793F),
  ];

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  int _parseDurationMinutes(String durationStr) {
    try {
      final reg = RegExp(r'(?:(\d+)h)?\s*(?:(\d+)m)?');
      final match = reg.firstMatch(durationStr);
      if (match != null) {
        final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
        final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
        return (hours * 60) + minutes;
      }
    } catch (_) {}
    return 120;
  }

  List<Movie> get _filteredWatchlist {
    final today = DateTime.now();
    final now = DateTime(today.year, today.month, today.day);
    return widget.movies.where((movie) {
      if (movie.status != 'watch_later') return false;

      if (movie.releaseDate != null && movie.releaseDate!.isAfter(now)) {
        return false;
      }

      if (_selectedGenres.isNotEmpty) {
        final hasAnyGenre = movie.genres.any((g) => _selectedGenres.contains(g));
        if (!hasAnyGenre) return false;
      }

      final minutes = _parseDurationMinutes(movie.duration);
      if (minutes > _maxDurationMinutes) {
        return false;
      }

      return true;
    }).toList();
  }

  double _normalizeAngle(double angle) {
    final twopi = 2 * math.pi;
    double result = angle % twopi;
    if (result < 0) {
      result += twopi;
    }
    return result;
  }

  void _spinWheel(List<Movie> eligibleMovies) {
    if (_isSpinning || eligibleMovies.isEmpty) return;

    setState(() {
      _isSpinning = true;
      _winningMovie = null;
    });

    final random = math.Random();

    final extraRounds = 5 + random.nextInt(4);
    final selectedIndex = random.nextInt(eligibleMovies.length);

    final sliceAngle = (2 * math.pi) / eligibleMovies.length;

    final offsetInSlice = sliceAngle * (0.3 + random.nextDouble() * 0.4);
    final targetAngleInSlice = selectedIndex * sliceAngle + offsetInSlice;

    final targetFinalAngleBase = (3 * math.pi / 2) - targetAngleInSlice;
    final currentMod = _normalizeAngle(_currentAngle);

    double delta = _normalizeAngle(targetFinalAngleBase - currentMod);
    if (delta < 0.05) {
      delta += 2 * math.pi;
    }

    final totalTargetRotation = (extraRounds * 2 * math.pi) + delta;

    final startAngle = _currentAngle;
    final endAngle = startAngle + totalTargetRotation;

    final animation = CurvedAnimation(parent: _wheelController, curve: Curves.decelerate);

    _wheelController.reset();
    animation.addListener(() {
      setState(() {
        _currentAngle = startAngle + (endAngle - startAngle) * animation.value;
      });
    });

    _wheelController.forward().then((_) {
      setState(() {
        _isSpinning = false;
        _winningMovie = eligibleMovies[selectedIndex];
      });
      _showWinningDialog(_winningMovie!);
    });
  }

  void _pickRandomMovie(List<Movie> eligibleMovies) {
    if (eligibleMovies.isEmpty) return;
    final random = math.Random();
    final picked = eligibleMovies[random.nextInt(eligibleMovies.length)];
    setState(() {
      _winningMovie = picked;
    });
    _showWinningDialog(picked);
  }

  void _showWinningDialog(Movie movie) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D0E15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.2),
        ),
        title: const Column(
          children: [
            Text('FILM SÉLECTIONNÉ',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            SizedBox(height: 4),
            Text('Ce soir, vous regardez :',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.normal)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MoviePosterWidget(
                movie: movie,
                width: 140,
                height: 200,
                borderRadius: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              movie.title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '${movie.year} • ${movie.duration} • ${movie.genres.take(2).join(', ')}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                'Disponible sur : ${movie.platforms.take(2).join(', ')}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Fermer', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    widget.onMovieSelected(movie);
                  },
                  child: const Text('Voir Fiche', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final now = DateTime(2026, 10, 7);

    final watchlistMovies = widget.movies.where((m) {
      if (m.status != 'watch_later') return false;
      if (m.releaseDate != null && m.releaseDate!.isAfter(now)) return false;
      return true;
    }).toList();

    final allGenres = watchlistMovies.expand((m) => m.genres).toSet().toList()..sort();
    final Map<String, int> genreCounts = {};
    for (var movie in watchlistMovies) {
      for (var genre in movie.genres) {
        genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
      }
    }
    final eligibleMovies = _filteredWatchlist;

    final sortedMovies = List<Movie>.from(eligibleMovies);
    if (_listSortDate == 'newest') {
      sortedMovies.sort((a, b) {
        final indexA = widget.movies.indexOf(a);
        final indexB = widget.movies.indexOf(b);
        return indexB.compareTo(indexA);
      });
    } else if (_listSortDate == 'oldest') {
      sortedMovies.sort((a, b) {
        final indexA = widget.movies.indexOf(a);
        final indexB = widget.movies.indexOf(b);
        return indexA.compareTo(indexB);
      });
    }

    if (_listSortDuration == 'shortest') {
      sortedMovies.sort((a, b) => _parseDurationMinutes(a.duration).compareTo(_parseDurationMinutes(b.duration)));
    } else if (_listSortDuration == 'longest') {
      sortedMovies.sort((a, b) => _parseDurationMinutes(b.duration).compareTo(_parseDurationMinutes(a.duration)));
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            SliverToBoxAdapter(
              child: ClapperboardHeader(
                title: 'Choix du film',
                onOpenSettings: widget.onOpenSettings,
              ),
            ),

            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: Colors.amberAccent, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Filtres de recherche',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const Spacer(),
                        if (_selectedGenres.isNotEmpty || _maxDurationMinutes < 240)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedGenres.clear();
                                _maxDurationMinutes = 240;
                              });
                            },
                            child: const Text('Tout réinitialiser', style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Genres :',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        if (_selectedGenres.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedGenres.clear();
                              });
                            },
                            child: const Text('Réinitialiser genres', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isGenreDropdownOpen = !_isGenreDropdownOpen;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141524),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isGenreDropdownOpen ? Colors.white : Colors.white.withValues(alpha: 0.15),
                            width: _isGenreDropdownOpen ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.category_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedGenres.isEmpty
                                    ? 'Tous les genres (${watchlistMovies.length} film${watchlistMovies.length > 1 ? 's' : ''})'
                                    : '${_selectedGenres.length} genre${_selectedGenres.length > 1 ? 's' : ''} sélectionné${_selectedGenres.length > 1 ? 's' : ''} (${_selectedGenres.join(', ')})',
                                style: TextStyle(
                                  color: _selectedGenres.isEmpty ? Colors.grey[300] : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              _isGenreDropdownOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isGenreDropdownOpen) ...[
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF141524),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CheckboxListTile(
                              value: _selectedGenres.isEmpty,
                              onChanged: (bool? checked) {
                                if (checked == true) {
                                  setState(() {
                                    _selectedGenres.clear();
                                  });
                                }
                              },
                              title: Text(
                                'Tous les genres (${watchlistMovies.length} film${watchlistMovies.length > 1 ? 's' : ''})',
                                style: TextStyle(
                                  color: _selectedGenres.isEmpty ? Colors.white : Colors.grey[300],
                                  fontWeight: _selectedGenres.isEmpty ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                              activeColor: Colors.white,
                              checkColor: Colors.black,
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                            ),
                            const Divider(height: 1, color: Colors.white12),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 220),
                              child: ListView(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                children: allGenres.map((genre) {
                                  final isChecked = _selectedGenres.contains(genre);
                                  final count = genreCounts[genre] ?? 0;
                                  return CheckboxListTile(
                                    value: isChecked,
                                    onChanged: (bool? checked) {
                                      setState(() {
                                        if (checked == true) {
                                          _selectedGenres.add(genre);
                                        } else {
                                          _selectedGenres.remove(genre);
                                        }
                                      });
                                    },
                                    title: Text(
                                      '$genre ($count film${count > 1 ? 's' : ''})',
                                      style: TextStyle(
                                        color: isChecked ? Colors.white : Colors.grey[300],
                                        fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                    activeColor: Colors.white,
                                    checkColor: Colors.black,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    dense: true,
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Durée maximale :',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _maxDurationMinutes >= 240
                              ? 'Toutes les durées (4h max)'
                              : '≤ ${_maxDurationMinutes ~/ 60}h ${(_maxDurationMinutes % 60).toString().padLeft(2, '0')}m',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141524),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [

                          Expanded(
                            child: Column(
                              children: [
                                Text('HEURES', style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildStepperButton(
                                      icon: Icons.remove_rounded,
                                      onPressed: _maxDurationMinutes > 60
                                          ? () {
                                              setState(() {
                                                _maxDurationMinutes = (_maxDurationMinutes - 60).clamp(60, 240);
                                              });
                                            }
                                          : null,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        '${_maxDurationMinutes ~/ 60}h',
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    _buildStepperButton(
                                      icon: Icons.add_rounded,
                                      onPressed: _maxDurationMinutes < 240
                                          ? () {
                                              setState(() {
                                                _maxDurationMinutes = (_maxDurationMinutes + 60).clamp(60, 240);
                                              });
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),

                          Expanded(
                            child: Column(
                              children: [
                                Text('MINUTES (±10m)', style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildStepperButton(
                                      icon: Icons.remove_rounded,
                                      onPressed: _maxDurationMinutes > 60
                                          ? () {
                                              setState(() {
                                                _maxDurationMinutes = (_maxDurationMinutes - 10).clamp(60, 240);
                                              });
                                            }
                                          : null,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '${(_maxDurationMinutes % 60).toString().padLeft(2, '0')}m',
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    _buildStepperButton(
                                      icon: Icons.add_rounded,
                                      onPressed: _maxDurationMinutes < 240
                                          ? () {
                                              setState(() {
                                                _maxDurationMinutes = (_maxDurationMinutes + 10).clamp(60, 240);
                                              });
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.movie_filter_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${eligibleMovies.length} film${eligibleMovies.length > 1 ? 's' : ''} correspondent à vos filtres',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF161722),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSubTabButton(
                          index: 0,
                          label: 'Grande Roue',
                        ),
                      ),
                      Expanded(
                        child: _buildSubTabButton(
                          index: 1,
                          label: 'Tirage Hasard',
                        ),
                      ),
                      Expanded(
                        child: _buildSubTabButton(
                          index: 2,
                          label: 'Liste',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            if (eligibleMovies.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt_off_outlined, size: 64, color: Colors.grey[700]),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucun film ne correspond à vos filtres',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Essayez d\'élargir la durée maximale ou d\'enlever le filtre de genre !',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_activeSubTab == 0) ...[

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [

                        Container(
                          width: 295,
                          height: 295,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9F1A).withValues(alpha: 0.4),
                                blurRadius: 50,
                                spreadRadius: 12,
                              ),
                              BoxShadow(
                                color: const Color(0xFF7D5FFF).withValues(alpha: 0.3),
                                blurRadius: 70,
                                spreadRadius: 18,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          width: 290,
                          height: 290,
                          child: Transform.rotate(
                            angle: _currentAngle,
                            child: CustomPaint(
                              painter: WheelPainter(
                                movies: eligibleMovies,
                                sliceColors: _sliceColors,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          top: -24,
                          child: CasinoPointerWidget(
                            isSpinning: _isSpinning,
                            currentAngle: _currentAngle,
                            movieCount: eligibleMovies.length,
                          ),
                        ),

                        GestureDetector(
                          onTap: _isSpinning ? null : () => _spinWheel(eligibleMovies),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              gradient: const RadialGradient(
                                colors: [Color(0xFF3A3B52), Color(0xFF141524)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isSpinning ? Colors.amberAccent.withValues(alpha: 0.5) : const Color(0xFFFFD700),
                                width: 4.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.9),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isSpinning ? 'SPIN...' : 'SPIN',
                                    style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 1.2,
                                      shadows: [
                                        Shadow(blurRadius: 8, color: Colors.amber),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isSpinning ? '🎡' : 'LANCER',
                                    style: TextStyle(
                                      color: Colors.amber[200],
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ] else if (_activeSubTab == 1) ...[

              _buildVintageCinemaRandomDraw(eligibleMovies),
            ] else ...[

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    children: [

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141524),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _listSortDate != 'none' ? Colors.white : Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _listSortDate,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF1A1B29),
                              borderRadius: BorderRadius.circular(12),
                              icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70, size: 20),
                              style: TextStyle(
                                color: _listSortDate != 'none' ? Colors.white : Colors.grey[400],
                                fontSize: 12,
                                fontWeight: _listSortDate != 'none' ? FontWeight.bold : FontWeight.normal,
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _listSortDate = val;
                                  });
                                }
                              },
                              items: const [
                                DropdownMenuItem(value: 'none', child: Text('Date (Par défaut)')),
                                DropdownMenuItem(value: 'newest', child: Text('Plus récent (ajout)')),
                                DropdownMenuItem(value: 'oldest', child: Text('Plus ancien (ajout)')),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141524),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _listSortDuration != 'none' ? Colors.white : Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _listSortDuration,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF1A1B29),
                              borderRadius: BorderRadius.circular(12),
                              icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70, size: 20),
                              style: TextStyle(
                                color: _listSortDuration != 'none' ? Colors.white : Colors.grey[400],
                                fontSize: 12,
                                fontWeight: _listSortDuration != 'none' ? FontWeight.bold : FontWeight.normal,
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _listSortDuration = val;
                                  });
                                }
                              },
                              items: const [
                                DropdownMenuItem(value: 'none', child: Text('Durée (Par défaut)')),
                                DropdownMenuItem(value: 'shortest', child: Text('Plus court d\'abord')),
                                DropdownMenuItem(value: 'longest', child: Text('Plus long d\'abord')),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final movie = sortedMovies[index];
                      return _buildMovieChoiceCard(context, movie);
                    },
                    childCount: sortedMovies.length,
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabButton({required int index, required String label}) {
    final isSelected = _activeSubTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeSubTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMovieChoiceCard(BuildContext context, Movie movie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          contentPadding: const EdgeInsets.all(8),
          onTap: () => widget.onMovieSelected(movie),
          leading: SizedBox(
            width: 54,
            height: 80,
            child: MoviePosterWidget(
              movie: movie,
              width: 54,
              height: 80,
              borderRadius: 10,
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
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
              foregroundColor: Theme.of(context).colorScheme.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            onPressed: () => widget.onMovieSelected(movie),
            child: const Text('Choisir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ),
    );
  }

  Widget _buildVintageCinemaRandomDraw(List<Movie> eligibleMovies) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1017),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: 2.2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [

                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      10,
                      (index) => Container(
                        width: 10,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF252634),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.white30, width: 1),
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
                  child: Column(
                    children: [

                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 3.5),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.movie_creation_rounded,
                            size: 42,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'SELECTION SANS MANIÈRE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.2,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Le hasard sélectionne 1 film au sort parmi les ${eligibleMovies.length} titres filtrés de votre Watchlist.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 26),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.black, width: 2.5),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: () => _pickRandomMovie(eligibleMovies),
                        icon: const Icon(Icons.shuffle_rounded, size: 24, color: Colors.black),
                        label: const Text(
                          'PIOCHER AU HASARD',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      10,
                      (index) => Container(
                        width: 10,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF252634),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.white30, width: 1),
                        ),
                      ),
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

  Widget _buildStepperButton({required IconData icon, VoidCallback? onPressed}) {
    final enabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Icon(icon, size: 18, color: enabled ? Colors.white : Colors.grey[700]),
      ),
    );
  }
}

class CasinoPointerWidget extends StatelessWidget {
  final bool isSpinning;
  final double currentAngle;
  final int movieCount;

  const CasinoPointerWidget({
    super.key,
    required this.isSpinning,
    required this.currentAngle,
    required this.movieCount,
  });

  @override
  Widget build(BuildContext context) {

    final flickAngle = isSpinning ? math.sin(currentAngle * (movieCount > 0 ? movieCount : 8) * 1.5) * 0.14 : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        Container(
          width: 38,
          height: 12,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF59D), Color(0xFFFFD700), Color(0xFFB8860B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white, width: 1.2),
            boxShadow: const [
              BoxShadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
              BoxShadow(color: Colors.amber, blurRadius: 8, spreadRadius: 1),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF3E2723), shape: BoxShape.circle)),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF3E2723), shape: BoxShape.circle)),
            ],
          ),
        ),

        Transform.rotate(
          angle: flickAngle,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 34,
            height: 42,
            child: CustomPaint(
              painter: CasinoFlapperPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

class CasinoFlapperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    path.moveTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    final shadowPath = path.shift(const Offset(0, 3));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    final bodyGradient = const LinearGradient(
      colors: [Color(0xFFFF1744), Color(0xFFD50000), Color(0xFF880000)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final fillPaint = Paint()
      ..shader = bodyGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final goldBorderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, goldBorderPaint);

    final gemCenter = Offset(size.width / 2, 6);
    canvas.drawCircle(gemCenter, 5.5, Paint()..color = const Color(0xFFFFD700));
    canvas.drawCircle(gemCenter, 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WheelPainter extends CustomPainter {
  final List<Movie> movies;
  final List<Color> sliceColors;

  WheelPainter({required this.movies, required this.sliceColors});

  @override
  void paint(Canvas canvas, Size size) {
    if (movies.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sliceAngle = (2 * math.pi) / movies.length;

    final slicePaint = Paint()..style = PaintingStyle.fill;

    final goldBorderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final goldOuterRimPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    final goldInnerRimPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final darkRimBackgroundPaint = Paint()
      ..color = const Color(0xFF141524)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0;

    final warmLedGlowPaint = Paint()
      ..color = const Color(0xFFFFECB3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final rubyLedGlowPaint = Paint()
      ..color = const Color(0xFFFF1744)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final ledCorePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius - 8, darkRimBackgroundPaint);

    final innerRadius = radius - 16;
    final sliceBounds = Rect.fromCircle(center: center, radius: innerRadius);

    for (int i = 0; i < movies.length; i++) {
      Color baseColor = sliceColors[i % sliceColors.length];
      if (i == movies.length - 1 && movies.length > 1 && (i % sliceColors.length) == 0) {
        baseColor = sliceColors[1 % sliceColors.length];
      }

      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Color.lerp(baseColor, Colors.white, 0.4)!,
          baseColor,
          Color.lerp(baseColor, Colors.black, 0.35)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      );
      slicePaint.shader = gradient.createShader(sliceBounds);

      final startAngle = i * sliceAngle;

      canvas.drawArc(
        sliceBounds,
        startAngle,
        sliceAngle,
        true,
        slicePaint,
      );

      if (movies.length > 1) {
        final spokeAngle = startAngle;
        final spokeEndX = center.dx + innerRadius * math.cos(spokeAngle);
        final spokeEndY = center.dy + innerRadius * math.sin(spokeAngle);
        canvas.drawLine(center, Offset(spokeEndX, spokeEndY), goldBorderPaint);
      }

      final midAngle = startAngle + sliceAngle / 2;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(midAngle);

      int maxChar = 14;
      double fontSize = 12.0;
      if (movies.length > 30) {
        maxChar = 4;
        fontSize = 7.0;
      } else if (movies.length > 20) {
        maxChar = 6;
        fontSize = 8.0;
      } else if (movies.length > 14) {
        maxChar = 8;
        fontSize = 9.0;
      } else if (movies.length > 8) {
        maxChar = 10;
        fontSize = 10.5;
      }

      final textSpan = TextSpan(
        text: _truncateTitle(movies[i].title, maxChar),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
          shadows: const [
            Shadow(blurRadius: 6, color: Colors.black, offset: Offset(1, 1)),
            Shadow(blurRadius: 6, color: Colors.black, offset: Offset(-1, -1)),
            Shadow(blurRadius: 3, color: Colors.black),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(innerRadius * 0.32, -textPainter.height / 2));
      canvas.restore();
    }

    canvas.drawCircle(center, radius - 2.5, goldOuterRimPaint);
    canvas.drawCircle(center, innerRadius, goldInnerRimPaint);

    const int totalBulbs = 20;
    final bulbAngleStep = (2 * math.pi) / totalBulbs;
    final bulbDistance = radius - 8;

    for (int b = 0; b < totalBulbs; b++) {
      final bulbAngle = b * bulbAngleStep;
      final bulbX = center.dx + bulbDistance * math.cos(bulbAngle);
      final bulbY = center.dy + bulbDistance * math.sin(bulbAngle);
      final bulbPos = Offset(bulbX, bulbY);

      final isOdd = b % 2 != 0;

      canvas.drawCircle(bulbPos, 4.0, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 1.0);

      canvas.drawCircle(bulbPos, 5.0, isOdd ? warmLedGlowPaint : rubyLedGlowPaint);

      canvas.drawCircle(bulbPos, 2.5, ledCorePaint);
    }

    final pegShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final pegGoldPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final pegRimPaint = Paint()
      ..color = const Color(0xFFB8860B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final pegHighlightPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final int numPegs = math.min(movies.length, 20);
    final pegAngleStep = (2 * math.pi) / numPegs;

    for (int i = 0; i < numPegs; i++) {
      final pegAngle = i * pegAngleStep;
      final pegX = center.dx + (innerRadius - 2) * math.cos(pegAngle);
      final pegY = center.dy + (innerRadius - 2) * math.sin(pegAngle);
      final pegCenter = Offset(pegX, pegY);

      canvas.drawCircle(pegCenter + const Offset(0.8, 1.2), 4.5, pegShadowPaint);

      canvas.drawCircle(pegCenter, 4.2, pegGoldPaint);
      canvas.drawCircle(pegCenter, 4.2, pegRimPaint);

      canvas.drawCircle(pegCenter - const Offset(1.2, 1.2), 1.6, pegHighlightPaint);
    }
  }

  String _truncateTitle(String str, int maxLen) {
    if (str.length <= maxLen) return str;
    return '${str.substring(0, maxLen - 1)}…';
  }

  @override
  bool shouldRepaint(covariant WheelPainter oldDelegate) {
    if (oldDelegate.movies.length != movies.length) return true;
    return oldDelegate.movies != movies || oldDelegate.sliceColors != sliceColors;
  }
}

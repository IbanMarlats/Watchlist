import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../widgets/movie_poster.dart';
import '../widgets/clapperboard_header.dart';

class ReleasesPage extends StatefulWidget {
  final List<Movie> movies;
  final Function(Movie) onMovieSelected;
  final Function(Movie movie, String newStatus) onStatusChanged;
  final VoidCallback onOpenSettings;

  const ReleasesPage({
    super.key,
    required this.movies,
    required this.onMovieSelected,
    required this.onStatusChanged,
    required this.onOpenSettings,
  });

  @override
  State<ReleasesPage> createState() => _ReleasesPageState();
}

class _ReleasesPageState extends State<ReleasesPage> {

  static const List<String> _monthsFr = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  static const List<String> _daysFr = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
  ];

  String _formatDate(DateTime dt) {
    final dayName = _daysFr[dt.weekday - 1];
    final monthName = _monthsFr[dt.month - 1];
    return '$dayName ${dt.day} $monthName ${dt.year}';
  }

  String _formatMonthYear(DateTime dt) {
    final monthName = _monthsFr[dt.month - 1].toUpperCase();
    return '$monthName ${dt.year}';
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
                    content: Text('"${movie.title}" marqué Vu'),
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
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final targetMovies = widget.movies.where((m) => m.status == 'watch_later').toList();

    final recentReleases = targetMovies.where((m) {
      if (m.releaseDate == null) return false;
      return m.releaseDate!.isAfter(thirtyDaysAgo.subtract(const Duration(days: 1))) &&
          m.releaseDate!.isBefore(now.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => b.releaseDate!.compareTo(a.releaseDate!));

    final upcomingMovies = targetMovies.where((m) {
      if (m.releaseDate == null) return false;
      return m.releaseDate!.isAfter(now);
    }).toList()
      ..sort((a, b) => a.releaseDate!.compareTo(b.releaseDate!));

    final Map<String, List<Movie>> groupedUpcoming = {};
    for (var movie in upcomingMovies) {
      final key = _formatMonthYear(movie.releaseDate!);
      groupedUpcoming.putIfAbsent(key, () => []).add(movie);
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            SliverToBoxAdapter(
              child: ClapperboardHeader(
                title: 'Sorties films',
                onOpenSettings: widget.onOpenSettings,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            if (recentReleases.isEmpty && groupedUpcoming.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune sortie enregistrée dans votre liste',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

            if (recentReleases.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    children: [
                      const Text(
                        'Sortis ces 30 derniers jours',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${recentReleases.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                      final movie = recentReleases[index];
                      return _buildReleaseMovieCard(context, movie, isRecent: true, now: now);
                    },
                    childCount: recentReleases.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],

            ...groupedUpcoming.entries.expand((entry) {
              final monthTitle = entry.key;
              final moviesInMonth = entry.value;

              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Row(
                      children: [
                        Text(
                          monthTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${moviesInMonth.length} film${moviesInMonth.length > 1 ? 's' : ''}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                        final movie = moviesInMonth[index];
                        return _buildReleaseMovieCard(context, movie, isRecent: false, now: now);
                      },
                      childCount: moviesInMonth.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ];
            }),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildReleaseMovieCard(BuildContext context, Movie movie, {required bool isRecent, required DateTime now}) {
    final releaseDate = movie.releaseDate;
    String badgeText = '';

    if (releaseDate != null) {
      final relDay = DateTime(releaseDate.year, releaseDate.month, releaseDate.day);
      final differenceInDays = relDay.difference(now).inDays;
      if (isRecent) {
        final daysAgo = now.difference(relDay).inDays;
        badgeText = daysAgo <= 0 ? 'Sorti aujourd\'hui' : 'Sorti il y a $daysAgo jour${daysAgo > 1 ? 's' : ''}';
      } else {
        if (differenceInDays <= 0) {
          badgeText = 'Aujourd\'hui';
        } else if (differenceInDays == 1) {
          badgeText = 'Demain';
        } else {
          badgeText = 'Dans $differenceInDays jours';
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => widget.onMovieSelected(movie),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                MoviePosterWidget(
                  movie: movie,
                  width: 64,
                  height: 94,
                  borderRadius: 12,
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      if (releaseDate != null) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],

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

                      if (releaseDate != null)
                        Text(
                          _formatDate(releaseDate),
                          style: TextStyle(color: Colors.grey[300], fontSize: 12, fontWeight: FontWeight.w500),
                        ),

                      const SizedBox(height: 4),
                      Text(
                        '${movie.duration} • ${movie.genres.take(2).join(', ')}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                if (movie.status == 'watch_later')
                  GestureDetector(
                    onTap: () => _showConfirmWatchedDialog(context, movie),
                    child: Container(
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
                  )
                else if (movie.status == 'completed')
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 1.5),
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

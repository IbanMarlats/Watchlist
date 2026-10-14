import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/sample_movies.dart';
import 'models/movie.dart';
import 'pages/home_page.dart';
import 'pages/search_page.dart';
import 'pages/movie_detail_page.dart';
import 'pages/movie_choice_page.dart';
import 'pages/releases_page.dart';
import 'pages/settings_page.dart';

import 'services/local_db_service.dart';
import 'services/tmdb_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  runApp(const WatchlistApp());
}

class WatchlistApp extends StatefulWidget {
  const WatchlistApp({super.key});

  @override
  State<WatchlistApp> createState() => _WatchlistAppState();
}

class _WatchlistAppState extends State<WatchlistApp> {
  Color _accentColor = const Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    return MaterialApp(
      title: 'Watchlist Mobile',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: _accentColor,
        colorScheme: ColorScheme.dark(
          primary: _accentColor,
          secondary: Colors.white70,
          surface: const Color(0xFF161722),
          onSurface: const Color(0xFFF0F0F8),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF161722),
          contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          actionTextColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: MainShell(
        accentColor: _accentColor,
        onAccentColorChanged: (newColor) {
          setState(() => _accentColor = newColor);
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final Color accentColor;
  final Function(Color) onAccentColorChanged;

  const MainShell({
    super.key,
    required this.accentColor,
    required this.onAccentColorChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late List<Movie> _movies;
  int _currentIndex = 0;
  int _previousIndex = 0;
  Movie? _selectedMovie;
  String _tmdbApiKey = LocalDbService.defaultEnvironmentApiKey;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _movies = getInitialMovies();
    _pageController = PageController(initialPage: _currentIndex);
    _loadSavedData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final savedApiKey = await LocalDbService.loadApiKey();
    final savedMovies = await LocalDbService.loadMovies();
    if (mounted) {
      setState(() {
        _tmdbApiKey = savedApiKey;
        _movies = savedMovies;
        if (_selectedMovie != null) {
          _selectedMovie = _movies.firstWhere((m) => m.id == _selectedMovie!.id, orElse: () => _selectedMovie!);
        }
      });
      _repairSavedMoviesRuntimes();
    }
  }

  Future<void> _repairSavedMoviesRuntimes() async {
    if (_tmdbApiKey.isEmpty) return;
    bool needsSave = false;
    final updatedList = List<Movie>.from(_movies);

    for (int i = 0; i < updatedList.length; i++) {
      final m = updatedList[i];
      if (m.id.startsWith('tmdb-') && (m.duration == '2h 00m' || m.director == 'TMDB' || m.director == 'Réalisateur TMDB')) {
        final rawId = int.tryParse(m.id.replaceAll('tmdb-', '')) ?? 0;
        if (rawId > 0) {
          final detail = await TmdbService.getMovieDetails(_tmdbApiKey, rawId);
          if (detail != null) {
            updatedList[i] = detail.copyWith(
              status: m.status,
              userNotes: m.userNotes,
            );
            needsSave = true;
          }
        }
      }
    }

    if (needsSave && mounted) {
      setState(() {
        _movies = updatedList;
      });
      await LocalDbService.saveMovies(updatedList);
    }
  }

  Future<void> _onApiKeyChanged(String newKey) async {
    setState(() {
      _tmdbApiKey = newKey;
    });
    await LocalDbService.saveApiKey(newKey);
    _repairSavedMoviesRuntimes();
  }

  Future<void> _onStatusChanged(Movie movie, String newStatus) async {
    Movie movieToSave = movie;
    if (_tmdbApiKey.isNotEmpty && movie.id.startsWith('tmdb-') && (movie.duration == '2h 00m' || movie.director == 'Réalisateur TMDB')) {
      final rawId = int.tryParse(movie.id.replaceAll('tmdb-', '')) ?? 0;
      if (rawId > 0) {
        final detail = await TmdbService.getMovieDetails(_tmdbApiKey, rawId);
        if (detail != null) {
          movieToSave = detail.copyWith(userNotes: movie.userNotes);
        }
      }
    }

    final updatedList = await LocalDbService.saveOrUpdateMovieStatus(_movies, movieToSave, newStatus);
    if (mounted) {
      setState(() {
        _movies = updatedList;
        if (_selectedMovie?.id == movieToSave.id) {
          _selectedMovie = _movies.firstWhere((m) => m.id == movieToSave.id, orElse: () => movieToSave.copyWith(status: newStatus));
        }
      });
    }
  }

  Future<void> _handleRefreshHomePage() async {
    await _loadSavedData();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _onBatchAddMovies(List<Movie> moviesToAdd) async {
    List<Movie> currentList = List<Movie>.from(_movies);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var m in moviesToAdd) {
      final existingIdx = currentList.indexWhere(
        (x) => x.id == m.id || x.title.toLowerCase() == m.title.toLowerCase(),
      );
      final movieWithWatchLater = m.copyWith(status: 'watch_later');
      if (existingIdx != -1) {
        currentList.removeAt(existingIdx);
      }

      final isReleased = movieWithWatchLater.releaseDate != null
          ? !movieWithWatchLater.releaseDate!.isAfter(today)
          : movieWithWatchLater.year <= today.year;

      if (isReleased) {
        currentList.insert(0, movieWithWatchLater);
      } else {
        currentList.add(movieWithWatchLater);
      }
    }
    await LocalDbService.saveMovies(currentList);
    if (mounted) {
      setState(() {
        _movies = currentList;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🍿 ${moviesToAdd.length} film${moviesToAdd.length > 1 ? 's' : ''} ajouté${moviesToAdd.length > 1 ? 's' : ''} à la Watchlist !',
          ),
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
  }

  Future<void> _onSaveNotes(Movie movie, String notes) async {
    final updatedList = await LocalDbService.saveMovieNotes(_movies, movie.id, notes);
    if (mounted) {
      setState(() {
        _movies = updatedList;
        if (_selectedMovie?.id == movie.id) {
          _selectedMovie = _movies.firstWhere((m) => m.id == movie.id, orElse: () => movie.copyWith(userNotes: notes));
        }
      });
    }
  }

  void _openMovieDetail(Movie movie) {
    setState(() {
      _selectedMovie = movie;
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MovieDetailPage(
          movie: movie,
          onStatusChanged: _onStatusChanged,
          onSaveNotes: _onSaveNotes,
          onBack: () => Navigator.of(ctx).pop(),
          onOpenSettings: () {
            Navigator.of(ctx).pop();
            _openSettings();
          },
          tmdbApiKey: _tmdbApiKey,
        ),
      ),
    );
  }

  void _openSettings() {
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = 4;
    });
  }

  Future<void> _resetData() async {
    await LocalDbService.clearAll();
    if (mounted) {
      setState(() {
        _movies = [];
        _selectedMovie = null;
      });
    }
  }

  void _onTabTapped(int index) {
    final wasSettings = _currentIndex == 4;
    setState(() {
      _currentIndex = index;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        if (wasSettings) {
          _pageController.jumpToPage(index);
        } else if (_pageController.page?.round() != index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        movies: _movies,
        onMovieSelected: _openMovieDetail,
        onStatusChanged: _onStatusChanged,
        onOpenSettings: _openSettings,
        onBatchAddMovies: _onBatchAddMovies,
        onRefresh: _handleRefreshHomePage,
        tmdbApiKey: _tmdbApiKey,
      ),
      SearchPage(
        movies: _movies,
        onMovieSelected: _openMovieDetail,
        onStatusChanged: _onStatusChanged,
        onOpenSettings: _openSettings,
        tmdbApiKey: _tmdbApiKey,
      ),
      MovieChoicePage(
        movies: _movies,
        onMovieSelected: _openMovieDetail,
        onStatusChanged: _onStatusChanged,
        onOpenSettings: _openSettings,
      ),
      ReleasesPage(
        movies: _movies,
        onMovieSelected: _openMovieDetail,
        onStatusChanged: _onStatusChanged,
        onOpenSettings: _openSettings,
      ),
    ];

    Widget currentBody;
    if (_currentIndex == 4) {
      currentBody = SettingsPage(
        movies: _movies,
        currentAccentColor: widget.accentColor,
        onAccentColorChanged: widget.onAccentColorChanged,
        onResetData: _resetData,
        onBack: () {
          setState(() {
            _currentIndex = _previousIndex;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(_previousIndex);
            }
          });
        },
        tmdbApiKey: _tmdbApiKey,
        onApiKeyChanged: _onApiKeyChanged,
      );
    } else {
      currentBody = PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (_currentIndex != index) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        children: pages,
      );
    }

    final activeTab = _currentIndex > 3 ? _previousIndex : _currentIndex;

    final screenContent = Scaffold(
      body: currentBody,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF07070A),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  activeTab: activeTab,
                  icon: Icons.bookmark_outline_rounded,
                  activeIcon: Icons.bookmark_rounded,
                  label: 'Accueil',
                ),
                _buildNavItem(
                  index: 1,
                  activeTab: activeTab,
                  icon: Icons.search_rounded,
                  activeIcon: Icons.search_rounded,
                  label: 'Recherche',
                ),
                _buildNavItem(
                  index: 2,
                  activeTab: activeTab,
                  icon: Icons.casino_outlined,
                  activeIcon: Icons.casino_rounded,
                  label: 'Choix Film',
                ),
                _buildNavItem(
                  index: 3,
                  activeTab: activeTab,
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month_rounded,
                  label: 'Sorties',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return screenContent;
  }

  Widget _buildNavItem({
    required int index,
    required int activeTab,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = activeTab == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : const Color(0xFF888899),
              size: 21,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

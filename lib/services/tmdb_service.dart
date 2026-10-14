import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class TmdbService {
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  static const String backdropBaseUrl = 'https://image.tmdb.org/t/p/w1280';

  static final Map<int, String> genreMap = {
    28: 'Action',
    12: 'Aventure',
    16: 'Animation',
    35: 'Comédie',
    80: 'Crime',
    99: 'Documentaire',
    18: 'Drame',
    10751: 'Famille',
    14: 'Fantastique',
    36: 'Histoire',
    27: 'Horreur',
    10402: 'Musique',
    9648: 'Mystère',
    10749: 'Romance',
    878: 'Science-Fiction',
    10770: 'Téléfilm',
    53: 'Thriller',
    10752: 'Guerre',
    37: 'Western',
  };

  static Movie tmdbJsonToMovie(Map<String, dynamic> json, {String status = 'none'}) {
    final int id = json['id'] ?? 0;
    final String title = json['title'] ?? json['name'] ?? 'Sans titre';
    final String originalTitle = json['original_title'] ?? title;

    final String posterPath = json['poster_path'] ?? '';
    final String backdropPath = json['backdrop_path'] ?? '';

    final String posterUrl = posterPath.isNotEmpty
        ? '$imageBaseUrl$posterPath'
        : '';

    final String backdropUrl = backdropPath.isNotEmpty
        ? '$backdropBaseUrl$backdropPath'
        : '';

    final String releaseDateStr = json['release_date'] ?? '';
    DateTime? releaseDate;
    int year = 2026;
    if (releaseDateStr.isNotEmpty) {
      try {
        releaseDate = DateTime.parse(releaseDateStr);
        year = releaseDate.year;
      } catch (_) {}
    }

    String durationStr = '2h 00m';
    if (json['runtime'] != null && json['runtime'] is int && (json['runtime'] as int) > 0) {
      final int totalMins = json['runtime'] as int;
      final int hours = totalMins ~/ 60;
      final int mins = totalMins % 60;
      durationStr = hours > 0
          ? '${hours}h ${mins < 10 ? '0' : ''}${mins}m'
          : '${mins}m';
    } else if (json['duration'] != null && json['duration'] is String) {
      durationStr = json['duration'];
    }

    List<String> genres = [];
    if (json['genre_ids'] != null && json['genre_ids'] is List) {
      genres = (json['genre_ids'] as List)
          .map((id) => genreMap[id as int])
          .whereType<String>()
          .toList();
    } else if (json['genres'] != null && json['genres'] is List) {
      genres = (json['genres'] as List)
          .map((g) => g['name'] as String?)
          .whereType<String>()
          .toList();
    }
    if (genres.isEmpty) genres = ['Cinéma'];

    final String overview = json['overview'] ?? 'Aucun synopsis disponible.';

    String director = 'Réalisateur TMDB';
    List<String> cast = ['Casting Principal'];
    if (json['credits'] != null && json['credits'] is Map) {
      final credits = json['credits'] as Map<String, dynamic>;
      if (credits['crew'] != null && credits['crew'] is List) {
        final crew = credits['crew'] as List;
        final dirObj = crew.firstWhere(
          (c) => c['job'] == 'Director',
          orElse: () => null,
        );
        if (dirObj != null && dirObj['name'] != null) {
          director = dirObj['name'];
        }
      }
      if (credits['cast'] != null && credits['cast'] is List) {
        final castList = credits['cast'] as List;
        final topCast = castList.take(4).map((c) => c['name'] as String?).whereType<String>().toList();
        if (topCast.isNotEmpty) {
          cast = topCast;
        }
      }
    }

    return Movie(
      id: 'tmdb-$id',
      title: title,
      originalTitle: originalTitle,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      year: year,
      duration: durationStr,
      genres: genres,
      director: director,
      cast: cast,
      synopsis: overview,
      platforms: ['Au cinéma', 'VOD'],
      gradientColors: [const Color(0xFF161722), const Color(0xFF000000)],
      icon: Icons.movie_rounded,
      releaseDate: releaseDate,
      status: status,
    );
  }

  static Future<Movie?> getMovieDetails(String apiKey, int rawTmdbId) async {
    if (apiKey.isEmpty || rawTmdbId <= 0) return null;

    final url = Uri.parse('$baseUrl/movie/$rawTmdbId?api_key=$apiKey&language=fr-FR&append_to_response=credits');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return tmdbJsonToMovie(data);
      }
    } catch (e) {
      debugPrint('TMDB Detail error: $e');
    }
    return null;
  }

  static Future<List<Movie>> searchMovies(String apiKey, String query) async {
    if (apiKey.isEmpty || query.trim().isEmpty) return [];

    final url = Uri.parse('$baseUrl/search/movie?api_key=$apiKey&query=${Uri.encodeComponent(query)}&language=fr-FR&page=1');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        final basicMovies = results.take(10).map((item) => tmdbJsonToMovie(item)).toList();

        final enrichedMovies = await Future.wait(
          basicMovies.map((m) async {
            final rawId = int.tryParse(m.id.replaceAll('tmdb-', '')) ?? 0;
            if (rawId > 0) {
              final detail = await getMovieDetails(apiKey, rawId);
              if (detail != null) return detail;
            }
            return m;
          }),
        );
        return enrichedMovies;
      }
    } catch (e) {
      debugPrint('TMDB Search error: $e');
    }
    return [];
  }

  static Future<List<Movie>> getPopularMovies(String apiKey) async {
    if (apiKey.isEmpty) return [];

    final url = Uri.parse('$baseUrl/movie/popular?api_key=$apiKey&language=fr-FR&page=1');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        final basicMovies = results.take(10).map((item) => tmdbJsonToMovie(item)).toList();

        final enrichedMovies = await Future.wait(
          basicMovies.map((m) async {
            final rawId = int.tryParse(m.id.replaceAll('tmdb-', '')) ?? 0;
            if (rawId > 0) {
              final detail = await getMovieDetails(apiKey, rawId);
              if (detail != null) return detail;
            }
            return m;
          }),
        );
        return enrichedMovies;
      }
    } catch (e) {
      debugPrint('TMDB Popular error: $e');
    }
    return [];
  }
}

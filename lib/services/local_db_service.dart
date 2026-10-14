import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class LocalDbService {
  static const String _watchlistKey = 'user_saved_watchlist_v1';
  static const String _apiKeyPrefKey = 'tmdb_api_key';

  static Future<List<Movie>> loadMovies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? rawJson = prefs.getString(_watchlistKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawJson);
        return decoded.map((item) => Movie.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<void> saveMovies(List<Movie> movies) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(movies.map((m) => m.toJson()).toList());
      await prefs.setString(_watchlistKey, encoded);
    } catch (_) {}
  }

  static bool _isReleased(Movie m) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (m.releaseDate != null) {
      return !m.releaseDate!.isAfter(today);
    }
    return m.year <= today.year;
  }

  static Future<List<Movie>> saveOrUpdateMovieStatus(List<Movie> currentMovies, Movie movie, String newStatus) async {
    final updatedList = List<Movie>.from(currentMovies);
    final index = updatedList.indexWhere((m) => m.id == movie.id);
    final updatedMovie = movie.copyWith(status: newStatus);

    if (newStatus == 'none') {

      if (index != -1) {
        updatedList.removeAt(index);
      }
    } else {
      if (index != -1) {
        updatedList.removeAt(index);
      }

      if (newStatus == 'watch_later' && !_isReleased(updatedMovie)) {

        updatedList.add(updatedMovie);
      } else {

        updatedList.insert(0, updatedMovie);
      }
    }

    await saveMovies(updatedList);
    return updatedList;
  }

  static Future<List<Movie>> saveMovieNotes(List<Movie> currentMovies, String movieId, String notes) async {
    final updatedList = List<Movie>.from(currentMovies);
    final index = updatedList.indexWhere((m) => m.id == movieId);
    if (index != -1) {
      updatedList[index] = updatedList[index].copyWith(userNotes: notes);
      await saveMovies(updatedList);
    }
    return updatedList;
  }

  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_watchlistKey);
    } catch (_) {}
  }

  static const String defaultEnvironmentApiKey = String.fromEnvironment('TMDB_API_KEY', defaultValue: '');

  static Future<String> loadApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = prefs.getString(_apiKeyPrefKey);
      if (userKey != null && userKey.trim().isNotEmpty) {
        return userKey.trim();
      }
      return defaultEnvironmentApiKey;
    } catch (_) {
      return defaultEnvironmentApiKey;
    }
  }

  static Future<void> saveApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyPrefKey, apiKey);
    } catch (_) {}
  }
}

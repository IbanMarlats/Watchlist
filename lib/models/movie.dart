import 'package:flutter/material.dart';

class Movie {
  final String id;
  final String title;
  final String originalTitle;
  final String posterUrl;
  final String backdropUrl;
  final int year;
  final String duration;
  final List<String> genres;
  final String director;
  final List<String> cast;
  final String synopsis;
  final List<String> platforms;
  final List<Color> gradientColors;
  final IconData icon;
  final DateTime? releaseDate;

  String status;
  String? userNotes;

  Movie({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.posterUrl,
    required this.backdropUrl,
    required this.year,
    required this.duration,
    required this.genres,
    required this.director,
    required this.cast,
    required this.synopsis,
    required this.platforms,
    required this.gradientColors,
    required this.icon,
    this.releaseDate,
    this.status = 'none',
    this.userNotes,
  });

  Movie copyWith({
    String? status,
    String? userNotes,
    DateTime? releaseDate,
  }) {
    return Movie(
      id: id,
      title: title,
      originalTitle: originalTitle,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      year: year,
      duration: duration,
      genres: genres,
      director: director,
      cast: cast,
      synopsis: synopsis,
      platforms: platforms,
      gradientColors: gradientColors,
      icon: icon,
      releaseDate: releaseDate ?? this.releaseDate,
      status: status ?? this.status,
      userNotes: userNotes ?? this.userNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'originalTitle': originalTitle,
      'posterUrl': posterUrl,
      'backdropUrl': backdropUrl,
      'year': year,
      'duration': duration,
      'genres': genres,
      'director': director,
      'cast': cast,
      'synopsis': synopsis,
      'platforms': platforms,
      'releaseDate': releaseDate?.toIso8601String(),
      'status': status,
      'userNotes': userNotes,
    };
  }

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      originalTitle: json['originalTitle'] as String? ?? json['title'] as String? ?? '',
      posterUrl: json['posterUrl'] as String? ?? '',
      backdropUrl: json['backdropUrl'] as String? ?? '',
      year: json['year'] as int? ?? 2026,
      duration: json['duration'] as String? ?? '2h 00m',
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      director: json['director'] as String? ?? 'Inconnu',
      cast: (json['cast'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      synopsis: json['synopsis'] as String? ?? '',
      platforms: (json['platforms'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Cinéma'],
      gradientColors: [const Color(0xFF1E1E2C), const Color(0xFF12121D)],
      icon: Icons.movie_rounded,
      releaseDate: json['releaseDate'] != null ? DateTime.tryParse(json['releaseDate'] as String) : null,
      status: json['status'] as String? ?? 'none',
      userNotes: json['userNotes'] as String?,
    );
  }
}


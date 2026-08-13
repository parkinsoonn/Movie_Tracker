import 'package:flutter/material.dart';

class AppConstants {
  // API Configuration
  static const String apiKey = 'YOUR_TMDB_API_KEY_HERE';
  static const String apiBaseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  // App Colors
  static const Color primaryColor = Color(0xFF6200EA); // Deep Purple
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Grey
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color ratingColor = Color(0xFFFFC107); // Amber for stars

  // Spacing & Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Border Radius
  static const double defaultBorderRadius = 12.0;

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: textSecondaryColor,
  );
}
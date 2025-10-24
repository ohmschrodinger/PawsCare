// lib/theme/typography.dart
import 'package:flutter/material.dart';

/// Typography theme following Apple's Human Interface Guidelines (HIG)
///
/// This provides a consistent set of text styles across the app based on
/// iOS text style recommendations:
/// - Large Title: 34pt
/// - Title 1: 28pt
/// - Title 2: 22pt (Bold)
/// - Title 3: 20pt (Semibold)
/// - Headline: 17pt (Semibold)
/// - Body: 17pt (Regular)
/// - Callout: 16pt (Regular)
/// - Subhead: 15pt (Regular)
/// - Footnote: 13pt (Regular)
/// - Caption 1: 12pt (Regular)
/// - Caption 2: 11pt (Regular)

class AppTypography {
  // Private constructor to prevent instantiation
  AppTypography._();

  /// Returns a TextTheme configured with Apple HIG-inspired sizes
  static TextTheme getTextTheme() {
    return const TextTheme(
      // Large Title - 34pt (for major headlines)
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.37,
        height: 1.21, // 41/34
      ),

      // Title 1 - 28pt
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.36,
        height: 1.21, // 34/28
      ),

      // Title 2 - 22pt (Bold) - Main Greeting
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.35,
        height: 1.27, // 28/22
      ),

      // Title 3 - 20pt (Bold) - Section Titles
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.38,
        height: 1.25, // 25/20
      ),

      // Subhead - 15pt (Regular) - Card Body Text
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.24,
        height: 1.33, // 20/15
      ),

      // Headline - 17pt (Semibold) - Card Headlines
      headlineSmall: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.41,
        height: 1.29, // 22/17
      ),

      // Body - 17pt (Regular) - Greeting Subtext
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.41,
        height: 1.29, // 22/17
      ),

      // Subhead - 15pt (Regular) - Secondary body text
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.24,
        height: 1.33, // 20/15
      ),

      // Footnote - 13pt (Regular)
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.08,
        height: 1.38, // 18/13
      ),

      // Callout - 16pt (Semibold) - Button Text
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.32,
        height: 1.31, // 21/16
      ),

      // Caption 1 - 12pt (Regular)
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.33, // 16/12
      ),

      // Caption 2 - 11pt (Regular) - Icon Labels
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.06,
        height: 1.45, // 16/11
      ),
    );
  }

  /// Quick access to commonly used text styles
  /// These map directly to Apple HIG text styles

  // Title styles
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.37,
  );

  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.36,
  );

  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.35,
  );

  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.38,
  );

  // Content styles
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
  );

  static const TextStyle body = TextStyle(
    fontSize:17 ,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
  );

  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
  );

  static const TextStyle subhead = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
  );

  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
  );

  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.06,
  );
}

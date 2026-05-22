import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  // Brand display — kept as Fraunces italic for the Pulso wordmark only.
  static TextStyle display = GoogleFonts.fraunces(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    height: 1.2,
  );

  // Section headings, screen titles (e.g. username on profile, "Edit Profile").
  static TextStyle headline = GoogleFonts.dmSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  // Card titles, dialog titles, bold labels.
  static TextStyle title = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body text, captions, post content.
  static TextStyle body = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  // Helper text, timestamps, small labels.
  static TextStyle caption = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Buttons, tab bar items, form labels.
  static TextStyle label = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Timestamps, metadata, stat numbers.
  static TextStyle timestamp = GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );
}

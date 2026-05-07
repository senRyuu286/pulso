import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  static TextStyle display = GoogleFonts.fraunces(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static TextStyle headline = GoogleFonts.fraunces(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle title = GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle body = GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static TextStyle caption = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle label = GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle timestamp = GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );
}
import 'package:flutter/material.dart';

/// Spacing scale. Use only these values for padding, gaps and margins.
abstract final class AppSpacing {
  static const double xxs = 4, xs = 8, sm = 12, md = 16, lg = 24, xl = 32;
}

/// Corner radii. Use only these values.
abstract final class AppRadius {
  static const double sm = 8, md = 18, lg = 32, full = 999;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get fullAll => BorderRadius.circular(full);
}

/// Text styles. Colors are applied by the theme or at the call site.
abstract final class AppText {
  static const String body = 'Inter', display = 'Exo 2';

  static const displayLarge = TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 26,
      height: 1.0);
  static const displayMedium = TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 20,
      height: 1.0);
  static const displaySmall = TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 16,
      height: 1.0);

  static const headingXL = TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w600,
      fontSize: 32,
      height: 1.25);
  static const headingL = TextStyle(
      fontFamily: body, fontWeight: FontWeight.w600, fontSize: 24, height: 1.3);
  static const headingM = TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w600,
      fontSize: 20,
      height: 1.35);
  static const headingS = TextStyle(
      fontFamily: body, fontWeight: FontWeight.w600, fontSize: 16, height: 1.4);

  static const body14 = TextStyle(
      fontFamily: body, fontWeight: FontWeight.w500, fontSize: 14, height: 1.4);
  static const bodyStrong = TextStyle(
      fontFamily: body, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4);
  static const bodyRegular = TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 1.45);

  static const caption = TextStyle(
      fontFamily: body, fontWeight: FontWeight.w400, fontSize: 12, height: 1.5);
  static const captionStrong = TextStyle(
      fontFamily: body, fontWeight: FontWeight.w600, fontSize: 12, height: 1.4);
  static const micro = TextStyle(
      fontFamily: body, fontWeight: FontWeight.w400, fontSize: 10, height: 1.4);
  static const microStrong = TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w600,
      fontSize: 10,
      height: 1.4,
      letterSpacing: 0.4);
}

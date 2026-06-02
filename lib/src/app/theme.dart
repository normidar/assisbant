import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Design tokens (mirrored from prototype CSS) ───────────────────────────
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.ink4,
    required this.border,
    required this.border2,
    required this.accent,
    required this.accentSoft,
    required this.stPending,
    required this.stPendingBg,
    required this.stRunning,
    required this.stRunningBg,
    required this.stDone,
    required this.stDoneBg,
    required this.stFailed,
    required this.stFailedBg,
    required this.stSkipped,
    required this.stSkippedBg,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color ink4;
  final Color border;
  final Color border2;
  final Color accent;
  final Color accentSoft;
  final Color stPending;
  final Color stPendingBg;
  final Color stRunning;
  final Color stRunningBg;
  final Color stDone;
  final Color stDoneBg;
  final Color stFailed;
  final Color stFailedBg;
  final Color stSkipped;
  final Color stSkippedBg;

  static const light = AppColors(
    bg: Color(0xFFF5F2EC),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFFAF7F1),
    surface3: Color(0xFFF0EBE2),
    ink: Color(0xFF1C1A17),
    ink2: Color(0xFF44403A),
    ink3: Color(0xFF76716A),
    ink4: Color(0xFF9C9790),
    border: Color(0xFFE5DFD3),
    border2: Color(0xFFEFEAE0),
    accent: Color(0xFFC2502F),
    accentSoft: Color(0xFFF7E6DE),
    stPending: Color(0xFF4A6FB5),
    stPendingBg: Color(0xFFE8EEF8),
    stRunning: Color(0xFFC97B2A),
    stRunningBg: Color(0xFFFBEEDC),
    stDone: Color(0xFF4F8060),
    stDoneBg: Color(0xFFE4EFE7),
    stFailed: Color(0xFFB5443A),
    stFailedBg: Color(0xFFF6E1DD),
    stSkipped: Color(0xFF9C9790),
    stSkippedBg: Color(0xFFECE8DF),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? ink4,
    Color? border,
    Color? border2,
    Color? accent,
    Color? accentSoft,
    Color? stPending,
    Color? stPendingBg,
    Color? stRunning,
    Color? stRunningBg,
    Color? stDone,
    Color? stDoneBg,
    Color? stFailed,
    Color? stFailedBg,
    Color? stSkipped,
    Color? stSkippedBg,
  }) => AppColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    surface2: surface2 ?? this.surface2,
    surface3: surface3 ?? this.surface3,
    ink: ink ?? this.ink,
    ink2: ink2 ?? this.ink2,
    ink3: ink3 ?? this.ink3,
    ink4: ink4 ?? this.ink4,
    border: border ?? this.border,
    border2: border2 ?? this.border2,
    accent: accent ?? this.accent,
    accentSoft: accentSoft ?? this.accentSoft,
    stPending: stPending ?? this.stPending,
    stPendingBg: stPendingBg ?? this.stPendingBg,
    stRunning: stRunning ?? this.stRunning,
    stRunningBg: stRunningBg ?? this.stRunningBg,
    stDone: stDone ?? this.stDone,
    stDoneBg: stDoneBg ?? this.stDoneBg,
    stFailed: stFailed ?? this.stFailed,
    stFailedBg: stFailedBg ?? this.stFailedBg,
    stSkipped: stSkipped ?? this.stSkipped,
    stSkippedBg: stSkippedBg ?? this.stSkippedBg,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      ink4: Color.lerp(ink4, other.ink4, t)!,
      border: Color.lerp(border, other.border, t)!,
      border2: Color.lerp(border2, other.border2, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      stPending: Color.lerp(stPending, other.stPending, t)!,
      stPendingBg: Color.lerp(stPendingBg, other.stPendingBg, t)!,
      stRunning: Color.lerp(stRunning, other.stRunning, t)!,
      stRunningBg: Color.lerp(stRunningBg, other.stRunningBg, t)!,
      stDone: Color.lerp(stDone, other.stDone, t)!,
      stDoneBg: Color.lerp(stDoneBg, other.stDoneBg, t)!,
      stFailed: Color.lerp(stFailed, other.stFailed, t)!,
      stFailedBg: Color.lerp(stFailedBg, other.stFailedBg, t)!,
      stSkipped: Color.lerp(stSkipped, other.stSkipped, t)!,
      stSkippedBg: Color.lerp(stSkippedBg, other.stSkippedBg, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get ac => Theme.of(this).extension<AppColors>()!;
}

ThemeData buildAppTheme() {
  const c = AppColors.light;
  final base = ThemeData.light(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    colorScheme: ColorScheme.light(
      primary: c.accent,
      surface: c.surface,
      onSurface: c.ink,
      outline: c.border,
    ),
    textTheme: GoogleFonts.ibmPlexSansTextTheme(base.textTheme).apply(
      bodyColor: c.ink,
      displayColor: c.ink,
    ),
    extensions: const [c],
    dividerColor: c.border,
    cardColor: c.surface,
    dialogTheme: DialogThemeData(backgroundColor: c.surface),
  );
}

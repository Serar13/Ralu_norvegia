///
/// Utilities for ISO weeks (Monday = first day)
///
/// All functions below are timezone-agnostic for a given local `DateTime`
/// (they only use Y/M/D parts).

/// Returns the Monday of the ISO week containing [d].
DateTime startOfIsoWeek(DateTime d) {
  final local = DateTime(d.year, d.month, d.day);
  // weekday: Mon=1..Sun=7 -> subtract (weekday-1) to get Monday
  return local.subtract(Duration(days: local.weekday - 1));
}

/// Returns the Sunday of the ISO week containing [d].
DateTime endOfIsoWeek(DateTime d) {
  final start = startOfIsoWeek(d);
  return start.add(const Duration(days: 6));
}

/// Returns a stable ISO week ID like `Y2025-W36` for the date [d].
String weekIdFor(DateTime d) {
  // ISO week-numbering year is based on the Thursday of the current week.
  final local = DateTime(d.year, d.month, d.day);
  final weekday = local.weekday; // Mon=1..Sun=7
  // Shift to Thursday in the same week:
  final thursday = local.add(Duration(days: 3 - ((weekday + 6) % 7)));
  final isoYear = thursday.year;

  // Find the Monday of the week containing Jan 4th (which is always in week 1)
  final jan4 = DateTime(isoYear, 1, 4);
  final jan4Weekday = jan4.weekday; // Mon=1..Sun=7
  final firstWeekStart = jan4.subtract(Duration(days: jan4Weekday - 1)); // Monday of week 1

  // Compute 0-based week index from the Monday of week 1, then +1
  final daysSince = thursday.difference(firstWeekStart).inDays;
  final isoWeek = (daysSince ~/ 7) + 1;

  return 'Y$isoYear-W${isoWeek.toString().padLeft(2, '0')}';
}
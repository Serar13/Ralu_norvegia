import 'package:cloud_firestore/cloud_firestore.dart';

Future<int> calculateStreak(String uid) async {
  final now = DateTime.now();
  int streak = 0;

  DateTime current = now;
  while (true) {
    final weekKey = _yearWeekKey(current);
    final dayKey = _dayKey(current);

    final dayRef = FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('userProgress').doc(weekKey)
        .collection('days').doc(dayKey);

    final daySnap = await dayRef.get();
    if (!daySnap.exists) break;

    final locs = await dayRef.collection('locations').get();
    if (locs.docs.isEmpty) break;

    bool allDone = true;
    for (final d in locs.docs) {
      final data = d.data();
      final tasks = List<String>.from(data['tasks'] ?? const []);
      final doneMap = Map<String, dynamic>.from(data['done'] ?? {});
      for (int i = 0; i < tasks.length; i++) {
        if ((doneMap['$i'] ?? false) != true) {
          allDone = false;
          break;
        }
      }
      if (!allDone) break;
    }

    if (!allDone) {
      // ziua curentă (galbenă) incompletă → streak = 0
      if (_isSameDate(current, now)) {
        // streak = 0;
        current = current.subtract(const Duration(days: 1));
        continue;
      } else {
        break;
      }
    }

    streak++;
    current = current.subtract(const Duration(days: 1));
  }

  return streak;
}

String _dayKey(DateTime d) {
  const map = {
    DateTime.monday: 'Luni',
    DateTime.tuesday: 'Marti',
    DateTime.wednesday: 'Miercuri',
    DateTime.thursday: 'Joi',
    DateTime.friday: 'Vineri',
    DateTime.saturday: 'Sambata',
    DateTime.sunday: 'Duminica',
  };
  return map[d.weekday]!;
}

String _yearWeekKey(DateTime d) {
  final thursday = d.add(Duration(days: 3 - ((d.weekday + 6) % 7)));
  final firstThursday = DateTime(thursday.year, 1, 4);
  final firstWeekStart =
  firstThursday.subtract(Duration(days: (firstThursday.weekday + 6) % 7));
  final week = ((thursday.difference(firstWeekStart).inDays) / 7).floor() + 1;
  final year = thursday.year;
  return 'Y$year-W${week.toString().padLeft(2, '0')}';
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/utils/week_utils.dart';

class CalendarWeekView extends StatefulWidget {
  const CalendarWeekView({super.key});
  @override
  State<CalendarWeekView> createState() => _CalendarWeekViewState();
}

class _CalendarWeekViewState extends State<CalendarWeekView> {
  DateTime? _accountCreatedAt;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  bool _isWithinAccountRange(DateTime d) {
    if (_accountCreatedAt == null) return false;
    final cd = DateTime(_accountCreatedAt!.year, _accountCreatedAt!.month, _accountCreatedAt!.day);
    final today = DateTime.now();
    final dd = DateTime(d.year, d.month, d.day);
    return !dd.isBefore(cd) && !dd.isAfter(today);
  }

  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late DateTime _monday; // începutul săptămânii curente
  late DateTime _friday; // finalul săptămânii de lucru (Luni–Vineri)

  // Cache progress per day (date-only key) to avoid async flicker
  final Map<int, double> _progressCache = {};
  final List<StreamSubscription> _weekSubs = [];

  int _dateKeyInt(DateTime d) => DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;

  double? _cachedProgress(DateTime d) => _progressCache[_dateKeyInt(d)];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _monday = _startOfWeek(_focusedDay);
    _friday = _monday.add(const Duration(days: 4));

    _loadAccountCreatedDate().then((_) {
      _loadAllProgressFromAccountCreation();

      if (_isCurrentIsoWeek(_monday)) {
        _ensureWeekInitializedForMonday(_monday).then((_) {
          if (mounted) _attachCurrentWeekListeners();
        });
      } else {
        if (mounted) _attachCurrentWeekListeners();
      }
    });
  }

  Future<void> _loadAccountCreatedDate() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final ts = doc.data()?['createdAt'];
    if (ts is Timestamp) {
      _accountCreatedAt = ts.toDate();
    } else {
      _accountCreatedAt = DateTime.now(); // fallback de siguranță
    }
  }

  void _attachCurrentWeekListeners() {
    // Cancel previous listeners
    for (final s in _weekSubs) { s.cancel(); }
    _weekSubs.clear();

    for (int i = 0; i < 5; i++) {
      final day = _monday.add(Duration(days: i));
      final week = _yearWeekKey(day);
      final dayName = _dayKey(day);
      final key = _dateKeyInt(day);

      final sub = FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('userProgress').doc(week)
          .collection('days').doc(dayName)
          .collection('locations')
          .snapshots()
          .listen((qs) {
        int done = 0, total = 0;
        for (final d in qs.docs) {
          final data = d.data();
          final tasks = List<String>.from(data['tasks'] ?? const <String>[]);
          final doneMap = Map<String, dynamic>.from(data['done'] ?? {});
          total += tasks.length;
          for (var i = 0; i < tasks.length; i++) {
            if ((doneMap['$i'] ?? false) == true) done++;
          }
        }
        final value = total == 0 ? 0.0 : (done / total);
        if (mounted) {
          setState(() { _progressCache[key] = value; });
        }
      });

      _weekSubs.add(sub);
    }
  }

  Future<void> _loadAllProgressFromAccountCreation() async {
    final creationDate = FirebaseAuth.instance.currentUser!.metadata.creationTime!;
    final now = DateTime.now();
    DateTime current = _startOfWeek(creationDate); // luni din săptămâna contului

    while (!current.isAfter(now)) {
      final weekKey = _yearWeekKey(current);
      for (int i = 0; i < 5; i++) {
        final day = current.add(Duration(days: i));
        final dayName = _dayKey(day);
        final key = _dateKeyInt(day);

        final locs = await FirebaseFirestore.instance
            .collection('users').doc(uid)
            .collection('userProgress').doc(weekKey)
            .collection('days').doc(dayName)
            .collection('locations')
            .get();

        int done = 0, total = 0;
        for (final d in locs.docs) {
          final data = d.data();
          final tasks = List<String>.from(data['tasks'] ?? const <String>[]);
          final doneMap = Map<String, dynamic>.from(data['done'] ?? {});
          total += tasks.length;
          for (int i = 0; i < tasks.length; i++) {
            if ((doneMap['$i'] ?? false) == true) done++;
          }
        }
        final progress = total == 0 ? 0.0 : (done / total);
        _progressCache[key] = progress;
      }
      current = current.add(const Duration(days: 7));
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final s in _weekSubs) { s.cancel(); }
    super.dispose();
  }

  DateTime get _today => DateTime.now();

  bool _isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isPastWeek(DateTime d) {
    final dd = DateTime(d.year, d.month, d.day);
    return dd.isBefore(_monday);
  }

  bool _isFutureWeek(DateTime d) {
    final dd = DateTime(d.year, d.month, d.day);
    return dd.isAfter(_friday);
  }

  bool _isFutureInCurrentWeek(DateTime d) {
    final dd = DateTime(d.year, d.month, d.day);
    final today = DateTime(_today.year, _today.month, _today.day);
    return _isInCurrentWorkWeek(dd) && dd.isAfter(today);
  }

  bool _isSelectable(DateTime d) {
    // selectabil doar în săptămâna curentă și nu în avans (maxim azi)
    final dd = DateTime(d.year, d.month, d.day);
    final today = DateTime(_today.year, _today.month, _today.day);
    return _isInCurrentWorkWeek(dd) && (dd.isBefore(today) || _isSameCalendarDay(dd, today));
  }

  DateTime _startOfWeek(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  // Este aceeași săptămână ISO ca azi?
  bool _isCurrentIsoWeek(DateTime anyDayOfWeek) {
    final idNow = weekIdFor(DateTime.now());
    final idThat = weekIdFor(anyDayOfWeek);
    return idNow == idThat;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isInCurrentWorkWeek(DateTime d) {
    final dd = DateTime(d.year, d.month, d.day);
    return !dd.isBefore(_monday) && !dd.isAfter(_friday);
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

  Future<void> _ensureWeekInitializedForMonday(DateTime monday) async {
    if (!_isCurrentIsoWeek(monday)) return;

    int isoWeekNumber(DateTime date) {
      final thursday = date.add(Duration(days: 3 - ((date.weekday + 6) % 7)));
      final firstThursday = DateTime(thursday.year, 1, 4);
      final firstWeekStart =
          firstThursday.subtract(Duration(days: (firstThursday.weekday + 6) % 7));
      return ((thursday.difference(firstWeekStart).inDays) / 7).floor() + 1;
    }
    String ukeFor(DateTime d) {
      final w = isoWeekNumber(d);
      final idx = ((w - 1) % 4) + 1;
      return 'Uke $idx';
    }

    final weekKey = _yearWeekKey(monday);
    final weekRef = FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('userProgress').doc(weekKey);

    // dacă există deja vreo zi, ne oprim
    for (final dn in const ['Luni','Marti','Miercuri','Joi','Vineri']) {
      final snap = await weekRef.collection('days').doc(dn).get();
      if (snap.exists) return;
    }

    final uke = ukeFor(monday);
    for (final dn in const ['Luni','Marti','Miercuri','Joi','Vineri']) {
      final legacy = await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('weeklyTasks').doc(uke)
          .collection('days').doc(dn)
          .get();

      if (!legacy.exists) {
        await weekRef.collection('days').doc(dn).set({});
        continue;
      }

      final data = legacy.data() as Map<String, dynamic>;
      final suprafata = data['suprafata'];
      final nrLoc = int.tryParse('${data['nrLoc'] ?? '0'}') ?? 0;
      final List<String> tasks = List<String>.from(data['tasks'] ?? const <String>[]);

      await weekRef.collection('days').doc(dn).set({
        if (suprafata != null) 'suprafata': suprafata,
      }, SetOptions(merge: true));

      for (int i = 0; i < nrLoc; i++) {
        final key = (i == 0) ? 'locatie' : 'locatie$i';
        final name = (data[key]?.toString().trim().isNotEmpty ?? false)
            ? data[key].toString()
            : 'Locație ${i + 1}';
        await weekRef
            .collection('days').doc(dn)
            .collection('locations').doc('loc_$i')
            .set({
          'index': i,
          'name': name,
          'tasks': tasks,
        }, SetOptions(merge: true));
      }
    }
  }

  // String _weekLabel(DateTime d) {
  //   final startOfYear = DateTime(d.year, 1, 1);
  //   final days = d.difference(startOfYear).inDays + 1;
  //   final weekOfYear = (days / 7).ceil();
  //   final ukeIndex = (weekOfYear - 1) % 4 + 1;
  //   return 'Uke $ukeIndex';
  // }

  // ===== ISO week helpers =====
  int _isoWeekday(DateTime d) => d.weekday; // 1=Mon .. 7=Sun

  int _isoWeekYear(DateTime date) {
    // ISO year = anul zilei de joi din săptămâna curentă
    final thursday = date.add(Duration(days: 3 - ((_isoWeekday(date) + 6) % 7)));
    return thursday.year;
  }

  int _isoWeekNumber(DateTime date) {
    // Mutăm pe joi (ISO)
    final thursday = date.add(Duration(days: 3 - ((_isoWeekday(date) + 6) % 7)));
    // Prima joi din anul ISO
    final firstThursday = DateTime(thursday.year, 1, 4);
    // Începutul săptămânii ce conține 4 ianuarie (start ISO week 1)
    final firstWeekStart =
    firstThursday.subtract(Duration(days: (firstThursday.weekday + 6) % 7));
    return ((thursday.difference(firstWeekStart).inDays) / 7).floor() + 1;
  }

  /// Cheie unică de săptămână: Y2025-W36
  String _yearWeekKey(DateTime d) {
    final week = _isoWeekNumber(d);
    final year = _isoWeekYear(d);
    return 'Y$year-W${week.toString().padLeft(2, '0')}';
  }

  Future<double> _completionForDay(DateTime date) async {
    // Compute progress for *any* date (past/current/future). If the
    // data for that week/day doesn't exist yet, we fall back to 0.0.
    final week = _yearWeekKey(date);
    final day = _dayKey(date);

    final locs = await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('userProgress').doc(week)
        .collection('days').doc(day)
        .collection('locations')
        .get();

    int done = 0, total = 0;
    for (final d in locs.docs) {
      final data = d.data();
      final tasks = List<String>.from(data['tasks'] ?? const <String>[]);
      final doneMap = Map<String, dynamic>.from(data['done'] ?? {});
      total += tasks.length;
      for (int i = 0; i < tasks.length; i++) {
        if ((doneMap['$i'] ?? false) == true) {
          done++;
        }
      }
    }

    if (total == 0) return 0.0; // nothing defined for that day
    return done / total; // 0..1
  }

  Color _colorForProgress(double p) {
    if (p <= 0) return Colors.red;      // nimic făcut
    if (p < 1.0) return Colors.orange;  // parțial
    return Colors.green;                // complet
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar (săptămâna curentă)'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TableCalendar(
              firstDay: _accountCreatedAt ?? DateTime.now(),
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) => _isSameDay(day, _selectedDay),
              availableGestures: AvailableGestures.horizontalSwipe,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                isTodayHighlighted: true,
                outsideDaysVisible: true,
                todayDecoration: BoxDecoration(
                  color: AppColors.accent3.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(color: Colors.black),
                weekendTextStyle: const TextStyle(color: Colors.white70),
                defaultTextStyle: const TextStyle(color: Colors.white),
                outsideTextStyle: const TextStyle(color: Colors.white38),
              ),
              onDaySelected: (selectedDay, focusedDay) async {
                if (!_isSelectable(selectedDay) || !_isWithinAccountRange(selectedDay)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nu poți selecta zile în afara săptămânii curente, în avans sau înainte de crearea contului.')),
                  );
                  return;
                }
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                Navigator.of(context).pop<DateTime>(selectedDay);
              },
              onPageChanged: (focusedDay) async {
                setState(() {
                  _focusedDay = focusedDay;
                  _monday = _startOfWeek(_focusedDay);
                  _friday = _monday.add(const Duration(days: 4));
                });
                // Lazy-create doar pentru săptămâna curentă
                if (_isCurrentIsoWeek(_monday)) {
                  await _ensureWeekInitializedForMonday(_monday);
                }
                if (mounted) {
                  _attachCurrentWeekListeners();
                }
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final isPastW = _isPastWeek(day);
                  final isFutureW = _isFutureWeek(day);
                  final isFutureCur = _isFutureInCurrentWeek(day);

                  // Zile în afara intervalului contului: estompat complet
                  if (!_isWithinAccountRange(day)) {
                    return Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('${day.day}', style: const TextStyle(color: Colors.white12)),
                    );
                  }

                  // Săptămâni viitoare: estompat
                  if (isFutureW) {
                    return Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('${day.day}', style: const TextStyle(color: Colors.white38)),
                    );
                  }

                  // Săptămâni trecute: culoare după progres + lacăt
                  if (isPastW) {
                    return FutureBuilder<double>(
                      future: _completionForDay(day),
                      builder: (context, snap) {
                        final p = snap.data ?? 0.0;
                        final color = _colorForProgress(p).withOpacity(0.25);
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text('${day.day}', style: const TextStyle(color: Colors.white)),
                            ),
                            const Positioned(
                              right: 2,
                              bottom: 2,
                              child: Icon(Icons.lock, size: 12, color: Colors.white70),
                            ),
                          ],
                        );
                      },
                    );
                  }

                  // Zile viitoare din săptămâna curentă: marcate, dar blocate
                  if (isFutureCur) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white24.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Text('${day.day}', style: const TextStyle(color: Colors.white60)),
                    );
                  }

                  // Zile valide (curente până la azi): culoare după progres
                  final p = _cachedProgress(day);
                  final color = p == null
                      ? Colors.white24.withOpacity(0.15)
                      : _colorForProgress(p).withOpacity(0.25);
                  return Container(
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('${day.day}', style: const TextStyle(color: Colors.white)),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  if (!_isWithinAccountRange(day)) {
                    return Container(
                      alignment: Alignment.center,
                      child: Text('${day.day}', style: const TextStyle(color: Colors.white12)),
                    );
                  }
                  if (!_isInCurrentWorkWeek(day)) {
                    return Container(
                      alignment: Alignment.center,
                      child: Text('${day.day}', style: const TextStyle(color: Colors.white)),
                    );
                  }
                  final p = _cachedProgress(day);
                  final base = p == null ? Colors.white24 : _colorForProgress(p);
                  return Container(
                    decoration: BoxDecoration(
                      color: base.withOpacity(0.35),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent3, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text('${day.day}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  );
                },
                selectedBuilder: (context, day, focusedDay) {
                  if (!_isSelectable(day) || !_isWithinAccountRange(day)) {
                    return Container(
                      alignment: Alignment.center,
                      child: Text('${day.day}', style: const TextStyle(color: Colors.white54)),
                    );
                  }
                  final p = _cachedProgress(day);
                  final base = p == null ? Colors.white54 : _colorForProgress(p);
                  return Container(
                    decoration: BoxDecoration(color: base.withOpacity(0.6), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('${day.day}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: const [
                _Legend(color: Colors.red, label: 'Nefăcut'),
                SizedBox(width: 12),
                _Legend(color: Colors.orange, label: 'În progres'),
                SizedBox(width: 12),
                _Legend(color: Colors.green, label: 'Complet'),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

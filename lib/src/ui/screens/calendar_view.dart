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
  DateTime? _loadingMonth;
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
  bool _isInitialLoadDone = false;
  // Cache progress per day (date-only key) to avoid async flicker
  final Map<int, double> _progressCache = {};
  final Map<int, double> _liveWeekCache = {};
  final List<StreamSubscription> _weekSubs = [];

  int _dateKeyInt(DateTime d) => DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;

  double? _cachedProgress(DateTime d) {
    final key = _dateKeyInt(d);
    final val = _progressCache[key];
    final live = _liveWeekCache[key];
    debugPrint("🔍 _cachedProgress($d) => progress=$val live=$live");
    if (_isInCurrentWorkWeek(d)) {
      return live ?? val;
    }
    return val;
  }

  @override
  void initState() {
    super.initState();
    debugPrint("🚀 CalendarWeekView initState");
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _monday = _startOfWeek(_focusedDay);
    _friday = _monday.add(const Duration(days: 4));

    _loadAccountCreatedDate().then((_) {
      _loadAllProgressFromAccountCreation();
      _loadAccountCreatedDate().then((_) async {
        await _loadAllProgressFromAccountCreation();

        if (!mounted) return;
        setState(() {
          _isInitialLoadDone = true;
        });

        if (_isCurrentIsoWeek(_monday)) {
          _ensureWeekInitializedForMonday(_monday).then((_) {
            if (!mounted) return;
            _attachCurrentWeekListeners();
          });
          await _ensureWeekInitializedForMonday(_monday);
          if (!mounted) return;
          _attachCurrentWeekListeners();
        }
      });
    }
    );

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
    debugPrint("🔗 Attaching listeners for week $_monday - $_friday");
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
        debugPrint("📡 Live update $dayName ($day): $value");
        if (mounted) {
          setState(() {
            _liveWeekCache[key] = value;
            debugPrint("💾 Updated liveWeekCache[$key] = $value");
          });
        }
      });

      _weekSubs.add(sub);
    }
  }

  Future<void> _loadAllProgressFromAccountCreation() async {
    final creationDate = DateTime(_accountCreatedAt!.year, _accountCreatedAt!.month, _accountCreatedAt!.day);
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
    debugPrint("🛑 CalendarWeekView dispose");
    for (final s in _weekSubs) { s.cancel(); }
    _liveWeekCache.clear();
    super.dispose();
  }

  DateTime get _today => DateTime.now();

  bool _isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isWeekend(DateTime d) =>
      d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  bool _isPastWeek(DateTime d) {
    final todayMonday = _startOfWeek(DateTime.now());
    final dd = DateTime(d.year, d.month, d.day);
    return dd.isBefore(todayMonday);
  }

  bool _isFutureWeek(DateTime d) {
    final todayFriday = _startOfWeek(DateTime.now()).add(const Duration(days: 4));
    final dd = DateTime(d.year, d.month, d.day);
    return dd.isAfter(todayFriday);
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
    final todayMonday = _startOfWeek(DateTime.now());
    final todayFriday = todayMonday.add(const Duration(days: 4));
    final dd = DateTime(d.year, d.month, d.day);
    return !dd.isBefore(todayMonday) && !dd.isAfter(todayFriday);
  }

  Future<void> _loadAllProgressForMonth(DateTime date) async {
    debugPrint("📅 Start loading month ${date.month}/${date.year}");
    final firstOfMonth = DateTime(date.year, date.month, 1);
    final lastOfMonth = DateTime(date.year, date.month + 1, 0);

    DateTime current = _startOfWeek(firstOfMonth);

    while (!current.isAfter(lastOfMonth)) {
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
        debugPrint("  ➡️ Saving progress for $day = $progress");
        if (!_progressCache.containsKey(key)) {
          _progressCache[key] = progress;
        }
      }
      current = current.add(const Duration(days: 7));
    }

    debugPrint("✅ Finished loading month ${date.month}/${date.year}");
    if (mounted) setState(() {});
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
    if (_accountCreatedAt == null || !_isInitialLoadDone) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text(
          'Kalender',
          style: TextStyle(
            color: AppColors.accentDark,
            fontFamily: 'Kanit',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: TableCalendar(
                    locale:'no_NO',
                    firstDay: _accountCreatedAt!,
                    lastDay: DateTime.now(),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    selectedDayPredicate: (day) => _isSameDay(day, _selectedDay),
                    availableGestures: AvailableGestures.horizontalSwipe,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        color: AppColors.accentDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Kanit',
                      ),
                      leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.accent3),
                      rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.accent3),
                    ),
                    calendarStyle: CalendarStyle(
                      isTodayHighlighted: true,
                      outsideDaysVisible: false,
                      todayDecoration: BoxDecoration(
                        color: AppColors.accent3.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accent3, width: 1.5),
                      ),
                      selectedDecoration: BoxDecoration(
                        color: AppColors.accent3,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: const TextStyle(color: Colors.white),
                      weekendTextStyle: const TextStyle(
                        color: AppColors.primaryText2,
                        fontFamily: 'Kanit',
                      ),
                      defaultTextStyle: const TextStyle(
                        color: AppColors.primaryText,
                        fontFamily: 'Kanit',
                      ),
                      outsideTextStyle: const TextStyle(
                        color: AppColors.primaryText2,
                        fontFamily: 'Kanit',
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) async {
                      if (!_isSelectable(selectedDay) || !_isWithinAccountRange(selectedDay)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Zi nepermisă.')),
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
                      await _handlePageChange(focusedDay);
                    },
                    calendarBuilders: calendarBuilders(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _Legend(color: Colors.red, label: 'Ikke gjort'),
                  SizedBox(width: 16),
                  _Legend(color: Colors.orange, label: 'I gang'),
                  SizedBox(width: 16),
                  _Legend(color: Colors.green, label: 'Fullført'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePageChange(DateTime focusedDay) async {
    debugPrint("📖 Page changed to ${focusedDay.month}/${focusedDay.year}");
    final first = DateTime(_accountCreatedAt!.year, _accountCreatedAt!.month, _accountCreatedAt!.day);
    final last = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final clamped = focusedDay.isBefore(first)
        ? first
        : focusedDay.isAfter(last)
            ? last
            : focusedDay;
    if (_loadingMonth != null &&
        _loadingMonth!.year == clamped.year &&
        _loadingMonth!.month == clamped.month) {
      debugPrint("⚠️ Skip duplicate load for ${clamped.month}/${clamped.year}");
      return;
    }
    _loadingMonth = clamped;
    if (mounted) {
      setState(() {
        _focusedDay = clamped;
        _monday = _startOfWeek(clamped);
        _friday = _monday.add(const Duration(days: 4));
      });
    }
    debugPrint("📅 Start loading month ${clamped.month}/${clamped.year}");
    await _loadAllProgressForMonth(clamped);
    if (!mounted) return;
    if (_loadingMonth != null &&
        (_loadingMonth!.year != clamped.year || _loadingMonth!.month != clamped.month)) {
      debugPrint("⏭️ Skipping outdated load for ${clamped.month}/${clamped.year}");
      return;
    }
    final monday = _startOfWeek(clamped);
    if (_isSameDay(monday, _startOfWeek(DateTime.now()))) {
      await _ensureWeekInitializedForMonday(monday);
      if (mounted) _attachCurrentWeekListeners();
    }
    debugPrint("✅ Finished month load ${clamped.month}/${clamped.year}");
    _loadingMonth = null;
  }

  CalendarBuilders calendarBuilders() {
    return CalendarBuilders(
      defaultBuilder: (context, day, focusedDay) {
        final isPastW = _isPastWeek(day);
        final isFutureW = _isFutureWeek(day);
        final isFutureCur = _isFutureInCurrentWeek(day);
        if (!_isWithinAccountRange(day)) {
          return Container(
            decoration: const BoxDecoration(shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: const TextStyle(
                color: AppColors.primaryText2,
                fontFamily: 'Kanit',
              ),
            ),
          );
        }
        if (isFutureW) {
          return Container(
            decoration: const BoxDecoration(shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: const TextStyle(
                color: AppColors.primaryText2,
                fontFamily: 'Kanit',
              ),
            ),
          );
        }
        if (_isWeekend(day)) {
          final isPastWeekend = day.isBefore(_startOfWeek(DateTime.now()));
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryText2.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: isPastWeekend
                      ? null
                      : Border.all(color: AppColors.primaryText2.withOpacity(0.12), width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: const TextStyle(
                    color: AppColors.primaryText2,
                    fontFamily: 'Kanit',
                  ),
                ),
              ),
              if (isPastWeekend)
                const Positioned(
                  right: 2,
                  bottom: 2,
                  child: Icon(Icons.lock, size: 12, color: AppColors.primaryText2),
                ),
            ],
          );
        }
        if (isPastW) {
          final p = _cachedProgress(day);
          final color = p == null
              ? AppColors.primaryText2.withOpacity(0.08)
              : _colorForProgress(p).withOpacity(0.22);
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontFamily: 'Kanit',
                  ),
                ),
              ),
              const Positioned(
                right: 2,
                bottom: 2,
                child: Icon(Icons.lock, size: 12, color: AppColors.primaryText2),
              ),
            ],
          );
        }
        if (isFutureCur) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.primaryText2.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryText2.withOpacity(0.12), width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: const TextStyle(
                color: AppColors.primaryText2,
                fontFamily: 'Kanit',
              ),
            ),
          );
        }
        final p = _cachedProgress(day);
        final color = p == null
            ? AppColors.primaryText2.withOpacity(0.08)
            : _colorForProgress(p).withOpacity(0.22);
        return Container(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: const TextStyle(
              color: AppColors.primaryText,
              fontFamily: 'Kanit',
            ),
          ),
        );
      },
      todayBuilder: (context, day, focusedDay) {
        if (_isWeekend(day)) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.accent3.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent3, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.bold,
                fontFamily: 'Kanit',
              ),
            ),
          );
        }
        if (!_isWithinAccountRange(day)) {
          return Container(
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: const TextStyle(
                color: AppColors.primaryText2,
                fontFamily: 'Kanit',
              ),
            ),
          );
        }
        if (!_isInCurrentWorkWeek(day)) {
          return Container(
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontFamily: 'Kanit',
              ),
            ),
          );
        }
        final p = _cachedProgress(day);
        final base = p == null ? AppColors.primaryText2 : _colorForProgress(p);
        return Container(
          decoration: BoxDecoration(
            color: base.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent3, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: const TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
              fontFamily: 'Kanit',
            ),
          ),
        );
      },
      selectedBuilder: (context, day, focusedDay) {
        if (_isWeekend(day)) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.accent3.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Kanit',
              ),
            ),
          );
        }
        if (!_isSelectable(day) || !_isWithinAccountRange(day)) {
          return Container(
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: const TextStyle(
                color: AppColors.primaryText2,
                fontFamily: 'Kanit',
              ),
            ),
          );
        }
        final p = _cachedProgress(day);
        final base = p == null ? AppColors.accent3 : _colorForProgress(p);
        return Container(
          decoration: BoxDecoration(color: base.withOpacity(0.9), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Kanit',
            ),
          ),
        );
      },
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
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontFamily: 'Kanit',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

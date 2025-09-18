import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/utils/week_utils.dart';

class TodayView extends StatefulWidget {
  final ValueNotifier<DateTime?>? selectedDateNotifier;
  const TodayView({super.key, this.selectedDateNotifier});

  @override
  State<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<TodayView> with AutomaticKeepAliveClientMixin {
  final user = FirebaseAuth.instance.currentUser!;

  bool _loading = true;
  bool _hasLoadedOnce = false;

  late String currentDay;
  late String currentWeek;

  String? surfaceForToday;
  final List<String> allLocations = [];
  final List<List<String>> _tasksPerLocation = [];
  List<List<bool>> _isCheckedPerLocation = [];

  VoidCallback? _notifierListener;

  void _applyDate(DateTime date) {
    currentDay = _getDayFor(date);
    currentWeek = _getWeekFor(date);
    _loadTasksForDate(date);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentDay = _getDayFor(now);
    currentWeek = _getWeekFor(now);
    _loadEverything();
    _loadTasksForDate(now);
    if (widget.selectedDateNotifier != null) {
      _notifierListener = () {
        final d = widget.selectedDateNotifier!.value;
        if (d != null) {
          _applyDate(d);
        }
      };
      widget.selectedDateNotifier!.addListener(_notifierListener!);
    }
  }

  bool _isCurrentIsoWeek(DateTime d) => weekIdFor(d) == weekIdFor(DateTime.now());
  
  @override
  void dispose() {
    if (widget.selectedDateNotifier != null && _notifierListener != null) {
      widget.selectedDateNotifier!.removeListener(_notifierListener!);
    }
    super.dispose();
  }

  String _getDayFor(DateTime d) {
    const days = ['Luni','Marti','Miercuri','Joi','Vineri','Sambata','Duminica'];
    return days[d.weekday - 1];
  }

  // String _getWeekFor(DateTime d) {
  //   final weekOfYear = ((d.difference(DateTime(d.year, 1, 1)).inDays + 1) / 7).ceil();
  //   return 'Uke ${(weekOfYear - 1) % 4 + 1}';
  // }

  int _isoWeekday(DateTime d) => d.weekday; // 1=Mon..7=Sun

  String _getWeekFor(DateTime d) {
    // Construiește cheia ISO Yyyyy-Www (ex: Y2025-W36)
    final thursday = d.add(Duration(days: 3 - ((_isoWeekday(d) + 6) % 7)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstWeekStart =
    firstThursday.subtract(Duration(days: (firstThursday.weekday + 6) % 7));
    final week = ((thursday.difference(firstWeekStart).inDays) / 7).floor() + 1;
    final year = thursday.year;
    return 'Y$year-W${week.toString().padLeft(2, '0')}';
  }

  // ===== Lazy week initialization (from legacy weeklyTasks Uke 1..4) =====
  int _isoWeekNumber(DateTime date) {
    final thursday = date.add(Duration(days: 3 - ((date.weekday + 6) % 7)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstWeekStart =
    firstThursday.subtract(Duration(days: (firstThursday.weekday + 6) % 7));
    return ((thursday.difference(firstWeekStart).inDays) / 7).floor() + 1;
  }

  String _ukeFor(DateTime d) {
    final w = _isoWeekNumber(d);
    final idx = ((w - 1) % 4) + 1; // 1..4
    return 'Uke $idx';
  }

  Future<void> _ensureWeekInitialized(DateTime date) async {
    if (!_isCurrentIsoWeek(date)) return;

    final weekKey = _getWeekFor(date); // Yyyyy-Www
    final dayNames = const ['Luni','Marti','Miercuri','Joi','Vineri'];

    final weekRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userProgress')
        .doc(weekKey);

    // dacă există deja vreo zi, considerăm săptămâna inițializată
    for (final dn in dayNames) {
      final snap = await weekRef.collection('days').doc(dn).get();
      if (snap.exists) return;
    }

    // Construim din weeklyTasks (Uke 1..4) mapând ISO week % 4
    final uke = _ukeFor(date);
    for (final dn in dayNames) {
      final legacy = await FirebaseFirestore.instance
          .collection('users').doc(user.uid)
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
          // 'done': {} // se va completa la primele bife
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> _loadTasksForDate(DateTime date) async {
    try {
      await _ensureWeekInitialized(date);
      final week = _getWeekFor(date);
      final day = _getDayFor(date);
      currentDay = day;
      currentWeek = week;

      final dayRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userProgress')
          .doc(currentWeek)
          .collection('days')
          .doc(currentDay);

      final daySnap = await dayRef.get();

      if (!daySnap.exists) {
        if (!mounted) return;
        setState(() {
          surfaceForToday = null;
          allLocations.clear();
          _tasksPerLocation.clear();
          _isCheckedPerLocation = [];
        });
        return;
      }

      final dayData = daySnap.data() as Map<String, dynamic>? ?? {};
      surfaceForToday = dayData['suprafata']?.toString();

      final locsSnap = await dayRef
          .collection('locations')
          .orderBy('index')
          .get();

      allLocations.clear();
      _tasksPerLocation.clear();
      _isCheckedPerLocation = [];

      if (locsSnap.docs.isEmpty) {
        if (!mounted) return;
        setState(() {});
        return;
      }

      for (int li = 0; li < locsSnap.docs.length; li++) {
        final data = locsSnap.docs[li].data();
        allLocations.add(data['name']?.toString() ?? 'Locație ${li + 1}');
        final List<String> tasks = List<String>.from(data['tasks'] ?? const <String>[]);
        _tasksPerLocation.add(tasks);

        final Map<String, dynamic> doneMap = Map<String, dynamic>.from(data['done'] ?? {});
        final List<bool> row = List<bool>.generate(
          tasks.length,
          (ti) => (doneMap['$ti'] is bool) ? doneMap['$ti'] as bool : false,
        );
        _isCheckedPerLocation.add(row);
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading tasks for today: $e');
    }
  }

  DocumentReference<Map<String, dynamic>> _locationDocRef(int locIdx) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userProgress')
        .doc(currentWeek)
        .collection('days')
        .doc(currentDay)
        .collection('locations')
        .doc('loc_$locIdx');
  }

  Future<void> _saveCheckboxState(int locIdx, int taskIdx, bool value) async {
    try {
      await _locationDocRef(locIdx).update({
        'done.$taskIdx': value,
      });

      final allTasksDoneForLocation = _isCheckedPerLocation[locIdx].isNotEmpty &&
          _isCheckedPerLocation[locIdx].every((b) => b);
      await _locationDocRef(locIdx).set(
        {'completed': allTasksDoneForLocation},
        SetOptions(merge: true),
      );

      final allDone = _isCheckedPerLocation.isNotEmpty &&
          _isCheckedPerLocation.every((locRow) => locRow.isNotEmpty && locRow.every((b) => b));

      if (allDone) {
        _showCompletionDialog(context);
      }
    } catch (e) {
      debugPrint('Error saving checkbox state: $e');
    }
  }

  Future<void> _loadEverything() async {
    if (_hasLoadedOnce) return;
    try {
      await _loadTasksForDate(DateTime.now());
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasLoadedOnce = true;
      });
    } catch (e, s) {
      debugPrint('Error loading tasks for today: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  Future<void> _incrementStreak() async {
    final today = DateTime.now();
    final todayKey = "${today.year}-${today.month}-${today.day}";

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await userRef.get();

    final data = doc.data();
    final lastActiveDay = data?['lastActiveDay'];

    if (lastActiveDay != todayKey) {
      await userRef.set({
        'streakCount': FieldValue.increment(1),
        'lastActiveDay': todayKey,
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
          body: Container(
            color: AppColors.primary,
            child: Column(
              children: [
                // Header
                Container(
                  color: AppColors.accent3,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Current Week: $currentWeek",
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Day: $currentDay",
                          style: const TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 4),
                      if (allLocations.length == 1)
                        Text("Location: ${allLocations.first}",
                            style: const TextStyle(color: Colors.white, fontSize: 16)),
                      if (surfaceForToday != null)
                        Text("Suprafață: $surfaceForToday",
                            style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),

                // Tasks
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : (_tasksPerLocation.isEmpty || (_tasksPerLocation.every((l) => l.isEmpty)))
                      ? const Center(
                    child: Text("No tasks for today.",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  )
                      : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      if (allLocations.length > 1)
                        ...List.generate(allLocations.length, (locIdx) {
                          final tasks = _tasksPerLocation[locIdx];
                          return ExpansionTile(
                            title: Text(allLocations[locIdx], style: const TextStyle(fontWeight: FontWeight.bold)),
                            children: [
                              for (int ti = 0; ti < tasks.length; ti++)
                                Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ListTile(
                                    title: Text(tasks[ti]),
                                    trailing: Checkbox(
                                      value: _isCheckedPerLocation[locIdx][ti],
                                      onChanged: (bool? v) {
                                        setState(() {
                                          _isCheckedPerLocation[locIdx][ti] = v ?? false;
                                        });
                                        _saveCheckboxState(locIdx, ti, _isCheckedPerLocation[locIdx][ti]);
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                      if (allLocations.length == 1)
                        ...List.generate(_tasksPerLocation[0].length, (ti) {
                          final checked = (_isCheckedPerLocation.isNotEmpty && _isCheckedPerLocation[0][ti]);
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              title: Text(
                                _tasksPerLocation[0][ti],
                                style: TextStyle(
                                  color: checked ? Colors.grey : Colors.black,
                                  fontWeight: checked ? FontWeight.w300 : FontWeight.w500,
                                ),
                              ),
                              trailing: Checkbox(
                                value: checked,
                                onChanged: (bool? v) {
                                  setState(() {
                                    if (_isCheckedPerLocation.isEmpty) {
                                      _isCheckedPerLocation = [ List<bool>.filled(_tasksPerLocation[0].length, false), ];
                                    }
                                    _isCheckedPerLocation[0][ti] = v ?? false;
                                  });
                                  _saveCheckboxState(0, ti, _isCheckedPerLocation[0][ti]);
                                },
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }

  // (rămâne neschimbat; doar mesajul menționează o singură locație dacă există exact una)
  void _showCompletionDialog(BuildContext context) {
    final singleLoc = (allLocations.length == 1) ? allLocations.first : null;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Completion"),
          content: Text(
            singleLoc == null
                ? "Are you sure you have finished all tasks for $currentDay?"
                : "Are you sure you have finished all tasks for $singleLoc and completed the cleaning for $currentDay?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _incrementStreak();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Great! You finished cleaning for $currentDay!")),
                );
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }
}
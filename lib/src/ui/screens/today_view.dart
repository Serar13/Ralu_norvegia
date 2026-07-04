import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/utils/week_utils.dart';
import 'package:ralu_norvegia/src/service/profile_service.dart';
import 'package:ralu_norvegia/src/models/family_profile.dart';

import '../../utils/streak_utils.dart';

class TodayView extends StatefulWidget {
  final ValueNotifier<DateTime?>? selectedDateNotifier;
  final ValueNotifier<int> streakNotifier;
  const TodayView({super.key, this.selectedDateNotifier, required this.streakNotifier,});

  @override
  State<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<TodayView> with AutomaticKeepAliveClientMixin {
  final User? user = FirebaseAuth.instance.currentUser;

  bool _loading = true;
  bool _hasLoadedOnce = false;

  late String currentDay;
  late String currentWeek;

  String? surfaceForToday;
  final List<String> allLocations = [];
  final List<List<String>> _tasksPerLocation = [];
  List<List<bool>> _isCheckedPerLocation = [];

  bool _isActiveAdmin = true;
  String? _activeProfileId;
  List<FamilyProfile> _profiles = [];
  final List<_DisplayLocation> _displayLocations = [];

  bool _completionDialogShown = false;

  VoidCallback? _notifierListener;

  void _applyDate(DateTime date) {
    _completionDialogShown = false;
    currentDay = _getDayFor(date);
    currentWeek = _getWeekFor(date);
    _loadTasksForDate(date);
  }

  String translateDay(String day) {
    switch (day.toLowerCase()) {
      case 'luni':
        return 'Mandag';
      case 'marti':
        return 'Tirsdag';
      case 'miercuri':
        return 'Onsdag';
      case 'joi':
        return 'Torsdag';
      case 'vineri':
        return 'Fredag';
      case 'sambata':
        return 'Lørdag';
      case 'duminica':
        return 'Søndag';
      default:
        return day; // fallback dacă e deja tradus sau necunoscut
    }
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
        .doc(user!.uid)
        .collection('userProgress')
        .doc(weekKey);

    final weekSnap = await weekRef.get();
    if (weekSnap.exists) {
      if (weekSnap.data()?['initialized'] == true) {
        return;
      }
      final snaps = await Future.wait(dayNames.map((dn) => weekRef.collection('days').doc(dn).get()));
      if (snaps.any((snap) => snap.exists)) {
        await weekRef.set({'initialized': true}, SetOptions(merge: true));
        return;
      }
    }

    // Construim din weeklyTasks (Uke 1..4) mapând ISO week % 4
    final uke = _ukeFor(date);
    final legacySnaps = await Future.wait(dayNames.map((dn) => FirebaseFirestore.instance
        .collection('users').doc(user!.uid)
        .collection('weeklyTasks').doc(uke)
        .collection('days').doc(dn)
        .get()));

    final List<Future<void>> writeFutures = [];

    writeFutures.add(weekRef.set({
      'initialized': true,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)));

    for (int idx = 0; idx < dayNames.length; idx++) {
      final dn = dayNames[idx];
      final legacy = legacySnaps[idx];

      if (!legacy.exists) {
        writeFutures.add(weekRef.collection('days').doc(dn).set({
          'progress': 0.0,
        }));
        continue;
      }

      final data = legacy.data() as Map<String, dynamic>;
      final suprafata = data['suprafata'];
      final nrLoc = int.tryParse('${data['nrLoc'] ?? '0'}') ?? 0;
      final List<String> tasks = List<String>.from(data['tasks'] ?? const <String>[]);

      writeFutures.add(weekRef.collection('days').doc(dn).set({
        'progress': 0.0,
        if (suprafata != null) 'suprafata': suprafata,
      }, SetOptions(merge: true)));

      for (int i = 0; i < nrLoc; i++) {
        final key = (i == 0) ? 'locatie' : 'locatie$i';
        final name = (data[key]?.toString().trim().isNotEmpty ?? false)
            ? data[key].toString()
            : 'Locație ${i + 1}';
        writeFutures.add(weekRef
            .collection('days').doc(dn)
            .collection('locations').doc('loc_$i')
            .set({
          'index': i,
          'name': name,
          'tasks': tasks,
        }, SetOptions(merge: true)));
      }
    }

    await Future.wait(writeFutures);
  }

  Future<void> _loadTasksForDate(DateTime date) async {
    try {
      await _ensureWeekInitialized(date);
      final week = _getWeekFor(date);
      final day = _getDayFor(date);
      currentDay = day;
      currentWeek = week;

      // Load active profile details
      _activeProfileId = await ProfileService.getActiveProfileId();
      _isActiveAdmin = await ProfileService.isActiveProfileAdmin();
      if (user != null) {
        _profiles = await ProfileService.getProfiles(user!.uid);
      }

      final dayRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
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
          _displayLocations.clear();
        });
        return;
      }

      final dayData = daySnap.data() ?? {};
      surfaceForToday = dayData['suprafata']?.toString();

      final locsSnap = await dayRef
          .collection('locations')
          .orderBy('index')
          .get();

      allLocations.clear();
      _tasksPerLocation.clear();
      _isCheckedPerLocation = [];
      _displayLocations.clear();

      if (locsSnap.docs.isEmpty) {
        if (!mounted) return;
        setState(() {});
        return;
      }

      for (int li = 0; li < locsSnap.docs.length; li++) {
        final data = locsSnap.docs[li].data();
        final name = data['name']?.toString() ?? 'Locație ${li + 1}';
        final List<String> tasks = List<String>.from(data['tasks'] ?? const <String>[]);
        
        allLocations.add(name);
        _tasksPerLocation.add(tasks);

        final Map<String, dynamic> doneMap = Map<String, dynamic>.from(data['done'] ?? {});
        final List<bool> row = List<bool>.generate(
          tasks.length,
          (ti) => (doneMap['$ti'] is bool) ? doneMap['$ti'] as bool : false,
        );
        _isCheckedPerLocation.add(row);

        // Populate display list
        final delegations = Map<String, dynamic>.from(data['delegations'] ?? {});
        final List<_DisplayTask> displayTasks = [];

        for (int ti = 0; ti < tasks.length; ti++) {
          final delegatedProfileId = delegations['$ti']?.toString();
          if (_isActiveAdmin || delegatedProfileId == _activeProfileId) {
            displayTasks.add(_DisplayTask(
              originalIndex: ti,
              name: tasks[ti],
              isChecked: row[ti],
              delegatedTo: delegatedProfileId,
            ));
          }
        }

        if (displayTasks.isNotEmpty) {
          _displayLocations.add(_DisplayLocation(
            originalIndex: li,
            name: name,
            tasks: displayTasks,
          ));
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading tasks for today: $e');
    }
  }

  DocumentReference<Map<String, dynamic>> _locationDocRef(int locIdx) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('userProgress')
        .doc(currentWeek)
        .collection('days')
        .doc(currentDay)
        .collection('locations')
        .doc('loc_$locIdx');
  }

  Future<void> _saveCheckboxState(int locIdx, int taskIdx, bool value) async {
    try {
      if (!value) {
        _completionDialogShown = false;
      }

      final wasAllDone = _completionDialogShown;
      if (wasAllDone && !value) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Avbryt fullføring?"),
            content: const Text("Dette vil påvirke streak-en din. Er du sikker?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Avbryt")),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Ja")),
            ],
          ),
        ) ?? false;

        if (!confirm) {
          // dacă refuză, menține bifa
          setState(() {
            _isCheckedPerLocation[locIdx][taskIdx] = true;
            for (final dl in _displayLocations) {
              if (dl.originalIndex == locIdx) {
                for (final dt in dl.tasks) {
                  if (dt.originalIndex == taskIdx) {
                    dt.isChecked = true;
                  }
                }
              }
            }
          });
          return;
        }
      }

      await _locationDocRef(locIdx).update({
        'done.$taskIdx': value,
      });

      final allTasksDoneForLocation = _isCheckedPerLocation[locIdx].isNotEmpty &&
          _isCheckedPerLocation[locIdx].every((b) => b);
      await _locationDocRef(locIdx).set(
        {'completed': allTasksDoneForLocation},
        SetOptions(merge: true),
      );

      await _updateDayProgress();

      // după orice schimbare recalculează streak-ul
      final streak = await calculateStreak(user!.uid);
      widget.streakNotifier.value = streak;

      // dacă toate sunt bifate → dialog de confirmare
      final isAllDoneForActive = _isActiveAdmin
          ? (_isCheckedPerLocation.isNotEmpty &&
              _isCheckedPerLocation.every((locRow) => locRow.isNotEmpty && locRow.every((b) => b)))
          : (_displayLocations.isNotEmpty &&
              _displayLocations.every((loc) => loc.tasks.every((t) => t.isChecked)));

      if (isAllDoneForActive && !_completionDialogShown) {
        _completionDialogShown = true;

        final allHouseholdTasksDone = _isCheckedPerLocation.isNotEmpty &&
            _isCheckedPerLocation.every((locRow) => locRow.isNotEmpty && locRow.every((b) => b));
        if (allHouseholdTasksDone) {
          await _incrementStreak();
        }

        final newStreak = await calculateStreak(user!.uid);
        widget.streakNotifier.value = newStreak;

        if (mounted) {
          _showCompletionDialog(context);
        }
      }
    } catch (e) {
      debugPrint('Error saving checkbox state: $e');
    }
  }

  Future<void> _updateDayProgress() async {
    try {
      if (user == null) return;
      final dayRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('userProgress')
          .doc(currentWeek)
          .collection('days')
          .doc(currentDay);

      final locsSnap = await dayRef.collection('locations').get();
      int done = 0, total = 0;
      for (final d in locsSnap.docs) {
        final data = d.data();
        final tasks = List<String>.from(data['tasks'] ?? const <String>[]);
        final doneMap = Map<String, dynamic>.from(data['done'] ?? {});
        total += tasks.length;
        for (int i = 0; i < tasks.length; i++) {
          if ((doneMap['$i'] ?? false) == true) done++;
        }
      }
      final progress = total == 0 ? 0.0 : (done / total);
      await dayRef.set({
        'progress': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating day progress: $e");
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

    final userRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primaryBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header modern pastel-mint style
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.accent3, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            "Denne uken",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _ukeFor(DateTime.now()),
                        style: TextStyle(
                          color: AppColors.primaryText2,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Dag: ${translateDay(currentDay)}",
                        style: TextStyle(
                          color: AppColors.primaryText2,
                          fontSize: 15,
                        ),
                      ),
                      if (_displayLocations.length == 1) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Rom: ${_displayLocations.first.name}",
                          style: TextStyle(
                            color: AppColors.primaryText2,
                            fontSize: 15,
                          ),
                        ),
                      ],
                      if (surfaceForToday != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Fokus: $surfaceForToday",
                          style: TextStyle(
                            color: AppColors.primaryText2,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Tasks
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent3,
                          ),
                        )
                      : _displayLocations.isEmpty
                          ? Center(
                              child: Text(
                                _isActiveAdmin
                                    ? "Ingen oppgaver for i dag."
                                    : "Ingen oppgaver tildelt deg for i dag.",
                                style: TextStyle(
                                  color: AppColors.primaryText2,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              itemCount: _displayLocations.length,
                              itemBuilder: (context, locIdx) {
                                final displayLoc = _displayLocations[locIdx];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 18),
                                  color: Colors.white,
                                  elevation: 3,
                                  shadowColor: Colors.black12,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ExpansionTile(
                                    leading: Icon(
                                      Icons.home_work_outlined,
                                      color: AppColors.accent3,
                                      size: 26,
                                    ),
                                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    title: Text(
                                      displayLoc.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accentDark,
                                        fontSize: 17,
                                      ),
                                    ),
                                    shape: const Border(),
                                    collapsedShape: const Border(),
                                    childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    children: [
                                      for (int ti = 0; ti < displayLoc.tasks.length; ti++)
                                        Builder(
                                          builder: (context) {
                                            final displayTask = displayLoc.tasks[ti];
                                            final isDone = displayTask.isChecked;
                                            final delegatedProfile = displayTask.delegatedTo == null
                                                ? null
                                                : _profiles.cast<FamilyProfile?>().firstWhere(
                                                      (p) => p?.id == displayTask.delegatedTo,
                                                      orElse: () => null,
                                                    );

                                            return Container(
                                              margin: const EdgeInsets.symmetric(vertical: 6),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryBackground.withValues(alpha: 0.5),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isDone
                                                      ? Colors.green.withValues(alpha: 0.3)
                                                      : AppColors.accent3.withValues(alpha: 0.2),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          displayTask.name,
                                                          style: const TextStyle(
                                                            color: AppColors.primaryText,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: isDone
                                                              ? Colors.green.withValues(alpha: 0.15)
                                                              : Colors.orange.withValues(alpha: 0.15),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          isDone ? 'Fullført' : 'Gjenstår',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: isDone ? Colors.green.shade800 : Colors.orange.shade800,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Checkbox(
                                                        value: displayTask.isChecked,
                                                        activeColor: AppColors.accent3,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(5),
                                                        ),
                                                        onChanged: (bool? v) {
                                                          setState(() {
                                                            displayTask.isChecked = v ?? false;
                                                            _isCheckedPerLocation[displayLoc.originalIndex][displayTask.originalIndex] = v ?? false;
                                                          });
                                                          _saveCheckboxState(
                                                            displayLoc.originalIndex,
                                                            displayTask.originalIndex,
                                                            displayTask.isChecked,
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  if (delegatedProfile != null) ...[
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: delegatedProfile.color.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(
                                                          color: delegatedProfile.color.withValues(alpha: 0.3),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            delegatedProfile.emoji,
                                                            style: const TextStyle(fontSize: 12),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            delegatedProfile.name,
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                              color: delegatedProfile.color,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            );
                                          }
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // (rămâne neschimbat; doar mesajul menționează o singură locație dacă există exact una)
  void _showCompletionDialog(BuildContext context) {
    final singleLoc = (_displayLocations.length == 1) ? _displayLocations.first.name : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.accent3,
                  size: 56,
                ),
                const SizedBox(height: 16),

                const Text(
                  "Bra jobba!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  singleLoc == null
                      ? (_isActiveAdmin
                          ? "Du har fullført alle oppgavene for ${translateDay(currentDay)}."
                          : "Du har fullført alle dine oppgaver for ${translateDay(currentDay)}.")
                      : (_isActiveAdmin
                          ? "Du har fullført alle oppgavene i $singleLoc for ${translateDay(currentDay)}."
                          : "Du har fullført alle dine oppgaver i $singleLoc for ${translateDay(currentDay)}."),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.primaryText2,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final streak = await calculateStreak(user!.uid);
                      widget.streakNotifier.value = streak;

                      Navigator.of(context).pop(); // 🔥 UN SINGUR POP

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isActiveAdmin
                                ? "Bra jobba! Du har fullført dagens rengjøring 🎉"
                                : "Bra jobba! Du har fullført dine oppgaver for i dag 🎉",
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Ferdig",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DisplayTask {
  final int originalIndex;
  final String name;
  bool isChecked;
  final String? delegatedTo;

  _DisplayTask({
    required this.originalIndex,
    required this.name,
    required this.isChecked,
    this.delegatedTo,
  });
}

class _DisplayLocation {
  final int originalIndex;
  final String name;
  final List<_DisplayTask> tasks;

  _DisplayLocation({
    required this.originalIndex,
    required this.name,
    required this.tasks,
  });
}
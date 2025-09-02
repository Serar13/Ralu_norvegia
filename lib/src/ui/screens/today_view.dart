import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';

class TodayView extends StatefulWidget {
  final ValueNotifier<DateTime?>? selectedDateNotifier;
  const TodayView({super.key, this.selectedDateNotifier});

  @override
  State<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<TodayView> {
  final user = FirebaseAuth.instance.currentUser!;

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
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentDay = _getDayFor(now);
    currentWeek = _getWeekFor(now);
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

  String _getWeekFor(DateTime d) {
    final weekOfYear = ((d.difference(DateTime(d.year, 1, 1)).inDays + 1) / 7).ceil();
    return 'Uke ${(weekOfYear - 1) % 4 + 1}';
  }

  Future<void> _loadTasksForDate(DateTime date) async {
    try {
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

  @override
  Widget build(BuildContext context) {
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
              child: (_tasksPerLocation.isEmpty || (_tasksPerLocation.isNotEmpty && _tasksPerLocation.every((l) => l.isEmpty)))
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
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';

class TodayView extends StatefulWidget {
  const TodayView({super.key});

  @override
  State<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<TodayView> {
  final user = FirebaseAuth.instance.currentUser!;

  late String currentDay;
  late String currentWeek;

  String? surfaceForToday;
  final List<String> allLocations = [];
  final List<String> tasksForToday = [];
  List<List<bool>> _isCheckedPerLocation = [];

  // doc pentru persistarea bifelor (per user, per zi)
  DocumentReference<Map<String, dynamic>> get _completedDocRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('completedTasks')
          .doc('${currentWeek}-${currentDay}');

  @override
  void initState() {
    super.initState();
    currentDay = _getCurrentDay();
    currentWeek = _getCurrentWeek();
    _loadTasksForToday();
  }

  String _getCurrentDay() {
    final now = DateTime.now();
    const days = ['Luni', 'Marti', 'Miercuri', 'Joi', 'Vineri', 'Sambata', 'Duminica'];
    return days[now.weekday - 1];
  }

  String _getCurrentWeek() {
    final now = DateTime.now();
    final weekOfYear = ((now.difference(DateTime(now.year, 1, 1)).inDays + 1) / 7).ceil();
    return 'Uke ${(weekOfYear - 1) % 4 + 1}';
  }

  Future<void> _loadTasksForToday() async {
    try {
      final daySnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('weeklyTasks')
          .doc(currentWeek)
          .collection('days')
          .doc(currentDay)
          .get();

      if (!daySnap.exists) {
        setState(() {
          surfaceForToday = null;
          allLocations.clear();
          tasksForToday.clear();
          _isCheckedPerLocation = [];
        });
        return;
      }

      final data = daySnap.data() as Map<String, dynamic>? ?? {};
      surfaceForToday = data['suprafata']?.toString();

      // nrLoc e string în date; îl tolerăm oricum ar veni
      final int locCount = () {
        final raw = data['nrLoc'];
        final n = int.tryParse(raw?.toString() ?? '');
        return (n == null || n <= 0) ? 1 : n;
      }();

      // colectăm locațiile: locatie, locatie1, locatie2, …
      allLocations
        ..clear();
      for (int i = 0; i < locCount; i++) {
        final key = (i == 0) ? 'locatie' : 'locatie$i';
        final val = data[key]?.toString().trim();
        allLocations.add((val != null && val.isNotEmpty) ? val : 'Locație ${i + 1}');
      }

      // tasks: listă de string
      tasksForToday
        ..clear()
        ..addAll(List<String>.from(data['tasks'] ?? const <String>[]));

      // fallback dacă nu sunt taskuri
      if (tasksForToday.isEmpty) {
        _isCheckedPerLocation = List.generate(locCount, (_) => <bool>[]);
        setState(() {});
        return;
      }

      // inițializare locală cu false (UI-ready)
      _isCheckedPerLocation = List.generate(
        locCount,
            (_) => List<bool>.filled(tasksForToday.length, false),
      );

      // hidratează din completedTasks/{week-day}
      final compSnap = await _completedDocRef.get();
      final Map<String, dynamic> saved = compSnap.data() ?? const {};

      for (int li = 0; li < locCount; li++) {
        for (int ti = 0; ti < tasksForToday.length; ti++) {
          final key = 'loc${li}_task${ti}';
          final v = saved[key];
          if (v is bool) {
            _isCheckedPerLocation[li][ti] = v;
          }
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading tasks for today: $e');
    }
  }

  Future<void> _saveCheckboxState(int locIdx, int taskIdx, bool value) async {
    try {
      // salvăm incremental pe cheie specifică
      final key = 'loc${locIdx}_task${taskIdx}';
      await _completedDocRef.set({key: value}, SetOptions(merge: true));

      // dacă toate task-urile tuturor locațiilor sunt bifate → dialog confirmare
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
              child: tasksForToday.isEmpty
                  ? const Center(
                child: Text("No tasks for today.",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              )
                  : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (allLocations.length > 1)
                    ...List.generate(allLocations.length, (locIdx) {
                      return ExpansionTile(
                        title: Text(allLocations[locIdx],
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        children: [
                          for (int ti = 0; ti < tasksForToday.length; ti++)
                            Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                title: Text(tasksForToday[ti]),
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
                    ...List.generate(tasksForToday.length, (ti) {
                      final checked = (_isCheckedPerLocation.isNotEmpty &&
                          _isCheckedPerLocation[0][ti]);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            tasksForToday[ti],
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
                                  _isCheckedPerLocation = [
                                    List<bool>.filled(tasksForToday.length, false),
                                  ];
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
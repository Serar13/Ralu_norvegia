import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/ui/screens/dailyItemDetails.dart';
import 'package:shared_preferences/shared_preferences.dart';

class dailyView extends StatefulWidget {
  final ValueNotifier<int> pointsNotifier;

  const dailyView({required this.pointsNotifier, super.key});

  @override
  State<dailyView> createState() => _dailyViewState();
}

class _dailyViewState extends State<dailyView> with AutomaticKeepAliveClientMixin {
  Future<Map<String, bool>>? _tasksFuture;
  final List<Map<String, dynamic>> dailyItems = [];
  final user = FirebaseAuth.instance.currentUser!;
  bool _allTasksCompleted = false;

  // Fetch tasks from Firestore's "daily" collection
  Future<void> getDocId() async {
    await FirebaseFirestore.instance.collection('daily').get().then(
          (snapshot) {
        snapshot.docs.forEach((element) {
          dailyItems.add({
            'title': element.reference.id,
            'description': element.data().values.join('\n'),
          });
        });
        setState(() {});
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _checkAndResetForNewDay(); // Verificăm și resetăm dacă este o zi nouă
    getDocId();
    _tasksFuture = _fetchUserTasks();
  }

  @override
  bool get wantKeepAlive => true;

// Checks and resets tasks if it's a new day
  Future<void> _checkAndResetForNewDay() async {
    final prefs = await SharedPreferences.getInstance();

    // Get the last reset date stored
    String? lastResetDate = prefs.getString('lastResetDate');

    DateTime today = DateTime.now();

    // Check if today is a new day
    if (lastResetDate == null || DateTime.parse(lastResetDate).day != today.day) {
      // Reset tasks for a new day
      await _resetUserTasks();

      // Save today's date as the last reset date
      prefs.setString('lastResetDate', today.toIso8601String());

      print("Tasks reset for a new day!");
    }

    // Schedule the next reset for midnight
    _scheduleResetForMidnight();
  }

  void _scheduleResetForMidnight() {
    final now = DateTime.now();

    // Get the next midnight (local time)
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    // Calculate the duration until midnight
    final timeUntilMidnight = tomorrow.difference(now);
    // final timeUntilMidnight = Duration(seconds: 5); // Simulate midnight in 5 seconds

    // Log the scheduled reset time
    print("Current time: $now");
    print("Next midnight: $tomorrow");
    print("Scheduled reset at midnight in ${timeUntilMidnight.inHours} hours and ${timeUntilMidnight.inMinutes.remainder(60)} minutes.");

    // Set a timer to call _resetUserTasks at midnight
    Future.delayed(timeUntilMidnight, () async {
      print("Midnight reached! Resetting tasks...");
      await _resetUserTasks();
    });
  }

  // Verifică dacă toate task-urile sunt completate
  Future<void> _checkIfAllTasksCompleted() async {
    final user = FirebaseAuth.instance.currentUser!;
    final completedTasksRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('completedTasks');

    bool allCompleted = true;
    for (String room in tasks.keys) {
      final roomDoc = await completedTasksRef.doc(room).get();
      if (!roomDoc.exists || !roomDoc.data()!.containsValue(true)) {
        allCompleted = false;
        break;
      }
    }
    if (allCompleted) {
      await _addPoints(10);
    }
    setState(() {
      _allTasksCompleted = allCompleted;
    });
  }

  // Method to add points to the user
  Future<void> _addPoints(int pointsToAdd) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Atomically increment the points
      await userRef.update({
        'points': FieldValue.increment(pointsToAdd),
      });

      // Notify the parent widget (homeView) about the updated points
      widget.pointsNotifier.value += pointsToAdd;
    } catch (e) {
      print("Error adding points: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Container(
            constraints: BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Dagens oppgaver',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent3,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _allTasksCompleted
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Color(0xFFDFF6E4),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.15),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.celebration,
                                    color: Colors.green.shade700,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Congrats! You've completed all the tasks for today!",
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : FutureBuilder(
                            future: _tasksFuture, // Fetch tasks for the current user
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }

                              return ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: dailyItems.length,
                                separatorBuilder: (context, index) => SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final item = dailyItems[index];
                                  final bool isCompleted = snapshot.data![item['title']] ?? false;

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      leading: isCompleted
                                          ? Icon(Icons.check_circle, color: Colors.green)
                                          : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400),
                                      title: Text(
                                        item['title'],
                                        style: TextStyle(
                                          color: isCompleted ? Colors.grey : Colors.black87,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                        ),
                                      ),
                                      onTap: () {
                                        _onItemPressed(context, item);
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Resetăm task-urile pentru utilizator
  Future<void> _resetUserTasks() async {
    final user = FirebaseAuth.instance.currentUser!;
    final completedTasksRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('completedTasks');

    for (String room in tasks.keys) {
      final roomRef = completedTasksRef.doc(room);

      // Setăm toate task-urile pe false
      await roomRef.set({
        for (String task in tasks[room]!) task: false,
      });
    }

    setState(() {
      _allTasksCompleted = false;
    });
  }

  // Resetăm task-urile manual (pentru testare)
  Future<void> _resetUserTasksButton() async {
    await _resetUserTasks();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tasks reset!')));
  }

  // Fetch user tasks
  Future<Map<String, bool>> _fetchUserTasks() async {
    final user = FirebaseAuth.instance.currentUser!;
    final completedTasksRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('completedTasks');

    Map<String, bool> userTaskCompletionStatus = {};

    for (String room in tasks.keys) {
      final roomDoc = await completedTasksRef.doc(room).get();

      if (roomDoc.exists) {
        userTaskCompletionStatus[room] = roomDoc.data()!.containsValue(true);
      } else {
        userTaskCompletionStatus[room] = false;
      }
    }

    return userTaskCompletionStatus;
  }

  // Handle item press
  void _onItemPressed(BuildContext context, Map<String, dynamic> item) async {
    bool isCompleted = await _checkIfTaskCompleted(item['title']);
    if (isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have already completed these tasks!')),
      );
    } else {
      final descriptions = item['description'].split('\n');
      final taskCompleted = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DailyItemDetailsView(
            title: item['title'],
            descriptions: descriptions,
          ),
        ),
      );

      if (taskCompleted == true) {
        _completeTask(item['title']);
      }
    }
  }

  Future<bool> _checkIfTaskCompleted(String taskTitle) async {
    final user = FirebaseAuth.instance.currentUser!;
    final taskRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('completedTasks').doc(taskTitle);

    final snapshot = await taskRef.get();
    return snapshot.exists && snapshot.data()?['completed'] == true;
  }

  Future<void> _completeTask(String taskTitle) async {
    final user = FirebaseAuth.instance.currentUser!;
    final completedTasksRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('completedTasks');

    await completedTasksRef.doc(taskTitle).set({
      'completed': true,
    });

    _checkIfAllTasksCompleted();
  }
}

Map<String, List<String>> tasks = {
  'Baderom': [
    'bruk vindusnal på dusjdørene etter dusjing',
    'fei/støvsug/mopp gulvet',
    'sett ting tilbake på plass',
    'ta ut ting som ikke hører hjemme på badet',
    'tørk fort over speil, vask og toalett',
    'åpne vinduene i minst 10 minutter',
  ],
  'Kjøkken': [
    'bruk en glassklut på kokeplata',
    'fei/støvsug/mop gulvet',
    'rydd benkeplater',
    'spray overflater med hverdagsflasken',
    'ta ut søppel',
    'tøm oppvasken',
    'tørk overflater tørre etter vask',
    'åpne vinduene i minst 10 minutter',
  ],
  'Soverom': [
    're opp sengen',
    'ta ut skitne klær/håndklær',
    'ta ut ting som ikke hører hjemme på soverommet',
    'åpne vinduene i minst 10 minutter',
  ],
  'Stue og barnerom': [
    'rydd ting på plass',
    'tørk søl umiddelbart',
    'åpne vinduene i minst 10 minutter',
  ],
  'Inngang': [
    'bruk en håndhelt batteridrevet støvsuger på gulvet',
    'heng jakker/klær tilbake på plass',
    'sett sko tilbake på plass',
    'åpne vinduene i minst 10 minutter',
  ],
};

Future<void> resetUserTasks() async {
  try {
    final user = FirebaseAuth.instance.currentUser!;
    final completedTasksRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('completedTasks');

    // Iterate over each room and tasks
    for (String room in tasks.keys) {
      final roomRef = completedTasksRef.doc(room);

      // Check if the room document exists
      final roomSnapshot = await roomRef.get();
      if (roomSnapshot.exists) {
        // Reset all tasks for the room to false
        final Map<String, dynamic> updatedTasks = {};
        for (String task in tasks[room]!) {
          updatedTasks[task] = false;
        }

        // Update the document with the reset tasks
        await roomRef.update(updatedTasks);
      } else {
        // If the room document doesn't exist, create it with all tasks set to false
        final Map<String, dynamic> newTasks = {};
        for (String task in tasks[room]!) {
          newTasks[task] = false;
        }

        // Create the document
        await roomRef.set(newTasks);
      }
    }

    print("Tasks reset successfully for user ${user.email}!");
  } catch (e) {
    print("Error resetting tasks: $e");
  }
}
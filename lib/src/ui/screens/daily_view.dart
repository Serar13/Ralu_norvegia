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

class _dailyViewState extends State<dailyView> {
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
  }

  /// Verificăm și resetăm task-urile dacă este o zi nouă
  Future<void> _checkAndResetForNewDay() async {
    final prefs = await SharedPreferences.getInstance();

    // Obținem ultima dată când task-urile au fost verificate/resetate
    String? lastResetDate = prefs.getString('lastResetDate');

    DateTime today = DateTime.now();
    if (lastResetDate == null || DateTime.parse(lastResetDate).day != today.day) {
      // Resetăm task-urile dacă este o zi nouă
      await _resetUserTasks();
      // Salvăm noua dată de resetare
      prefs.setString('lastResetDate', today.toIso8601String());
    }

    // Verificăm dacă toate task-urile au fost finalizate ieri și setăm starea
    _checkIfAllTasksCompleted();
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

    setState(() {
      _allTasksCompleted = allCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: _allTasksCompleted
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Congrats! You've completed all the tasks for today!",
              style: TextStyle(fontSize: 24, color: AppColors.accent3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetUserTasksButton, // Reset tasks button (pentru testare)
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent3,
                minimumSize: Size(200, 50),
              ),
              child: const Text("Reset Tasks"),
            ),
          ],
        ),
      )
          : FutureBuilder(
        future: _fetchUserTasks(), // Fetch tasks for the current user
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: dailyItems.length,
                  itemBuilder: (context, index) {
                    final item = dailyItems[index];
                    final bool isCompleted = snapshot.data![item['title']] ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(
                          item['title'],
                          style: TextStyle(
                            color: isCompleted ? Colors.grey : Colors.black,
                          ),
                        ),
                        onTap: () {
                          _onItemPressed(context, item);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
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
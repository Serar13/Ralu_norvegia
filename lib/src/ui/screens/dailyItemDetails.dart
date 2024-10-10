import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:flutter/material.dart';

class DailyItemDetailsView extends StatefulWidget {
  final String title;
  final List<String> descriptions;

  const DailyItemDetailsView({
    required this.title,
    required this.descriptions,
    Key? key,
  }) : super(key: key);

  @override
  _DailyItemDetailsViewState createState() => _DailyItemDetailsViewState();
}

class _DailyItemDetailsViewState extends State<DailyItemDetailsView> {
  final user = FirebaseAuth.instance.currentUser!;
  List<bool> _isChecked = [];
  bool _allChecked = false;

  @override
  void initState() {
    super.initState();
    _loadCheckboxState();  // Load the checkbox state when the screen opens
  }

  // Function to load the checkbox states from Firestore
  Future<void> _loadCheckboxState() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('completedTasks')
          .doc(widget.title)
          .get();

      List<bool> savedStates = List.generate(widget.descriptions.length, (index) {
        // Cast userSnapshot.data() to Map<String, dynamic>
        Map<String, dynamic>? data = userSnapshot.data() as Map<String, dynamic>?;
        return data?['checkbox_$index'] ?? false;
      });

      setState(() {
        _isChecked = savedStates;
        _checkAllChecked();  // Check if all checkboxes are checked
      });
    } catch (e) {
      print("Error loading checkbox state: $e");
    }
  }

  // Function to save the checkbox state to Firestore
  Future<void> _saveCheckboxState(int index, bool value) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('completedTasks')
        .doc(widget.title)
        .set({'checkbox_$index': value}, SetOptions(merge: true));
  }

  // This function will update whether all checkboxes are checked
  void _checkAllChecked() {
    setState(() {
      _allChecked = _isChecked.every((checked) => checked);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Handle empty descriptions case
    if (widget.descriptions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('No tasks available'),
          centerTitle: true,
        ),
        body: Center(
          child: Text('No tasks available for this room.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,
          style: TextStyle(
            color: AppColors.accent3,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.secondary,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context, false); // Return false if back is pressed
          },
          icon: Icon(Icons.arrow_back, color: AppColors.accent3),
        ),
      ),
      body: Container(
        color: AppColors.primary,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.descriptions.length,
                itemBuilder: (context, index) {
                  // Ensure the list is in bounds
                  if (index >= _isChecked.length) return SizedBox.shrink();

                  return CheckboxListTile(
                    title: Text(widget.descriptions[index]),
                    value: _isChecked[index],
                    onChanged: (bool? value) {
                      setState(() {
                        _isChecked[index] = value ?? false;
                      });
                      _saveCheckboxState(index,
                          _isChecked[index]); // Save state when checkbox changes
                      _checkAllChecked(); // Check if all checkboxes are now checked
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _allChecked
                    ? () {
                  _completeTask(widget.title); // Mark the task as complete
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('All tasks completed!')),
                  );
                }
                    : null,
                // Button is disabled if not all checkboxes are checked
                child: Text("Complete Tasks"),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Function to mark the entire task as completed
  void _completeTask(String taskTitle) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('completedTasks')
        .doc(taskTitle)
        .set({'completed': true}, SetOptions(merge: true));

    Navigator.of(context).pop(true);  // Return true to indicate task completion
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:ralu_norvegia/src/models/family_profile.dart';
import 'package:ralu_norvegia/src/service/profile_service.dart';

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
  
  String? _activeProfileId;
  List<FamilyProfile> _profiles = [];
  Map<int, String> _completedByMap = {};

  @override
  void initState() {
    super.initState();
    _loadCheckboxState();  // Load the checkbox state when the screen opens
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final pId = await ProfileService.getActiveProfileId();
      final list = await ProfileService.getProfiles(user.uid);
      setState(() {
        _activeProfileId = pId;
        _profiles = list;
      });
    } catch (e) {
      print("Error loading profiles: $e");
    }
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
        Map<String, dynamic>? data = userSnapshot.data() as Map<String, dynamic>?;
        return data?['checkbox_$index'] ?? false;
      });

      final Map<int, String> completedBy = {};
      Map<String, dynamic>? data = userSnapshot.data() as Map<String, dynamic>?;
      if (data != null) {
        for (int i = 0; i < widget.descriptions.length; i++) {
          final profileId = data['completedBy_checkbox_$i'] as String?;
          if (profileId != null) {
            completedBy[i] = profileId;
          }
        }
      }

      setState(() {
        _isChecked = savedStates;
        _completedByMap = completedBy;
        _checkAllChecked();  // Check if all checkboxes are checked
      });
    } catch (e) {
      print("Error loading checkbox state: $e");
    }
  }

  // Function to save the checkbox state to Firestore
  Future<void> _saveCheckboxState(int index, bool value) async {
    setState(() {
      if (value) {
        if (_activeProfileId != null) {
          _completedByMap[index] = _activeProfileId!;
        }
      } else {
        _completedByMap.remove(index);
      }
    });

    final dataToSet = {
      'checkbox_$index': value,
      'completedBy_checkbox_$index': value ? _activeProfileId : FieldValue.delete(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('completedTasks')
        .doc(widget.title)
        .set(dataToSet, SetOptions(merge: true));
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
        backgroundColor: AppColors.primaryBackground,
        body: Center(
          child: Text('No tasks available for this room.',
            style: TextStyle(
              color: AppColors.accent3,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Dagens oppgaver',
                style: TextStyle(
                  color: AppColors.accent3,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Column(
          children: [
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListView.builder(
                    itemCount: widget.descriptions.length,
                    itemBuilder: (context, index) {
                      if (index >= _isChecked.length) return SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
                        child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isChecked[index] = !_isChecked[index];
                              });
                              _saveCheckboxState(index, _isChecked[index]);
                              _checkAllChecked();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isChecked[index]) ...[
                                    _buildCompleterBadge(index),
                                    const SizedBox(width: 8),
                                  ],
                                  Icon(
                                    _isChecked[index] ? Icons.task_alt : Icons.circle_outlined,
                                    color: _isChecked[index] ? AppColors.accent3 : Colors.grey,
                                  ),
                                ],
                              ),
                              title: Text(
                                widget.descriptions[index],
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _allChecked
                    ? () {
                        _completeTask(widget.title);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Bra jobbet! Alle dagens oppgaver er fullført',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.accent3, // verdele tău
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent3,
                  disabledBackgroundColor: AppColors.accent3.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  "Complete Tasks",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
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
        .set({
          'completed': true,
          'completedBy': _activeProfileId,
        }, SetOptions(merge: true));

    Navigator.of(context).pop(true);  // Return true to indicate task completion
  }

  Widget _buildCompleterBadge(int index) {
    final profileId = _completedByMap[index];
    if (profileId == null) return const SizedBox.shrink();

    final profile = _profiles.cast<FamilyProfile?>().firstWhere(
          (p) => p?.id == profileId,
          orElse: () => null,
        );
    if (profile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: profile.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: profile.color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        profile.emoji,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
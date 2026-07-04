import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/ui/screens/dailyItemDetails.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ralu_norvegia/src/models/family_profile.dart';
import 'package:ralu_norvegia/src/service/profile_service.dart';

import '../../app/app_router.dart';

class dailyView extends StatefulWidget {
  final ValueNotifier<int> pointsNotifier;

  const dailyView({required this.pointsNotifier, super.key});

  @override
  State<dailyView> createState() => _dailyViewState();
}

class _dailyViewState extends State<dailyView> with AutomaticKeepAliveClientMixin {
  final List<Map<String, dynamic>> dailyItems = [];
  final User? user = FirebaseAuth.instance.currentUser;
  bool _allTasksCompleted = false;

  List<FamilyProfile> _profiles = [];
  String? _activeProfileId;

  // Fetch tasks from Firestore's "daily" collection
  Future<void> getDocId() async {
    await FirebaseFirestore.instance.collection('daily').get().then(
      (snapshot) {
        dailyItems.clear();
        for (var element in snapshot.docs) {
          dailyItems.add({
            'title': element.reference.id,
            'description': element.data().values.join('\n'),
          });
        }
        setState(() {});
      },
    );
  }

  Future<void> _loadProfiles() async {
    if (user == null) return;
    try {
      final pId = await ProfileService.getActiveProfileId();
      final list = await ProfileService.getProfiles(user!.uid);
      setState(() {
        _activeProfileId = pId;
        _profiles = list;
      });
      await _checkIfCurrentlyAllCompleted();
    } catch (e) {
      debugPrint("Error loading profiles in daily view: $e");
    }
  }

  Future<void> _checkIfCurrentlyAllCompleted() async {
    if (user == null) return;
    try {
      final completedTasksRef = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('completedTasks');
      bool allCompleted = true;
      for (String r in tasks.keys) {
        final roomDoc = await completedTasksRef.doc(r).get();
        if (!roomDoc.exists || roomDoc.data()?['completed'] != true) {
          allCompleted = false;
          break;
        }
      }
      if (mounted) {
        setState(() {
          _allTasksCompleted = allCompleted;
        });
      }
    } catch (e) {
      debugPrint("Error checking if all completed: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    if (user == null) return;
    _checkAndResetForNewDay();
    getDocId();
    _loadProfiles();
  }

  @override
  bool get wantKeepAlive => true;

  // Checks and resets tasks if it's a new day
  Future<void> _checkAndResetForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastResetDate = prefs.getString('lastResetDate');
    DateTime today = DateTime.now();

    if (lastResetDate == null || DateTime.parse(lastResetDate).day != today.day) {
      await _resetUserTasks();
      prefs.setString('lastResetDate', today.toIso8601String());
      print("Tasks reset for a new day!");
    }
    _scheduleResetForMidnight();
  }

  void _scheduleResetForMidnight() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    Future.delayed(timeUntilMidnight, () async {
      print("Midnight reached! Resetting tasks...");
      await _resetUserTasks();
    });
  }

  // Method to add points to the user
  Future<void> _addPoints(int pointsToAdd) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
      await userRef.update({
        'points': FieldValue.increment(pointsToAdd),
      });
      widget.pointsNotifier.value += pointsToAdd;
    } catch (e) {
      print("Error adding points: $e");
    }
  }

  Future<void> _saveDailyCheckboxState(String room, int index, bool value) async {
    if (user == null) return;

    final Map<String, dynamic> dataToSet = {
      'checkbox_$index': value,
      'completedBy_checkbox_$index': value ? _activeProfileId : FieldValue.delete(),
    };

    if (!value) {
      dataToSet['completed'] = false;
      dataToSet['completedBy'] = FieldValue.delete();
      if (_allTasksCompleted) {
        setState(() {
          _allTasksCompleted = false;
        });
      }
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('completedTasks')
        .doc(room)
        .set(dataToSet, SetOptions(merge: true));
  }

  Future<void> _completeDailyRoom(String room) async {
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('completedTasks')
        .doc(room)
        .set({
      'completed': true,
      if (_activeProfileId != null) 'completedBy': _activeProfileId,
    }, SetOptions(merge: true));

    // Check if all rooms are completed
    final completedTasksRef = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('completedTasks');
    bool allCompleted = true;
    for (String r in tasks.keys) {
      if (r == room) continue;
      final roomDoc = await completedTasksRef.doc(r).get();
      if (!roomDoc.exists || roomDoc.data()?['completed'] != true) {
        allCompleted = false;
        break;
      }
    }

    if (allCompleted) {
      await _addPoints(10);
      if (mounted) {
        setState(() {
          _allTasksCompleted = true;
        });
      }
    }
  }

  Future<void> _resetUserTasks() async {
    if (user == null) return;
    final completedTasksRef = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('completedTasks');

    for (String room in tasks.keys) {
      final roomRef = completedTasksRef.doc(room);
      final Map<String, dynamic> resetData = {
        'completed': false,
        'completedBy': FieldValue.delete(),
      };
      
      final List<String> roomTasks = tasks[room] ?? [];
      for (int i = 0; i < roomTasks.length; i++) {
        resetData['checkbox_$i'] = false;
        resetData['completedBy_checkbox_$i'] = FieldValue.delete();
      }

      await roomRef.set(resetData, SetOptions(merge: true));
    }

    setState(() {
      _allTasksCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 56,
                    color: AppColors.accent3,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Denne funksjonen er låst',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'For å bruke daglige oppgaver og lagre fremgangen din, må du opprette en konto eller logge inn.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent3,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => GoRouter.of(context).push(loginPath),
                      child: const Text(
                        'Gå til innlogging',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
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
                                color: const Color(0xFFDFF6E4),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
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
                                    "Gratulerer! Du har fullført alle oppgavene for i dag!",
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
                        : StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user!.uid)
                                .collection('completedTasks')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }

                              final docs = snapshot.data?.docs ?? [];
                              final Map<String, Map<String, dynamic>> roomDataMap = {
                                for (var doc in docs) doc.id: doc.data() as Map<String, dynamic>
                              };

                              final roomIcons = {
                                'Baderom': Icons.bathtub_outlined,
                                'Kjøkken': Icons.kitchen_outlined,
                                'Soverom': Icons.bed_outlined,
                                'Stue og barnerom': Icons.weekend_outlined,
                                'Inngang': Icons.door_front_door_outlined,
                              };

                              return ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: dailyItems.length,
                                itemBuilder: (context, index) {
                                  final item = dailyItems[index];
                                  final String room = item['title'];
                                  final List<String> roomTasks = item['description'].split('\n');
                                  final rData = roomDataMap[room] ?? {};
                                  final bool isRoomCompleted = rData['completed'] == true;
                                  final IconData icon = roomIcons[room] ?? Icons.home_outlined;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    color: Colors.white,
                                    elevation: 3,
                                    shadowColor: Colors.black12,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ExpansionTile(
                                      leading: Icon(icon, color: AppColors.accent3, size: 28),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              room,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.accentDark,
                                              ),
                                            ),
                                          ),
                                          if (isRoomCompleted) ...[
                                            const SizedBox(width: 8),
                                            _buildRoomCompleterBadge(room, rData['completedBy']),
                                          ],
                                        ],
                                      ),
                                      shape: const Border(),
                                      collapsedShape: const Border(),
                                      childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      children: [
                                        for (int ti = 0; ti < roomTasks.length; ti++)
                                          Builder(
                                            builder: (context) {
                                              final String taskText = roomTasks[ti];
                                              final bool isTaskDone = rData['checkbox_$ti'] == true;
                                              final String? completedByProfileId = rData['completedBy_checkbox_$ti'] as String?;
                                              final completerProfile = completedByProfileId == null
                                                  ? null
                                                  : _profiles.cast<FamilyProfile?>().firstWhere(
                                                        (p) => p?.id == completedByProfileId,
                                                        orElse: () => null,
                                                      );

                                              return Container(
                                                margin: const EdgeInsets.symmetric(vertical: 6),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryBackground.withValues(alpha: 0.5),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isTaskDone
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
                                                            taskText,
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
                                                            color: isTaskDone
                                                                ? Colors.green.withValues(alpha: 0.15)
                                                                : Colors.orange.withValues(alpha: 0.15),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            isTaskDone ? 'Fullført' : 'Gjenstår',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                              color: isTaskDone ? Colors.green.shade800 : Colors.orange.shade800,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Checkbox(
                                                          value: isTaskDone,
                                                          activeColor: AppColors.accent3,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(5),
                                                          ),
                                                          onChanged: (bool? v) {
                                                            _saveDailyCheckboxState(room, ti, v ?? false);
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                    if (completerProfile != null) ...[
                                                      const SizedBox(height: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: completerProfile.color.withValues(alpha: 0.15),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(
                                                            color: completerProfile.color.withValues(alpha: 0.3),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              completerProfile.emoji,
                                                              style: const TextStyle(fontSize: 12),
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              completerProfile.name,
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.bold,
                                                                color: completerProfile.color,
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
                                        const SizedBox(height: 12),
                                        Builder(
                                          builder: (context) {
                                            bool allTasksChecked = true;
                                            for (int i = 0; i < roomTasks.length; i++) {
                                              if (rData['checkbox_$i'] != true) {
                                                allTasksChecked = false;
                                                break;
                                              }
                                            }

                                            if (allTasksChecked && !isRoomCompleted) {
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  height: 44,
                                                  child: ElevatedButton.icon(
                                                    onPressed: () {
                                                      _completeDailyRoom(room);
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Kjempebra! Du har fullført alle oppgaver for $room! 🎉'),
                                                          backgroundColor: AppColors.accent3,
                                                          behavior: SnackBarBehavior.floating,
                                                        ),
                                                      );
                                                    },
                                                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                                                    label: Text(
                                                      'Fullfør $room',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppColors.accent3,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          }
                                        ),
                                      ],
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

  Widget _buildRoomCompleterBadge(String room, String? profileId) {
    if (profileId == null) return const SizedBox.shrink();

    final profile = _profiles.cast<FamilyProfile?>().firstWhere(
          (p) => p?.id == profileId,
          orElse: () => null,
        );
    if (profile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: profile.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: profile.color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(profile.emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            profile.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: profile.color,
            ),
          ),
        ],
      ),
    );
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
    'spray overflater met hverdagsflasken',
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

    for (String room in tasks.keys) {
      final roomRef = completedTasksRef.doc(room);
      final Map<String, dynamic> resetData = {
        'completed': false,
        'completedBy': FieldValue.delete(),
      };
      
      final List<String> roomTasks = tasks[room] ?? [];
      for (int i = 0; i < roomTasks.length; i++) {
        resetData['checkbox_$i'] = false;
        resetData['completedBy_checkbox_$i'] = FieldValue.delete();
      }

      await roomRef.set(resetData, SetOptions(merge: true));
    }

    print("Tasks reset successfully for user ${user.email}!");
  } catch (e) {
    print("Error resetting tasks: $e");
  }
}
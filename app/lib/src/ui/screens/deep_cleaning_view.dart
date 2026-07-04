import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/models/family_profile.dart';
import 'package:ralu_norvegia/src/service/profile_service.dart';

class DeepCleaningTask {
  final String id;
  final String room;
  final String name;
  final String description;

  const DeepCleaningTask({
    required this.id,
    required this.room,
    required this.name,
    required this.description,
  });
}

const List<DeepCleaningTask> deepCleaningTasks = [
  // Kjøkken
  DeepCleaningTask(id: 'kjøkken_stekeovn', room: 'Kjøkken', name: 'Rengjøre stekeovn', description: 'Rengjør stekeovn, rister og spor.'),
  DeepCleaningTask(id: 'kjøkken_kjøleskap', room: 'Kjøkken', name: 'Vaske inni kjøleskap', description: 'Tøm og vask alle hyller og skuffer inni kjøleskap og fryser.'),
  DeepCleaningTask(id: 'kjøkken_ventilator', room: 'Kjøkken', name: 'Rengjøre ventilator og filter', description: 'Ta ut filteret fra kjøkkenviften og rengjør det for fett.'),
  DeepCleaningTask(id: 'kjøkken_oppvaskmaskin', room: 'Kjøkken', name: 'Rense oppvaskmaskin', description: 'Rens filteret og kjør en rensemaskin på høy temperatur.'),

  // Baderom
  DeepCleaningTask(id: 'baderom_sluk', room: 'Baderom', name: 'Rense sluk i dusj', description: 'Fjern hår og rense sluket grundig med avløpsrens.'),
  DeepCleaningTask(id: 'baderom_fliser', room: 'Baderom', name: 'Skrubbe fliser og dusjfuger', description: 'Fjern kalk og skitt fra fliser og fuger i dusjsonen.'),
  DeepCleaningTask(id: 'baderom_vaskemaskin', room: 'Baderom', name: 'Vaske vaskemaskin og lofilter', description: 'Rens filteret og kjør maskinrens på høy temperatur.'),
  DeepCleaningTask(id: 'baderom_ventil', room: 'Baderom', name: 'Rengjøre ventilasjonsventil', description: 'Tørk støv og rengjør ventilen i taket eller på veggen.'),

  // Stue
  DeepCleaningTask(id: 'stue_vinduer', room: 'Stue', name: 'Rense og vaske vinduer', description: 'Vask vinduer innvendig og utvendig, inkludert karmer.'),
  DeepCleaningTask(id: 'stue_hoyeflater', room: 'Stue', name: 'Støvtørke høye skap', description: 'Tørk støv på toppen av høye skap, hyller og listverk.'),
  DeepCleaningTask(id: 'stue_dyprense_sofa', room: 'Stue', name: 'Dyprense sofa og tepper', description: 'Støvsug under puter og dyprens tekstiler med rensemaskin.'),
  DeepCleaningTask(id: 'stue_bak_mobler', room: 'Stue', name: 'Vaske bak tunge møbler', description: 'Dra frem sofa, TV-benk og vask grundig bak dem.'),

  // Soverom
  DeepCleaningTask(id: 'soverom_madrass', room: 'Soverom', name: 'Støvsuge og snu madrassen', description: 'Støvsug madrassen grundig og snu den 180 grader.'),
  DeepCleaningTask(id: 'soverom_dyner', room: 'Soverom', name: 'Vaske dyner og puter', description: 'Vask dyner, puter og overmadrassbeskytter på 60 grader.'),
  DeepCleaningTask(id: 'soverom_klesskap', room: 'Soverom', name: 'Rydde og tørke inni klesskap', description: 'Tørk støv på hyller og skuffer inni klesskapet.'),

  // Inngang
  DeepCleaningTask(id: 'inngang_ytterdor', room: 'Inngang', name: 'Vaske ytterdør og listverk', description: 'Vask ytterdøren på begge sider, samt karmer og lister.'),
  DeepCleaningTask(id: 'inngang_skohyller', room: 'Inngang', name: 'Rydde og vaske skohyller/skap', description: 'Tørk av skohyller og rengjør skoskapet for sesongsko.'),
  DeepCleaningTask(id: 'inngang_dormatter', room: 'Inngang', name: 'Rense og vaske dørmatter', description: 'Rist, støvsug og vask dørmattene ordentlig.'),
];

class DeepCleaningView extends StatefulWidget {
  const DeepCleaningView({Key? key}) : super(key: key);

  @override
  State<DeepCleaningView> createState() => _DeepCleaningViewState();
}

class _DeepCleaningViewState extends State<DeepCleaningView> {
  final User? user = FirebaseAuth.instance.currentUser;
  
  String? _activeProfileId;
  List<FamilyProfile> _profiles = [];
  bool _loadingProfiles = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    if (user == null) return;
    try {
      final pId = await ProfileService.getActiveProfileId();
      final list = await ProfileService.getProfiles(user!.uid);
      if (mounted) {
        setState(() {
          _activeProfileId = pId;
          _profiles = list;
          _loadingProfiles = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading profiles in deep cleaning: $e");
      if (mounted) {
        setState(() => _loadingProfiles = false);
      }
    }
  }

  String _getDayFor(DateTime d) {
    const days = ['Luni','Marti','Miercuri','Joi','Vineri','Sambata','Duminica'];
    return days[d.weekday - 1];
  }

  int _isoWeekday(DateTime d) => d.weekday;

  String _getWeekFor(DateTime d) {
    final thursday = d.add(Duration(days: 3 - ((_isoWeekday(d) + 6) % 7)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstWeekStart =
        firstThursday.subtract(Duration(days: (firstThursday.weekday + 6) % 7));
    final week = ((thursday.difference(firstWeekStart).inDays) / 7).floor() + 1;
    final year = thursday.year;
    return 'Y$year-W${week.toString().padLeft(2, '0')}';
  }

  Future<void> _completeDeepCleaningTask(String taskId) async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('deepCleaning')
          .doc(taskId)
          .set({
        'lastCompleted': FieldValue.serverTimestamp(),
        'completedBy': _activeProfileId,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Oppgaven markert som fullført! 🎉'),
          backgroundColor: AppColors.accent3,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("Error completing deep cleaning task: $e");
    }
  }

  Future<void> _delegateDeepCleaningTask(String taskId, String? profileId) async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('deepCleaning')
          .doc(taskId)
          .set({
        'delegatedTo': profileId ?? FieldValue.delete(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileId == null 
              ? 'Delegering fjernet' 
              : 'Oppgaven tildelt et familiemedlem'),
          backgroundColor: AppColors.accent3,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("Error delegating deep cleaning task: $e");
    }
  }

  Future<void> _addTaskToSelectedDay(String taskName, String? delegatedProfileId, String day) async {
    if (user == null) return;
    try {
      final now = DateTime.now();
      final currentWeek = _getWeekFor(now);

      final dayRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('userProgress')
          .doc(currentWeek)
          .collection('days')
          .doc(day);

      final locRef = dayRef.collection('locations').doc('loc_dyp_cleaning');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final locSnap = await transaction.get(locRef);

        List<String> tasks = [];
        List<String> taskIds = [];
        Map<String, bool> done = {};
        Map<String, dynamic> delegations = {};

        if (locSnap.exists) {
          final data = locSnap.data()!;
          tasks = List<String>.from(data['tasks'] ?? []);
          taskIds = List<String>.from(data['taskIds'] ?? []);
          done = Map<String, bool>.from(data['done'] ?? {});
          delegations = Map<String, dynamic>.from(data['delegations'] ?? {});
        }

        if (!tasks.contains(taskName)) {
          final newIndex = tasks.length;
          tasks.add(taskName);
          taskIds.add('Dyp::Periodic::$taskName');
          done['$newIndex'] = false;
          if (delegatedProfileId != null) {
            delegations['$newIndex'] = delegatedProfileId;
          }

          transaction.set(locRef, {
            'index': 99,
            'name': 'Dyp rengjøring',
            'type': 'Dyp',
            'tasks': tasks,
            'taskIds': taskIds,
            'done': done,
            'delegations': delegations,
            'completed': false,
          }, SetOptions(merge: true));

          if (!locSnap.exists) {
            transaction.set(dayRef, {
              'nrLoc': FieldValue.increment(1),
            }, SetOptions(merge: true));
          }
        }
      });

      final locsSnap = await dayRef.collection('locations').get();
      int doneCount = 0, totalCount = 0;
      for (final d in locsSnap.docs) {
        final data = d.data();
        final tasks = List<String>.from(data['tasks'] ?? const <String>[]);
        final doneMap = Map<String, dynamic>.from(data['done'] ?? {});
        totalCount += tasks.length;
        for (int i = 0; i < tasks.length; i++) {
          if ((doneMap['$i'] ?? false) == true) doneCount++;
        }
      }
      final progress = totalCount == 0 ? 0.0 : (doneCount / totalCount);
      await dayRef.set({
        'progress': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final String norwegianDay;
      switch (day) {
        case 'Luni': norwegianDay = 'mandag'; break;
        case 'Marti': norwegianDay = 'tirsdag'; break;
        case 'Miercuri': norwegianDay = 'onsdag'; break;
        case 'Joi': norwegianDay = 'torsdag'; break;
        case 'Vineri': norwegianDay = 'fredag'; break;
        default: norwegianDay = 'valgt dag';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lagt til "$taskName" på $norwegianDay! 📅'),
          backgroundColor: AppColors.accent3,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("Error copying task to selected day: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kunne ikke legge til oppgaven. Prøv igjen.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showScheduleModal(String taskName, String? delegatedProfileId) {
    const days = [
      {'name': 'I dag', 'key': 'today'},
      {'name': 'Mandag', 'key': 'Luni'},
      {'name': 'Tirsdag', 'key': 'Marti'},
      {'name': 'Onsdag', 'key': 'Miercuri'},
      {'name': 'Torsdag', 'key': 'Joi'},
      {'name': 'Fredag', 'key': 'Vineri'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Velg dag å planlegge',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentDark,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    return ListTile(
                      leading: const Icon(Icons.calendar_today_outlined, color: AppColors.accent3),
                      title: Text(
                        day['name']!,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        final dayKey = day['key']!;
                        final targetDay = dayKey == 'today' ? _getDayFor(DateTime.now()) : dayKey;
                        _addTaskToSelectedDay(taskName, delegatedProfileId, targetDay);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showDelegationModal(String taskId, String? currentDelegation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Deleger oppgave',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentDark,
                ),
              ),
              const SizedBox(height: 16),
              if (_profiles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Text(
                      'Ingen profiler opprettet ennå.',
                      style: TextStyle(color: AppColors.primaryText2),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _profiles.length,
                    itemBuilder: (context, index) {
                      final p = _profiles[index];
                      final isSelected = p.id == currentDelegation;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: p.color.withValues(alpha: 0.15),
                          child: Text(p.emoji, style: const TextStyle(fontSize: 20)),
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: AppColors.primaryText,
                          ),
                        ),
                        trailing: isSelected 
                            ? const Icon(Icons.check, color: AppColors.accent3) 
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _delegateDeepCleaningTask(taskId, p.id);
                        },
                      );
                    },
                  ),
                ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(Icons.person_remove_outlined, color: AppColors.warning),
                ),
                title: const Text(
                  'Fjern delegering',
                  style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _delegateDeepCleaningTask(taskId, null);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Du må være logget inn for å se periodiske oppgaver.',
              style: TextStyle(color: AppColors.primaryText2, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_loadingProfiles) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final Map<String, List<DeepCleaningTask>> tasksByRoom = {};
    for (var task in deepCleaningTasks) {
      tasksByRoom.putIfAbsent(task.room, () => []).add(task);
    }

    final roomKeys = tasksByRoom.keys.toList();
    final roomIcons = {
      'Kjøkken': Icons.kitchen_outlined,
      'Baderom': Icons.bathtub_outlined,
      'Stue': Icons.weekend_outlined,
      'Soverom': Icons.bed_outlined,
      'Inngang': Icons.door_front_door_outlined,
    };

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('deepCleaning')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final dataMap = {
            for (var doc in snapshot.data?.docs ?? [])
              doc.id: doc.data() as Map<String, dynamic>
          };

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: roomKeys.length,
            itemBuilder: (context, index) {
              final room = roomKeys[index];
              final roomTasks = tasksByRoom[room] ?? [];
              final icon = roomIcons[room] ?? Icons.home_outlined;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.white,
                elevation: 3,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  leading: Icon(icon, color: AppColors.accent3, size: 28),
                  title: Text(
                    room,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentDark,
                    ),
                  ),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: roomTasks.map((task) {
                    final data = dataMap[task.id] ?? {};
                    final Timestamp? lastCompleted = data['lastCompleted'] as Timestamp?;
                    final String? delegatedTo = data['delegatedTo'] as String?;
                    final String? completedBy = data['completedBy'] as String?;

                    // Calculate days ago
                    int? daysAgo;
                    if (lastCompleted != null) {
                      daysAgo = DateTime.now().difference(lastCompleted.toDate()).inDays;
                    }

                    // Done within 90 days badge status
                    final bool isOk = daysAgo != null && daysAgo <= 90;

                    final delegatedProfile = delegatedTo == null
                        ? null
                        : _profiles.firstWhere((p) => p.id == delegatedTo, orElse: () => _profiles.first);

                    final completerProfile = completedBy == null
                        ? null
                        : _profiles.firstWhere((p) => p.id == completedBy, orElse: () => _profiles.first);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBackground.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOk ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      task.description,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.primaryText2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // OK or Attention badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isOk 
                                      ? Colors.green.withValues(alpha: 0.15) 
                                      : Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isOk ? 'OK' : 'Trenger vask',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isOk ? Colors.green.shade800 : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Last completed text
                              Icon(
                                Icons.access_time_rounded, 
                                size: 14, 
                                color: AppColors.primaryText2.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  daysAgo == null
                                      ? 'Sist gjort: Aldri'
                                      : (daysAgo == 0
                                          ? 'Sist gjort: I dag'
                                          : 'Sist gjort: $daysAgo dager siden') +
                                          (completerProfile != null ? ' (${completerProfile.emoji} ${completerProfile.name})' : ''),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryText2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Actions row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Delegation pill or delegate button
                              GestureDetector(
                                onTap: () => _showDelegationModal(task.id, delegatedTo),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: delegatedProfile != null 
                                        ? delegatedProfile.color.withValues(alpha: 0.15) 
                                        : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: delegatedProfile != null 
                                          ? delegatedProfile.color.withValues(alpha: 0.3) 
                                          : Colors.grey.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        delegatedProfile != null ? Icons.person : Icons.person_add_alt_1,
                                        size: 14,
                                        color: delegatedProfile != null 
                                            ? delegatedProfile.color 
                                            : AppColors.primaryText2,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        delegatedProfile != null 
                                            ? '${delegatedProfile.emoji} ${delegatedProfile.name}' 
                                            : 'Deleger',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: delegatedProfile != null 
                                              ? delegatedProfile.color 
                                              : AppColors.primaryText2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  // Planlegg button
                                  TextButton.icon(
                                    onPressed: () => _showScheduleModal(task.name, delegatedTo),
                                    icon: const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.accent3),
                                    label: const Text(
                                      'Planlegg',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent3,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Done button
                                  ElevatedButton.icon(
                                    onPressed: () => _completeDeepCleaningTask(task.id),
                                    icon: const Icon(Icons.done, size: 16, color: Colors.white),
                                    label: const Text(
                                      'Fullført',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent3,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

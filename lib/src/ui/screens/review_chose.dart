import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import '../../service/firestore_bootstrap.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';

class ReviewChose extends StatefulWidget {
  final String optionType; // legacy, nefolosit
  final Map<String, String?> weekPlan; // legacy, nefolosit
  final String userId;

   ReviewChose({
    super.key,
    required this.optionType,
    required this.weekPlan,
     required this.userId,
  });

  @override
  State<ReviewChose> createState() => _ReviewChoseState();
}

class _ReviewChoseState extends State<ReviewChose> {
  bool _isLoading = false;

  // Predefined tasks for each day
  final Map<String, List<String>> defaultTasks = {
    "Luni": ["Spală vasele", "Șterge praful"],
    "Marti": ["Aspiră podeaua", "Curăță geamurile"],
    "Miercuri": ["Curăță baia", "Șterge oglinzile"],
    "Joi": ["Golește coșul de gunoi", "Organizează dulapurile"],
    "Vineri": ["Aspiră covoarele", "Șterge mobila"],
    "Sambata": ["Spală hainele", "Curăță bucătăria"],
    "Duminica": ["Relaxează-te", "Planifică săptămâna viitoare"],
  };

  final Map<String, String> dayTranslations = {
    'Luni': 'Mandag',
    'Marti': 'Tirsdag',
    'Miercuri': 'Onsdag',
    'Joi': 'Torsdag',
    'Vineri': 'Fredag',
    'Sambata': 'Lørdag',
    'Duminica': 'Søndag',
  };

  Future<void> saveToFirestore({
    required Map<String, Map<String, List<String>>> planWeeks,
    required Map<String, String> weekHeaders,
  }) async {
    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      final weeklyTasksRef = FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('weeklyTasks');

      final List<String> dayOrder = ['Luni','Marti','Miercuri','Joi','Vineri'];

      for (final week in planWeeks.keys) {
        final days = planWeeks[week]!;
        final daysRef = weeklyTasksRef.doc(week).collection('days');

        for (final day in dayOrder) {
          if (!days.containsKey(day)) continue;
          final locs = days[day]!;
          await daysRef.doc(day).set({
            'locatii': locs,
            'nrLoc': locs.length,
            'suprafata': weekHeaders[week] ?? '',
            'tasks': defaultTasks[day] ?? [],
          }, SetOptions(merge: true));
        }

        // scriem header și pe documentul săptămânii
        await weeklyTasksRef.doc(week).set({
          'header': weekHeaders[week] ?? '',
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving weekly tasks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final extras = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final Map<String, Map<String, List<String>>> planWeeks = (extras?['planWeeks'] as Map?)
            ?.map((wk, days) => MapEntry(
                  wk as String,
                  (days as Map).map((d, list) => MapEntry(d as String, List<String>.from(list as List))),
                ))
            ?? <String, Map<String, List<String>>>{};
    final Map<String, String> weekHeaders = (extras?['weekHeaders'] as Map?)
            ?.map((k, v) => MapEntry(k as String, v as String))
            ?? <String, String>{};
    final String optType = (extras?['optionType'] as String?) ?? widget.optionType;

    return Stack(
      children: [
        Scaffold(backgroundColor: AppColors.primaryBackground,
          appBar: AppBar(
            title: const Text("Gjennomgå valg"),
            // leading: IconButton(
            //   icon: const Icon(Icons.arrow_back),
            //   onPressed: () {
            //     GoRouter.of(context).go(
            //       ChooseOptionPath,
            //     extra: {
            //       'userId': userId, // Transmite userId sau alte date necesare
            //   },
            //     );
            //   },
            // ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.go(RoomsSetupPath);
              },
            ),
          ),
          body: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header text in the refreshed style
        const Text(
          "Se gjennom ukesplanen",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 12),

        // Content list
        Expanded(
          child: ListView(
            children: [
              for (final week in planWeeks.keys) ...[
                // Card for each week
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Week header row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                week,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                            if (weekHeaders[week] != null && weekHeaders[week]!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.crop_square, size: 14, color: AppColors.accent3),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Fokus: ${weekHeaders[week]}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primaryText2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0x11000000)),
                        const SizedBox(height: 8),

                        // Days list within the week card
                        for (final day in const ['Luni','Marti','Miercuri','Joi','Vineri'])
                          if (planWeeks[week]!.containsKey(day))
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2.0),
                                    child: Icon(Icons.calendar_today, size: 18, color: AppColors.accent3),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dayTranslations[day] ?? day,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          planWeeks[week]![day]!.isEmpty
                                              ? 'Ingen områder'
                                              : planWeeks[week]![day]!.join(', '),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.primaryText2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Confirm button full-width, styled
        SafeArea(
          top: false,
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent3,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                onPressed: () async {
                  setState(() { _isLoading = true; });
                  try {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) return;

                    await FirestoreBootstrap.saveWeeklyPlan(
                      uid: uid,
                      planWeeks: planWeeks,
                      weekHeaders: weekHeaders,
                      defaultTasksPerDay: defaultTasks,
                    );

                    await FirestoreBootstrap.resetCompletedTasks(
                      uid: uid,
                      planWeeks: planWeeks,
                    );
                    await FirestoreBootstrap.initializeUserProgress(
                      uid: uid,
                      planWeeks: planWeeks,
                      weekHeaders: weekHeaders,
                    );

                    // Set hasCompletedSetup to true in user's document
                    await FirebaseFirestore.instance.collection('users').doc(uid).set({
                      'hasCompletedSetup': true,
                    }, SetOptions(merge: true));

                    if (mounted) {
                      context.go(homePath);
                    }
                  } finally {
                    if (mounted) {
                      setState(() { _isLoading = false; });
                    }
                  }
                },
                child: const Text(
                  "Bekreft og opprett",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
        ),
        if (_isLoading)
          Container(
    color: Colors.black.withOpacity(0.35),
    child: Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Lagrer planen...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    ),
  )
      ],
    );
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import '../../service/firestore_bootstrap.dart';

class ReviewChose extends StatelessWidget {
  final String optionType; // legacy, nefolosit
  final Map<String, String?> weekPlan; // legacy, nefolosit
  final String userId;

   ReviewChose({
    super.key,
    required this.optionType,
    required this.weekPlan,
     required this.userId,
  });

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
    final String optType = (extras?['optionType'] as String?) ?? optionType;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Selecții"),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   "Tip Configurație: ${optType == "basic" ? "Basic" : "Custom"}",
            //   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            // ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: [
                  for (final week in planWeeks.keys) ...[
                    // Header de săptămână (linie simplă)
                  ListTile(
                    title: Text(
                      week,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: (weekHeaders[week] != null && weekHeaders[week]!.isNotEmpty)
                        ? Text('Suprafață: ${weekHeaders[week]}')
                        : null,
                  ),
                    // Zilele în ordine fixă
                    for (final day in const ['Luni','Marti','Miercuri','Joi','Vineri'])
                      if (planWeeks[week]!.containsKey(day))
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text(day),
                          subtitle: Text(
                            planWeeks[week]![day]!.isEmpty
                                ? 'Fără locații'
                                : planWeeks[week]![day]!.join(', '),
                          ),
                        ),
                    const Divider(height: 24),
                  ],
                ],
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return;

                // scriem planul complet (weeklyTasks)
                await FirestoreBootstrap.saveWeeklyPlan(
                  uid: uid,
                  planWeeks: planWeeks,
                  weekHeaders: weekHeaders,
                  defaultTasksPerDay: defaultTasks,
                );

                // pregătim completedTasks (schelet/reset)
                await FirestoreBootstrap.resetCompletedTasks(
                  uid: uid,
                  planWeeks: planWeeks,
                );

                context.go(homePath);
              },
              child: const Text("Confirmă și Creează"),
            ),
          ],
        ),
      ),
    );
  }
}
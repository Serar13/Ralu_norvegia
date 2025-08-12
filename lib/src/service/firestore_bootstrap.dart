import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Map<String, Map<String, List<String>>> _TASKS_BY_ROOM_AND_CATEGORY = {
  'Kjøkken': {
    'Tak og vegger': [
      'Flekkfjerning på tak/vegger',
      'Taklister',
      'Hengt belysning',
      'Vinduer/ventilasjon',
      'Persienner/gardiner',
      'Bilder og rammer',
      'Stikkontakter og brytere',
      'Dør med karm',
    ],
    'Inventar': [
      'Oppvaskmaskin (systemrens, filter)',
      'Mikrobølgeovn (innvendig/utvendig)',
      'Stekeovn (innvendig/utvendig)',
      'Kokeplate',
      'Vifte med filter',
      'Kjøleskap (inn/ut)',
      'Fryser',
      'Kaffemaskin/elkoker',
      'Benkeplate',
      'Skap og skuffer',
      'Blandebatteri og vask',
    ],
    'Gulv': [
      'Gulvlister',
      'Overflater (støvsuging, vask – under og bak møbler/hvitevarer)',
      'Gulvmatter/tepper',
    ],
  },
  'Baderom': {
    'Tak og vegger': [
      'Ventilasjon',
      'Vinduer',
      'Flekkfjerning på vegger',
      'Lysarmatur',
      'Stikkontakter',
      'Brytere',
      'Dør med karm',
    ],
    'Inventar': [
      'Hyller',
      'Skap/skuffer (oppe, inni, fronter, under, bak)',
      'Dusj og badekar',
      'Vask (blandebatteri, oppi/under)',
      'Toalettsete og børste',
      'Avfallskurv',
    ],
    'Gulv': [
      'Overflater (støvsuging, vask)',
      'Bak og under skap/toalett',
      'Sluk',
      'Baderomsmatter',
    ],
  },
  'Stue': {
    'Tak og vegger': [
      'Vinduer/ventilasjon',
      'Flekkfjerning på vegger',
      'Persienner/gardiner',
      'Bilder/rammer/vegglamper',
      'Stikkontakter og brytere',
      'Dør med karm',
    ],
    'Inventar': [
      'Hyller med pynt',
      'Skap/skuffer',
      'Kommoder',
      'Gulvlamper',
      'TV og benk',
      'Spisebord/stoler',
      'Sofa/lenestoler',
      'Puter/tepper',
      'Peis',
    ],
    'Gulv': ['Gulvlister', 'Støvsuging/vask under og bak møbler', 'Gulvmatter/tepper'],
  },
  'Inngangsparti': {
    'Tak og vegger': [
      'Flekkfjerning på vegger',
      'Ventilasjon',
      'Bilder/rammer',
      'Stikkontakter og brytere',
      'Dør med karm',
    ],
    'Inventar': [
      'Skoskap (inn/ut)', 'Klesskap (organisering)', 'Kommoder', 'Hyller med pynt'
    ],
    'Gulv': ['Gulvlister', 'Overflater (støvsuging, vask)', 'Gulvmatter/tepper'],
  },
  'Gang': {
    'Tak og vegger': [
      'Vinduer/ventilasjon', 'Flekkfjerning på vegger', 'Persienner/gardiner',
      'Stikkontakter og brytere', 'Taklister', 'Hengt belysning'
    ],
    'Inventar': ['Skap/skuffer', 'Kommoder', 'Hyller med pynt', 'Gulvlamper'],
    'Gulv': ['Gulvlister', 'Overflater (støvsuging, vask)', 'Gulvmatter/tepper'],
  },
  'Trapp': {
    'Tak og vegger': [
      'Flekkfjerning på vegger', 'Vinduer/ventilasjon', 'Stikkontakter', 'Brytere'
    ],
    'Inventar': ['Hyller med pynt', 'Rekkverk'],
    'Gulv': ['Gulvlister', 'Trappetrinn (støvsuging/vask)', 'Under trapp'],
  },
  'Gjestebad': {
    'Tak og vegger': [
      'Ventilasjon', 'Vinduer', 'Flekkfjerning på vegger', 'Lysarmatur',
      'Stikkontakter', 'Brytere', 'Dør med karm'
    ],
    'Inventar': [
      'Hyller', 'Skap/skuffer', 'Dusj', 'Vask', 'Toalettsete/børste', 'Avfallskurv'
    ],
    'Gulv': ['Gulvlister', 'Overflater (støvsuging, vask)', 'Sluk', 'Baderomsmatter'],
  },
  'Vaskerom': {
    'Tak og vegger': [
      'Flekkfjerning på vegger', 'Persienner/gardiner', 'Bilder/rammer',
      'Stikkontakter og brytere', 'Dør med karm', 'Ventilasjon'
    ],
    'Inventar': [
      'Skap/skuffer', 'Hyller', 'Vaskemaskin (rens/filter)', 'Tørketrommel (rens)',
      'Vaskemidler/utstyr', 'Varmtvannstank', 'Avfallskurv', 'Blandebatteri/vask'
    ],
    'Gulv': ['Gulvlister', 'Overflater (støvsuging, vask)', 'Gulvmatter/tepper'],
  },
  'Soverom': {
    'Tak og vegger': [
      'Flekkfjerning på vegger', 'Persienner/gardiner', 'Vinduer/ventilasjon',
      'Bilder/rammer', 'Vegglamper', 'Stikkontakter og brytere', 'Dør med karm'
    ],
    'Inventar': [
      'Madrass', 'Sengeramme', 'Puterdyner', 'Nattbord', 'Klesskap', 'Kommoder', 'Hyller'
    ],
    'Gulv': ['Gulvlister', 'Overflater (støvsuging, vask, under/bak møbler)', 'Gulvmatter'],
  },
  'Garderoberom': {
    'Tak og vegger': [
      'Flekkfjerning på vegger', 'Persienner/gardiner', 'Speil', 'Stikkontakter',
      'Brytere', 'Dør med karm', 'Ventilasjon', 'Vegglamper'
    ],
    'Inventar': ['Klesskap', 'Kommoder', 'Pynt'],
    'Gulv': ['Gulvlister', 'Overflater (støvsuging, vask)', 'Gulvmatter/tepper'],
  },
};

class FirestoreBootstrap {
  static final _db = FirebaseFirestore.instance;

  static const List<String> dayOrder = ['Luni', 'Marti', 'Miercuri', 'Joi', 'Vineri'];

  /// 1) Creează scheletul de bază pt user (profil + colecții goale)
  static Future<void> ensureUserSkeleton({
    required String uid,
    String? email,
  }) async {
    final userRef = _db.collection('users').doc(uid);

    // profil minimal (merge: true nu strică ce există)
    await userRef.set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // colecțiile: completedTasks și weeklyTasks (doar schelet)
    final completedRef = userRef.collection('completedTasks');
    for (final d in dayOrder) {
      await completedRef.doc(d).set({}, SetOptions(merge: true));
    }

    final weeklyRef = userRef.collection('weeklyTasks');
    for (final uke in ['Uke 1', 'Uke 2', 'Uke 3', 'Uke 4']) {
      await weeklyRef.doc(uke).set({'header': ''}, SetOptions(merge: true));
      final daysRef = weeklyRef.doc(uke).collection('days');
      for (final d in dayOrder) {
        await daysRef.doc(d).set({}, SetOptions(merge: true));
      }
    }
  }

  /// 2) Salvează planul pe săptămâni/zile (Review → Confirm)
  /// planWeeks: { 'Uke 1': { 'Luni': ['Kjøkken 1', ...], ... }, ... }
  static Future<void> saveWeeklyPlan({
    required String uid,
    required Map<String, Map<String, List<String>>> planWeeks,
    required Map<String, String> weekHeaders,
    required Map<String, List<String>> defaultTasksPerDay, // dacă ai mapping per zi
  }) async {
    final weeklyRef = _db.collection('users').doc(uid).collection('weeklyTasks');

    for (final week in planWeeks.keys) {
      final header = weekHeaders[week] ?? '';
      await weeklyRef.doc(week).set({'header': header}, SetOptions(merge: true));

      final days = planWeeks[week]!;
      final daysRef = weeklyRef.doc(week).collection('days');

      for (final day in dayOrder) {
        if (!days.containsKey(day)) continue;
        final locs = days[day]!;

        // Extrage tipul camerei din denumire (ex: "Kjøkken 1" -> "Kjøkken")
        final roomTypes = locs
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .map((s) => s.split(' ').first)
            .toSet();

        final category = header; // "Tak og vegger" / "Inventar" / "Gulv"
        final List<String> mergedTasks = [];
        for (final rt in roomTypes) {
          final t = _TASKS_BY_ROOM_AND_CATEGORY[rt]?[category] ?? const <String>[];
          for (final x in t) {
            if (!mergedTasks.contains(x)) mergedTasks.add(x);
          }
        }

        // Construiți payload conform cerinței (locatie, locatie1, ... nrLoc string)
        final Map<String, dynamic> payload = {
          'nrLoc': locs.length.toString(),
          'suprafata': header,
          'tasks': mergedTasks,
        };
        if (locs.isNotEmpty) {
          payload['locatie'] = locs[0];
          for (int i = 1; i < locs.length; i++) {
            payload['locatie$i'] = locs[i];
          }
        }

        await daysRef.doc(day).set(payload, SetOptions(merge: true));
      }
    }
  }

  /// Marchează un task ca "făcut" / "nefăcut" într-o anumită săptămână/zi.
  /// Nu atingem `completedTasks`. Scriem într-un câmp local pe zi: `doneTasks` (array de string).
  static Future<void> toggleTaskDone({
    required String uid,
    required String week, // ex: 'Uke 2'
    required String day,  // ex: 'Luni'
    required String task,
    required bool done,
  }) async {
    final ref = _db
        .collection('users').doc(uid)
        .collection('weeklyTasks').doc(week)
        .collection('days').doc(day);

    if (done) {
      await ref.set(
        {'doneTasks': FieldValue.arrayUnion([task])},
        SetOptions(merge: true),
      );
    } else {
      await ref.set(
        {'doneTasks': FieldValue.arrayRemove([task])},
        SetOptions(merge: true),
      );
    }

    // Dacă se bifează în Uke 2, propagăm imediat în Uke 3 (ascundem din Uke 3 cele bifate în 2)
    if (week == 'Uke 2') {
      await propagateWeek2ToWeek3(uid: uid);
    }
  }

  /// Citește ce s-a bifat în Uke 2 și elimină acele task‑uri din Uke 3 (pentru aceeași zi).
  static Future<void> propagateWeek2ToWeek3({required String uid}) async {
    final weeklyRef = _db.collection('users').doc(uid).collection('weeklyTasks');

    for (final day in dayOrder) {
      final week2Ref = weeklyRef.doc('Uke 2').collection('days').doc(day);
      final week3Ref = weeklyRef.doc('Uke 3').collection('days').doc(day);

      final w2 = await week2Ref.get();
      final w3 = await week3Ref.get();

      final List<String> doneW2 =
          List<String>.from((w2.data() ?? const {})['doneTasks'] ?? const <String>[]);
      if (doneW2.isEmpty) continue;

      final List<String> tasksW3 =
          List<String>.from((w3.data() ?? const {})['tasks'] ?? const <String>[]);

      // Filtrăm Uke 3: scoatem ce s-a făcut în Uke 2
      final filtered = tasksW3.where((t) => !doneW2.contains(t)).toList();

      await week3Ref.set({'tasks': filtered}, SetOptions(merge: true));
    }
  }

  /// 3) Creează scheletul pt completedTasks (toate checkbox-urile false)
  /// Poți apela asta la confirm dacă vrei să resetezi progresul.
  static Future<void> resetCompletedTasks({
    required String uid,
    required Map<String, Map<String, List<String>>> planWeeks,
  }) async {
    final completedRef = _db.collection('users').doc(uid).collection('completedTasks');

    for (final d in dayOrder) {
      // inițial nu bifăm nimic; poți genera „checkbox_0: false, ...” dacă vrei
      await completedRef.doc(d).set({
        'resetAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
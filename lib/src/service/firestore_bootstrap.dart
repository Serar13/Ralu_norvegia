import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// lib/src/service/firestore_bootstrap.dart

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

  // 🔧 STUE — completat după tabel
  'Stue': {
    'Tak og vegger': [
      'Flekkfjerning på taket',
      'Taklister',
      'Hengt belysning',
      'Flekkfjerning på vegger',
      'Vinduer/ventilasjon',
      'Persienner/gardiner',
      'Bilder, rammer, hengt pynt, vegglamper',
      'Stikkontakter',
      'Brytere',
      'Dør med karm',
    ],
    'Inventar': [
      'Hyller med pynt',
      'Skap/skuffer',
      'Kommoder',
      'Gulvlamper',
      'TV (med benk)',
      'Spisebord med stoler',
      'Sofa/lenestoler (støvsuging, flekkfjerning)',
      'Puter, tepper (vask putetrekk, vask/luft tepper)',
      'Peis',
    ],
    'Gulv': [
      'Gulvlister',
      'Overflate (støvsuging, vask – under og bak møbler)',
      'Gulvmatter/tepper',
    ],
  },

  // 🔧 INNGANGSPARTI — completat după tabel
  'Inngangsparti': {
    'Tak og vegger': [
      'Flekkfjerning på taket',
      'Taklister',
      'Hengt belysning',
      'Flekkfjerning på vegger',
      'Ventilasjon',
      'Bilder, rammer, hengt pynt, vegglamper',
      'Stikkontakter',
      'Brytere',
      'Dør med karm',
    ],
    'Inventar': [
      'Skoskap (innvendig, utvendig), skobrett',
      'Klesskap (organisering, støvsuging, vask inn- og utvendig)',
      'Kommoder (organisering, vask inn- og utvendig, bak)',
      'Hyller med pynt gjenstander',
    ],
    'Gulv': [
      'Gulvlister',
      'Overflater (støvsuging, vask)',
      'Gulvmatter/tepper',
    ],
  },

  // 🔧 GANG — completat după tabel
  'Gang': {
    'Tak og vegger': [
      'Vinduer/ventilasjon',
      'Flekkfjerning på vegger',
      'Persienner/gardiner',
      'Bilder, rammer, hengt pynt, vegglamper',
      'Stikkontakter',
      'Brytere',
      'Dør med karm',
      'Flekkfjerning på taket',
      'Taklister',
      'Hengt belysning',
    ],
    'Inventar': [
      'Skap/skuffer (oppå, inni, fronter, under, bak)',
      'Kommoder (organisering, vask inn- og utvendig, bak)',
      'Hyller med pynt gjenstander',
      'Gulvlamper',
    ],
    'Gulv': [
      'Gulvlister',
      'Overflate (støvsuging, vask)',
      'Gulvmatter/tepper',
    ],
  },

  // 🔧 TRAPP — completat după tabel
  'Trapp': {
    'Tak og vegger': [
      'Flekkfjerning på taket',
      'Taklister',
      'Hengt belysning',
      'Flekkfjerning på vegger',
      'Vinduer/ventilasjon',
      'Bilder, rammer, hengt pynt, vegglamper',
      'Stikkontakter',
      'Brytere',
    ],
    'Inventar': [
      'Hyller med pynt gjenstander',
      'Rekkverk',
    ],
    'Gulv': [
      'Gulvlister',
      'Trappetrinn (støvsuging, vask)',
      'Trappetepper (støvsuging, flekkfjerning)',
      'Under trapp (støvsuging/vask)',
    ],
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
      'Skap/skuffer', 'Hyller',
      'Vaskemaskin (rens/filter)', 'Tørketrommel (rens)',
      'Vaskemidler/utstyr til oppbevaring (tørk, vask, påfyll)',
      'Varmtvannstank (tørk/vask)',
      'Avfallskurv (tørk/vask)',
      'Blandebatteri/vask (innvendig, plugg hull, under)',
    ],
    'Gulv': ['Gulvlister', 'Overflater (støvsuging, vask)', 'Gulvmatter/tepper'],
  },

  'Soverom': {
    'Tak og vegger': [
      'Flekkfjerning på vegger', 'Persienner/gardiner', 'Vinduer/ventilasjon',
      'Bilder/rammer', 'Vegglamper', 'Stikkontakter og brytere', 'Dør med karm'
    ],
    'Inventar': [
      'Madrass', 'Sengeramme', 'Puterdyner (vask ved behov)',
      'Nattbord', 'Klesskap (organisering, støvsuging, fronter)',
      'Kommoder (organisering, fronter)', 'Hyller med pynt gjenstander'
    ],
    'Gulv': ['Gulvlister', 'Overflater (støvsuging, vask, under/bak møbler)', 'Gulvmatter'],
  },

  'Garderoberom': {
    'Tak og vegger': [
      'Flekkfjerning på vegger', 'Persienner/gardiner', 'Speil', 'Stikkontakter',
      'Brytere', 'Dør med karm', 'Ventilasjon', 'Vegglamper'
    ],
    'Inventar': ['Klesskap (organisering, støvsuging/støvtørking, fronter)', 'Kommoder (organisering, fronter)', 'Pynt'],
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
  /// Initialize per-user progress tree: users/{uid}/userProgress/{Uke}/days/{Zi}/locations/loc_{i}
  /// Each location holds its own task list based on its room type and the week's category.
  static Future<void> initializeUserProgress({
    required String uid,
    required Map<String, Map<String, List<String>>> planWeeks,
    required Map<String, String> weekHeaders,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final progressRef = userRef.collection('userProgress');

    for (final week in planWeeks.keys) {
      final header = weekHeaders[week] ?? '';

      // Ensure week doc exists
      await progressRef.doc(week).set({
        'header': header,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final daysForWeek = planWeeks[week]!; // { 'Luni': [locs], ... }
      for (final day in dayOrder) {
        if (!daysForWeek.containsKey(day)) continue;
        final locs = daysForWeek[day] ?? const <String>[];

        // Category for this week (Tak og vegger / Inventar / Gulv)
        final String category = header;

        // Create the day node
        final dayRef = progressRef.doc(week).collection('days').doc(day);
        await dayRef.set({
          'nrLoc': locs.length,
          'suprafata': header,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // For each location, create a location doc with the tasks & a boolean map
        final locationsRef = dayRef.collection('locations');
        for (int i = 0; i < locs.length; i++) {
          final name = locs[i];
          final String roomType = (name.trim().isEmpty ? name : name.trim()).split(' ').first;
          final List<String> tasks = List<String>.from(
            _TASKS_BY_ROOM_AND_CATEGORY[roomType]?[category] ?? const <String>[],
          );

          // Build `done` map per task index and stable task ids
          final Map<String, bool> done = {
            for (int ti = 0; ti < tasks.length; ti++) '$ti': false,
          };
          final List<String> taskIds = [
            for (final t in tasks) '$roomType::$category::$t',
          ];

          await locationsRef.doc('loc_$i').set({
            'index': i,
            'name': name,
            'type': roomType,
            'tasks': tasks,
            'taskIds': taskIds,
            'done': done,
            'completed': false,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    }
  }
}
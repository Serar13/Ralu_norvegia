// -----------------------------------------------------------------------------
// Shared schema constants for the Ralu Norvegia admin dashboard.
// -----------------------------------------------------------------------------
// The mobile app clones `weeklyTasks/{uke}/days/{day}` into each user's week,
// then tracks completion under `users/{uid}/completedTasks/{room}`. These
// constants describe the canonical shape (Uke 1–4, Norwegian weekdays, and the
// default room → tasks templates that ship with the app).

export const WEEK_KEYS = ['Uke 1', 'Uke 2', 'Uke 3', 'Uke 4'];

export const DAY_KEYS = [
  'Mandag',
  'Tirsdag',
  'Onsdag',
  'Torsdag',
  'Fredag',
  'Lørdag',
  'Søndag',
];

// Default rooms/locations and their tasks, mirroring the Flutter app's
// `_initializeCompletedTasksForUser` (lib/src/ui/screens/sing_in.dart). Used to
// seed the Room Manager and to pre-fill new weekly-template days.
export const DEFAULT_ROOMS = [
  {
    id: 'baderom',
    name: 'Baderom',
    icon: '🛁',
    order: 1,
    tasks: [
      'bruk vindusnal på dusjdørene etter dusjing',
      'fei/støvsug/mopp gulvet',
      'sett ting tilbake på plass',
      'ta ut ting som ikke hører hjemme på badet',
      'tørk fort over speil, vask og toalett',
      'åpne vinduene i minst 10 minutter',
    ],
  },
  {
    id: 'kjokken',
    name: 'Kjøkken',
    icon: '🍳',
    order: 2,
    tasks: [
      'bruk en glassklut på kokeplata',
      'fei/støvsug/mop gulvet',
      'rydd benkeplater',
      'spray overflater med hverdagsflasken',
      'ta ut søppel',
      'tøm oppvasken',
      'tørk overflater tørre etter vask',
      'åpne vinduene i minst 10 minutter',
    ],
  },
  {
    id: 'soverom',
    name: 'Soverom',
    icon: '🛏️',
    order: 3,
    tasks: [
      're opp sengen',
      'ta ut skitne klær or håndklær',
      'ta ut ting som ikke hører hjemme på soverommet',
      'åpne vinduene i minst 10 minutter',
    ],
  },
  {
    id: 'stue_barnerom',
    name: 'Stue og barnerom',
    icon: '🛋️',
    order: 4,
    tasks: [
      'rydd ting på plass',
      'tørk søl umiddelbart',
      'åpne vinduene i minst 10 minutter',
    ],
  },
  {
    id: 'inngang',
    name: 'Inngang',
    icon: '🚪',
    order: 5,
    tasks: [
      'bruk en håndhelt batteridrevet støvsuger på gulvet',
      'heng jakker or klær tilbake på plass',
      'sett sko tilbake på plass',
      'åpne vinduene i minst 10 minutter',
    ],
  },
];

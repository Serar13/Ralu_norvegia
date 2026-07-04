// -----------------------------------------------------------------------------
// Firestore data access layer for the admin dashboard.
// -----------------------------------------------------------------------------
// All reads/writes against the `ralunorvegia` project live here so the pages
// stay declarative. Functions are intentionally tolerant of the two shapes the
// app has used for room tasks: an array of task strings, or a map { task: bool }.

import {
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  setDoc,
  writeBatch,
} from 'firebase/firestore';
import { db } from '../firebase.js';
import { DAY_KEYS, DEFAULT_ROOMS, WEEK_KEYS } from './constants.js';

/* ----------------------------- helpers ---------------------------------- */

// Normalise a room's task value (array OR { task: bool } map) to string[].
export function toTaskArray(value) {
  if (Array.isArray(value)) return value.filter((t) => typeof t === 'string');
  if (value && typeof value === 'object') return Object.keys(value);
  return [];
}

// Best-effort millisecond timestamp from Firestore Timestamp | number | string.
export function toMillis(value) {
  if (!value) return null;
  if (typeof value?.toMillis === 'function') return value.toMillis();
  if (typeof value === 'number') return value;
  const parsed = Date.parse(value);
  return Number.isNaN(parsed) ? null : parsed;
}

/* ------------------------------- users ---------------------------------- */

// Load every user profile from `users`. Names in the app are stored under the
// slightly unusual keys "first name" / "last name", so we surface a friendly
// display name while keeping the raw doc available.
export async function listUsers() {
  const snap = await getDocs(collection(db, 'users'));
  return snap.docs.map((d) => {
    const data = d.data();
    const first = data['first name'] ?? data.firstName ?? '';
    const last = data['last name'] ?? data.lastName ?? '';
    const displayName = `${first} ${last}`.trim() || data.name || '—';
    return {
      id: d.id,
      displayName,
      email: data.email ?? '—',
      phone: data['phone number'] ?? data.phoneNumber ?? '',
      role: data.role ?? (data.isAdmin || data.admin ? 'admin' : 'user'),
      points: Number(data.points ?? 0),
      streak: Number(data.streak ?? data.currentStreak ?? data.streakCount ?? 0),
      createdAtMillis: toMillis(data.createdAt),
      raw: data,
    };
  });
}

/* --------------------------- weekly templates --------------------------- */

// Read a single template day: weeklyTasks/{uke}/days/{day}.
// Returns { room: string[] } — one entry per room in the day document.
export async function getTemplateDay(uke, day) {
  const ref = doc(db, 'weeklyTasks', uke, 'days', day);
  const snap = await getDoc(ref);
  if (!snap.exists()) return {};
  const data = snap.data();
  const rooms = {};
  for (const [room, value] of Object.entries(data)) {
    rooms[room] = toTaskArray(value);
  }
  return rooms;
}

// Overwrite a template day with the given { room: string[] } map. Uses setDoc
// without merge so removed rooms/tasks are actually deleted from the document.
export async function saveTemplateDay(uke, day, rooms) {
  const ref = doc(db, 'weeklyTasks', uke, 'days', day);
  // Ensure the parent week doc exists so it shows up in console listings.
  await setDoc(doc(db, 'weeklyTasks', uke), { label: uke }, { merge: true });
  const payload = {};
  for (const [room, tasks] of Object.entries(rooms)) {
    payload[room] = toTaskArray(tasks);
  }
  await setDoc(ref, payload); // full overwrite
}

// Remove a single room field from a template day.
export async function removeTemplateRoom(uke, day, room) {
  const ref = doc(db, 'weeklyTasks', uke, 'days', day);
  await setDoc(ref, { [room]: deleteField() }, { merge: true });
}

// Count total tasks configured for a whole week (across all days) — used for
// the overview cards. Cheap enough for 7 day-docs per week.
export async function getWeekSummary(uke) {
  const daysSnap = await getDocs(collection(db, 'weeklyTasks', uke, 'days'));
  let rooms = new Set();
  let tasks = 0;
  let configuredDays = 0;
  daysSnap.forEach((d) => {
    const data = d.data();
    const keys = Object.keys(data);
    if (keys.length) configuredDays += 1;
    keys.forEach((room) => {
      rooms.add(room);
      tasks += toTaskArray(data[room]).length;
    });
  });
  return { uke, configuredDays, rooms: rooms.size, tasks };
}

/* ------------------------------- rooms ---------------------------------- */

// Room/location templates live in a top-level `rooms` collection. This is a
// dashboard-managed convention (the app currently hardcodes these); seeding
// makes them editable centrally.
export async function listRooms() {
  const snap = await getDocs(collection(db, 'rooms'));
  return snap.docs
    .map((d) => {
      const data = d.data();
      return {
        id: d.id,
        name: data.name ?? d.id,
        icon: data.icon ?? '🧽',
        order: Number(data.order ?? 99),
        tasks: toTaskArray(data.tasks),
      };
    })
    .sort((a, b) => a.order - b.order);
}

export async function saveRoom(room) {
  const id = room.id || slugify(room.name);
  await setDoc(doc(db, 'rooms', id), {
    name: room.name,
    icon: room.icon ?? '🧽',
    order: Number(room.order ?? 99),
    tasks: toTaskArray(room.tasks),
  });
  return id;
}

export async function deleteRoom(id) {
  await deleteDoc(doc(db, 'rooms', id));
}

// One-click seed of the default Norwegian rooms into the `rooms` collection.
export async function seedDefaultRooms() {
  const batch = writeBatch(db);
  DEFAULT_ROOMS.forEach((r) => {
    batch.set(doc(db, 'rooms', r.id), {
      name: r.name,
      icon: r.icon,
      order: r.order,
      tasks: r.tasks,
    });
  });
  await batch.commit();
}

function slugify(name) {
  return (
    String(name)
      .toLowerCase()
      .normalize('NFD')
      .replace(/[̀-ͯ]/g, '')
      .replace(/[æ]/g, 'ae')
      .replace(/[ø]/g, 'o')
      .replace(/[å]/g, 'a')
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_+|_+$/g, '') || `room_${Date.now()}`
  );
}

export { WEEK_KEYS, DAY_KEYS };

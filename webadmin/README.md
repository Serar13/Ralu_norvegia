# Ralu Norvegia — Admin dashboard (`/webadmin`)

Internal dashboard for the Ralu Norvegia team to manage users, weekly task
templates and room templates. Built with **React + Vite + React Router** and
**Firebase Auth + Firestore**.

Deployed to the Firebase Hosting target **`webadmin`** →
`https://ralunorvegia-admin.web.app`.

## Features

| Page | Route | What it does |
|------|-------|--------------|
| **Login** | `/login` | Firebase email/password sign-in |
| **Oversikt** (Dashboard) | `/` | Totals: users, admins, streak days, template tasks; week summaries; newest users |
| **Brukere** (Users) | `/users` | Lists every `users/{uid}` — name, role, streak, points, created date, with search |
| **Ukesmaler** (Task Templates) | `/templates` | Edit `weeklyTasks/{uke}/days/{day}` for Uke 1–4 — add/edit/delete rooms & chores |
| **Rom** (Rooms) | `/rooms` | Manage default room/location templates (`rooms` collection) + one-click seed |

## Admin authentication & route protection

- `src/context/AuthContext.jsx` wraps the app, tracks the Firebase Auth user and
  loads their `users/{uid}` document.
- `resolveIsAdmin()` grants access when the profile has `role === 'admin'`
  (or `superadmin`), or a boolean `isAdmin`/`admin` field.
- `src/components/ProtectedRoute.jsx` gates every dashboard route: it shows a
  loader while resolving, redirects to `/login` when signed out, and shows an
  "access denied" screen for signed-in non-admins.

> For the User Overview and template editing to work, Firestore rules must let
> admins read all users and write `weeklyTasks`/`rooms`. See
> [`firestore.rules`](../firestore.rules) at the repo root.

## Structure

```
webadmin/
├─ index.html            # noindex; loads Kanit
├─ vite.config.js        # build → dist/, react/firebase vendor chunks
├─ .env.example
├─ public/favicon.svg
└─ src/
   ├─ main.jsx           # Router + AuthProvider
   ├─ App.jsx            # <Routes> definition
   ├─ firebase.js        # exports app / auth / db
   ├─ context/AuthContext.jsx
   ├─ components/  Layout.jsx  ProtectedRoute.jsx  Icons.jsx
   ├─ pages/       Login  Dashboard  Users  TaskTemplates  Rooms  NotFound
   ├─ lib/
   │  ├─ constants.js    # WEEK_KEYS, DAY_KEYS, DEFAULT_ROOMS (from the app)
   │  └─ api.js          # Firestore data access layer
   └─ styles/index.css   # dashboard design system
```

## Local development

```bash
cd webadmin
cp .env.example .env      # optional — firebase.js falls back to public keys
npm install
npm run dev               # http://localhost:5174
```

To sign in you need a Firebase Auth account whose `users/{uid}` document has
`role: "admin"` (set it in the Firebase console or the mobile app's DB).

## Build

```bash
npm run build             # outputs to webadmin/dist
npm run preview
```

Deployment is documented in the repo-root [`WEB_DEPLOYMENT.md`](../WEB_DEPLOYMENT.md).

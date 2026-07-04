# Ralu Norvegia — Web deployment guide

This repo hosts three things, kept in **separate folders**:

| Folder       | What it is                          | Firebase Hosting target |
|--------------|-------------------------------------|-------------------------|
| root (`lib/`, `android/`, `ios/`, …) | The Flutter **app**   | — (mobile) |
| `site/`      | Public **landing website** (React)  | `site`      |
| `webadmin/`  | Internal **admin dashboard** (React) | `webadmin` |

Both React apps deploy to the **same Firebase project** (`ralunorvegia`) using
**Firebase Hosting multi-site**.

---

## 1. One-time setup

### 1a. Install & log in to the Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### 1b. Create the two Hosting sites

The project's **default** site (`ralunorvegia` → `ralunorvegia.web.app`) is used
for the landing page. Create a **second** site for the admin panel:

```bash
# Landing site already exists as the default site (ralunorvegia.web.app).
# Create a dedicated site for the admin dashboard:
firebase hosting:sites:create ralunorvegia-admin
#   → https://ralunorvegia-admin.web.app
```

> Multi-site Hosting requires the **Blaze** (pay-as-you-go) plan. Pick different
> site IDs if these are taken — then update `.firebaserc` to match.

### 1c. Map the deploy targets to the sites

`.firebaserc` already declares the mapping, so this is usually a no-op, but you
can (re)apply it explicitly:

```bash
firebase target:apply hosting site     ralunorvegia
firebase target:apply hosting webadmin ralunorvegia-admin
```

`.firebaserc` (already committed):

```json
{
  "projects": { "default": "ralunorvegia" },
  "targets": {
    "ralunorvegia": {
      "hosting": {
        "site":     ["ralunorvegia"],
        "webadmin": ["ralunorvegia-admin"]
      }
    }
  }
}
```

### 1d. (Optional) Environment variables

Both apps read Firebase config from `VITE_*` env vars with a fallback to the
project's public web keys, so this step is optional:

```bash
cp site/.env.example     site/.env
cp webadmin/.env.example webadmin/.env
```

---

## 2. Deploy both sites in one go

From the **repo root**:

```bash
# 1. Build the landing site
cd site && npm ci && npm run build && cd ..

# 2. Build the admin dashboard
cd webadmin && npm ci && npm run build && cd ..

# 3. Deploy BOTH hosting targets together
firebase deploy --only hosting
```

`firebase deploy --only hosting` deploys every target in `firebase.json`
(`site` + `webadmin`) in a single command.

### One-liner

```bash
(cd site && npm ci && npm run build) && \
(cd webadmin && npm ci && npm run build) && \
firebase deploy --only hosting
```

### Deploy just one target

```bash
firebase deploy --only hosting:site       # landing page only
firebase deploy --only hosting:webadmin   # admin dashboard only
```

---

## 3. (Optional) Deploy the Firestore security rules

The admin dashboard needs admins to read all `users` and write the
`weeklyTasks` / `rooms` collections. Rules that support **both** the app and the
dashboard live in [`firestore.rules`](./firestore.rules).

> ⚠️ **Review first.** Deploying replaces the project's current rules and could
> affect the live mobile app. Deploy them deliberately and on their own:

```bash
firebase deploy --only firestore:rules
```

To make an account an admin, set `role: "admin"` (or `isAdmin: true`) on its
`users/{uid}` document in the Firebase console.

---

## 4. `firebase.json` (root)

The Flutter FlutterFire block is preserved; the `hosting` array and `firestore`
block were added for the two React apps:

```jsonc
{
  "flutter": { /* … FlutterFire config, untouched … */ },
  "firestore": { "rules": "firestore.rules", "indexes": "firestore.indexes.json" },
  "hosting": [
    { "target": "site",     "public": "site/dist",     "rewrites": [{ "source": "**", "destination": "/index.html" }] },
    { "target": "webadmin", "public": "webadmin/dist", "rewrites": [{ "source": "**", "destination": "/index.html" }] }
  ]
}
```

The `rewrites` make each app a single-page app (all routes → `index.html`), so
React Router deep links like `/templates` work on refresh.

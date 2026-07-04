# Ralu Norvegia — Landing site (`/site`)

The public presentation website for the **Ralu Norvegia** household organization
& premium cleaning app. Built with **React + Vite**, styled to match the mobile
app (Kanit typography, pastel Nordic palette, soft rounded shapes).

Deployed to the Firebase Hosting target **`site`** → `https://ralunorvegia.web.app`.

## Structure

```
site/
├─ index.html            # entry HTML, loads Kanit from Google Fonts
├─ vite.config.js        # build → dist/, vendor chunk splitting
├─ .env.example          # Firebase web keys (copy to .env)
├─ public/favicon.svg
└─ src/
   ├─ main.jsx           # React root + optional Analytics init
   ├─ App.jsx            # section composition
   ├─ firebase.js        # Firebase connection helper (env-driven)
   ├─ styles/index.css   # design system (tokens + component styles)
   └─ components/
      ├─ Navbar.jsx  Hero.jsx  Features.jsx  Showcase.jsx
      ├─ HowItWorks.jsx  CTA.jsx  Footer.jsx
      ├─ PhoneMockup.jsx # in-browser rendering of the app screens
      └─ Icons.jsx       # inline SVG icons
```

## Local development

```bash
cd site
cp .env.example .env      # optional — firebase.js falls back to public keys
npm install
npm run dev               # http://localhost:5173
```

## Build

```bash
npm run build             # outputs to site/dist
npm run preview           # serve the production build locally
```

## Environment variables

Vite only exposes vars prefixed with `VITE_`. See `.env.example`. The values are
the **web** app credentials of the `ralunorvegia` Firebase project (mirrors
`/lib/firebase_options.dart`). Web API keys are not secrets — access is governed
by Firestore/Storage security rules — but keeping them in `.env` makes swapping
environments trivial. `src/firebase.js` falls back to the public keys so the
site builds even without a `.env` file.

Deployment is documented in the repo-root [`WEB_DEPLOYMENT.md`](../WEB_DEPLOYMENT.md).

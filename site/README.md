# Ralu Norvegia — Business site (`/site`)

The public **cleaning-services** website for **Ralu Norvegia** (premium renhold
in Oslo og omegn). It sells the team's services — fast vaskehjelp, engangsvask,
flyttevask, hovedrengjøring, kontorvask, vindusvask — with pricing, reviews and
a booking form. The mobile app is featured as one supporting section, not the
whole story. Built with **React + Vite**, styled to match the app (Kanit
typography, pastel Nordic palette, soft rounded shapes).

Deployed to the Firebase Hosting target **`site`** → `https://ralunorvegia.web.app`.

## ✏️ Editing the content — start here

**All business copy lives in [`src/content.js`](./src/content.js)** — company
info, contact details, services, prices, testimonials and stats. Update that one
file to plug in the real values; the components read from it. Values marked
`TODO:` are placeholders (phone, e-mail, org.nr, prices, reviews) to replace
before going live.

Real photos go in [`public/images/`](./public/images/README.md) — drop them in
and reference `/images/...`, or swap the hero `Illustration` for a photograph.

## Structure

```
site/
├─ index.html            # entry HTML, loads Kanit from Google Fonts
├─ vite.config.js        # build → dist/, vendor chunk splitting
├─ .env.example          # Firebase web keys (copy to .env)
├─ public/
│  ├─ favicon.svg
│  └─ images/            # drop real photos here
└─ src/
   ├─ main.jsx           # React root + optional Analytics init
   ├─ content.js         # ← ALL editable business copy & prices
   ├─ App.jsx            # section composition
   ├─ firebase.js        # Firebase connection helper (env-driven)
   ├─ styles/index.css   # design system (tokens + component styles)
   └─ components/
      ├─ Navbar.jsx  Hero.jsx  TrustBar.jsx  Services.jsx  Pricing.jsx
      ├─ HowItWorks.jsx  Stats.jsx  AppSection.jsx  Testimonials.jsx
      ├─ Contact.jsx  CTA.jsx  Footer.jsx
      ├─ Illustration.jsx # hero vector art (swap for a photo)
      ├─ PhoneMockup.jsx  # in-browser rendering of the app screen
      └─ Icons.jsx        # inline SVG icons
```

## Booking form

`Contact.jsx` composes a pre-filled `mailto:` to `contact.email` on submit — it
works with **no backend**. Swap it for a Firestore write or a form service
(Formspree, etc.) when you want submissions stored server-side.

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

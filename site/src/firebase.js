// -----------------------------------------------------------------------------
// Firebase connection helper (landing site)
// -----------------------------------------------------------------------------
// The landing site only needs a lightweight Firebase connection (e.g. for
// Analytics or a future "join the waitlist" form). Auth/Firestore heavy lifting
// lives in the /webadmin project.
//
// Config is read from Vite env vars (see .env.example). We fall back to the
// public web credentials of the `ralunorvegia` project so the site still builds
// and runs if no .env file is present — Firebase web API keys are safe to ship
// to the client; real protection comes from Firestore/Storage security rules.

import { initializeApp } from 'firebase/app';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY ?? 'AIzaSyBHWgucuXfqfClcu738fXH1zT_GpTKrdhM',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN ?? 'ralunorvegia.firebaseapp.com',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID ?? 'ralunorvegia',
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET ?? 'ralunorvegia.appspot.com',
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID ?? '775850665665',
  appId: import.meta.env.VITE_FIREBASE_APP_ID ?? '1:775850665665:web:1c78adf7f69ab8e8f7d640',
  measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID ?? 'G-5KXERDYQPM',
};

export const app = initializeApp(firebaseConfig);

// Analytics is optional and only works in browsers that support it, so we guard
// it behind a dynamic import to avoid breaking SSR/build and older browsers.
export async function initAnalytics() {
  if (typeof window === 'undefined') return null;
  try {
    const { getAnalytics, isSupported } = await import('firebase/analytics');
    if (await isSupported()) return getAnalytics(app);
  } catch {
    // Analytics is non-critical for the landing page.
  }
  return null;
}

export default app;

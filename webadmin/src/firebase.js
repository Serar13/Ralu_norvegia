// -----------------------------------------------------------------------------
// Firebase connection helper (admin dashboard)
// -----------------------------------------------------------------------------
// Initialises the Firebase app and exposes the Auth + Firestore singletons used
// across the dashboard. Config comes from Vite env vars (see .env.example) with
// a fallback to the public `ralunorvegia` web credentials so the app builds and
// runs even without a .env file. The web API key is safe to ship to the client;
// admin protection is enforced by Auth + Firestore security rules.

import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

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
export const auth = getAuth(app);
export const db = getFirestore(app);

export default app;

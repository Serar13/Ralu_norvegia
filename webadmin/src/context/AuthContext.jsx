import { createContext, useContext, useEffect, useState } from 'react';
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut as fbSignOut,
} from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from '../firebase.js';

const AuthContext = createContext(null);

// Reads users/{uid} and decides whether the account has admin privileges.
// We accept a few shapes so the check works regardless of how the flag was set
// on a given profile: role === 'admin', or a boolean isAdmin/admin field.
export function resolveIsAdmin(profile) {
  if (!profile) return false;
  const role = String(profile.role ?? '').toLowerCase();
  return (
    role === 'admin' ||
    role === 'superadmin' ||
    profile.isAdmin === true ||
    profile.admin === true
  );
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null); // Firebase Auth user
  const [profile, setProfile] = useState(null); // users/{uid} document
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (fbUser) => {
      setError(null);
      if (!fbUser) {
        setUser(null);
        setProfile(null);
        setIsAdmin(false);
        setLoading(false);
        return;
      }

      setUser(fbUser);
      try {
        const snap = await getDoc(doc(db, 'users', fbUser.uid));
        const data = snap.exists() ? { id: snap.id, ...snap.data() } : null;
        setProfile(data);
        setIsAdmin(resolveIsAdmin(data));
      } catch (e) {
        // If the profile can't be read (e.g. security rules), treat as non-admin.
        setProfile(null);
        setIsAdmin(false);
        setError(e);
      } finally {
        setLoading(false);
      }
    });

    return unsub;
  }, []);

  async function signIn(email, password) {
    setError(null);
    const cred = await signInWithEmailAndPassword(auth, email.trim(), password);
    // Re-check admin status immediately so the caller can react without waiting
    // for the auth listener to settle.
    const snap = await getDoc(doc(db, 'users', cred.user.uid));
    const data = snap.exists() ? { id: snap.id, ...snap.data() } : null;
    const admin = resolveIsAdmin(data);
    setProfile(data);
    setIsAdmin(admin);
    return { user: cred.user, isAdmin: admin };
  }

  async function signOut() {
    await fbSignOut(auth);
  }

  const value = { user, profile, isAdmin, loading, error, signIn, signOut };
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider');
  return ctx;
}

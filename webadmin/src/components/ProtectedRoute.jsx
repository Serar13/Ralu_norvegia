import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';
import { Logout } from './Icons.jsx';

// Gate for admin-only routes. Three outcomes:
//  1. still resolving auth/profile      -> full-screen loader
//  2. not signed in                     -> redirect to /login
//  3. signed in but not an admin        -> "access denied" screen
export default function ProtectedRoute({ children }) {
  const { user, isAdmin, loading, signOut } = useAuth();

  if (loading) {
    return (
      <div className="center-state" style={{ minHeight: '100vh' }}>
        <div>
          <div className="spinner" />
          <p>Verifiserer tilgang…</p>
        </div>
      </div>
    );
  }

  if (!user) return <Navigate to="/login" replace />;

  if (!isAdmin) {
    return (
      <div className="login-wrap">
        <div className="login-card" style={{ textAlign: 'center' }}>
          <div className="empty-emoji">🔒</div>
          <h1>Ingen admin-tilgang</h1>
          <p className="sub">
            Kontoen <strong>{user.email}</strong> er logget inn, men har ikke
            admin-rettigheter. Be en administrator om å sette{' '}
            <code>role: "admin"</code> på brukerdokumentet ditt.
          </p>
          <button className="btn btn-ghost" onClick={signOut} style={{ width: '100%' }}>
            <Logout width={18} height={18} /> Logg ut
          </button>
        </div>
      </div>
    );
  }

  return children;
}

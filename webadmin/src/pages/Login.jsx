import { useState } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';
import { Sparkle } from '../components/Icons.jsx';

// Maps common Firebase Auth error codes to friendly Norwegian copy.
function friendlyError(code) {
  switch (code) {
    case 'auth/invalid-email':
      return 'Ugyldig e-postadresse.';
    case 'auth/user-disabled':
      return 'Denne kontoen er deaktivert.';
    case 'auth/user-not-found':
    case 'auth/wrong-password':
    case 'auth/invalid-credential':
      return 'Feil e-post eller passord.';
    case 'auth/too-many-requests':
      return 'For mange forsøk. Prøv igjen om litt.';
    default:
      return 'Innlogging feilet. Prøv igjen.';
  }
}

export default function Login() {
  const { user, isAdmin, loading, signIn } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  // Already signed in as an admin? Skip the form.
  if (!loading && user && isAdmin) return <Navigate to="/" replace />;

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setSubmitting(true);
    try {
      const { isAdmin: admin } = await signIn(email, password);
      if (admin) {
        navigate('/', { replace: true });
      } else {
        setError('Denne kontoen har ikke admin-tilgang.');
      }
    } catch (err) {
      setError(friendlyError(err?.code));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="login-wrap">
      <form className="login-card" onSubmit={handleSubmit}>
        <img src="/logo.png" alt="Logo" style={{ width: 52, height: 52, borderRadius: 16, marginBottom: 16, objectFit: 'cover' }} />
        <h1>Admin innlogging</h1>
        <p className="sub">Ralu Norvegia · internt konsoll</p>

        {error && <div className="alert">{error}</div>}

        <div className="field">
          <label htmlFor="email">E-post</label>
          <input
            id="email"
            className="input"
            type="email"
            autoComplete="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="deg@ralunorvegia.no"
            required
          />
        </div>

        <div className="field">
          <label htmlFor="password">Passord</label>
          <input
            id="password"
            className="input"
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            required
          />
        </div>

        <button className="btn btn-primary" type="submit" disabled={submitting} style={{ width: '100%' }}>
          {submitting ? 'Logger inn…' : 'Logg inn'}
        </button>
      </form>
    </div>
  );
}

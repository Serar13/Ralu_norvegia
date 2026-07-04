import { useEffect, useMemo, useState } from 'react';
import { listUsers } from '../lib/api.js';
import { Search, Flame, Refresh } from '../components/Icons.jsx';

function fmtDate(ms) {
  if (!ms) return '—';
  return new Date(ms).toLocaleDateString('nb-NO', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
}

export default function UsersPage() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [users, setUsers] = useState([]);
  const [q, setQ] = useState('');

  async function load() {
    setLoading(true);
    setError('');
    try {
      setUsers(await listUsers());
    } catch (e) {
      setError(e.message ?? 'Kunne ikke laste brukere.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  const filtered = useMemo(() => {
    const term = q.trim().toLowerCase();
    const base = term
      ? users.filter(
          (u) =>
            u.displayName.toLowerCase().includes(term) ||
            u.email.toLowerCase().includes(term),
        )
      : users;
    return [...base].sort((a, b) => (b.streak || 0) - (a.streak || 0));
  }, [users, q]);

  return (
    <>
      <div className="section-actions">
        <div style={{ position: 'relative', maxWidth: 320, width: '100%' }}>
          <span style={{ position: 'absolute', left: 12, top: 11, color: 'var(--ink-faint)' }}>
            <Search width={18} height={18} />
          </span>
          <input
            className="input"
            style={{ paddingLeft: 38 }}
            placeholder="Søk navn eller e-post…"
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
        </div>
        <button className="btn btn-ghost" onClick={load} disabled={loading}>
          <Refresh width={18} height={18} /> Oppdater
        </button>
      </div>

      <div className="card">
        <div className="card-head">
          <div>
            <h3>Alle brukere</h3>
            <p>{filtered.length} bruker(e) · sortert etter streak</p>
          </div>
        </div>

        {loading ? (
          <div className="center-state">
            <div>
              <div className="spinner" />
              <p>Laster brukere…</p>
            </div>
          </div>
        ) : error ? (
          <div className="card-pad">
            <div className="alert">{error}</div>
          </div>
        ) : filtered.length === 0 ? (
          <div className="center-state">
            <div>
              <div className="empty-emoji">🔍</div>
              <p>Ingen brukere funnet.</p>
            </div>
          </div>
        ) : (
          <div className="table-wrap">
            <table className="data">
              <thead>
                <tr>
                  <th>Bruker</th>
                  <th>Rolle</th>
                  <th>Streak</th>
                  <th>Poeng</th>
                  <th>Registrert</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((u) => (
                  <tr key={u.id}>
                    <td>
                      <div className="user-cell">
                        <span className="avatar">{(u.displayName?.[0] ?? '?').toUpperCase()}</span>
                        <div>
                          <div style={{ fontWeight: 500 }}>{u.displayName}</div>
                          <div className="u-mail">{u.email}</div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <span className={`badge ${u.role === 'admin' ? 'badge-admin' : 'badge-user'}`}>
                        {u.role === 'admin' ? 'Admin' : 'Bruker'}
                      </span>
                    </td>
                    <td>
                      <span className="badge badge-streak">
                        <Flame width={13} height={13} /> {u.streak}
                      </span>
                    </td>
                    <td>{u.points}</td>
                    <td className="muted">{fmtDate(u.createdAtMillis)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </>
  );
}

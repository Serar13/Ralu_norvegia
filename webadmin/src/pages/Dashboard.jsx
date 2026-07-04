import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { getWeekSummary, listUsers } from '../lib/api.js';
import { WEEK_KEYS } from '../lib/constants.js';
import { Users, Flame, Calendar, Sparkle } from '../components/Icons.jsx';

function fmtDate(ms) {
  if (!ms) return '—';
  return new Date(ms).toLocaleDateString('nb-NO', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
}

export default function Dashboard() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [users, setUsers] = useState([]);
  const [weeks, setWeeks] = useState([]);

  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const [u, w] = await Promise.all([
          listUsers(),
          Promise.all(WEEK_KEYS.map((k) => getWeekSummary(k))),
        ]);
        if (!alive) return;
        setUsers(u);
        setWeeks(w);
      } catch (e) {
        if (alive) setError(e.message ?? 'Kunne ikke laste data.');
      } finally {
        if (alive) setLoading(false);
      }
    })();
    return () => {
      alive = false;
    };
  }, []);

  if (loading) {
    return (
      <div className="center-state">
        <div>
          <div className="spinner" />
          <p>Laster oversikt…</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="card card-pad">
        <div className="alert">{error}</div>
      </div>
    );
  }

  const admins = users.filter((u) => u.role === 'admin').length;
  const totalStreaks = users.reduce((s, u) => s + (u.streak || 0), 0);
  const totalTemplateTasks = weeks.reduce((s, w) => s + w.tasks, 0);

  const stats = [
    { label: 'Registrerte brukere', val: users.length, icon: Users, grad: 'linear-gradient(135deg,#add8e6,#72c0b3)' },
    { label: 'Administratorer', val: admins, icon: Sparkle, grad: 'linear-gradient(135deg,#72c0b3,#23767b)' },
    { label: 'Samlet streak-dager', val: totalStreaks, icon: Flame, grad: 'linear-gradient(135deg,#e18178,#d96a5f)' },
    { label: 'Oppgaver i maler', val: totalTemplateTasks, icon: Calendar, grad: 'linear-gradient(135deg,#8ec9e6,#23767b)' },
  ];

  const recent = [...users]
    .filter((u) => u.createdAtMillis)
    .sort((a, b) => b.createdAtMillis - a.createdAtMillis)
    .slice(0, 5);

  return (
    <>
      <div className="stat-grid">
        {stats.map(({ label, val, icon: Icon, grad }) => (
          <div className="stat" key={label}>
            <div className="stat-icon" style={{ background: grad }}>
              <Icon width={22} height={22} />
            </div>
            <div className="stat-val">{val}</div>
            <div className="stat-label">{label}</div>
          </div>
        ))}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: 22, alignItems: 'start' }} className="dash-grid">
        <div className="card">
          <div className="card-head">
            <div>
              <h3>Ukesmaler (Uke 1–4)</h3>
              <p>Malene som klones når brukere starter en ny uke.</p>
            </div>
            <Link to="/templates" className="btn btn-ghost btn-sm">
              Rediger maler
            </Link>
          </div>
          <div className="table-wrap">
            <table className="data">
              <thead>
                <tr>
                  <th>Uke</th>
                  <th>Konfigurerte dager</th>
                  <th>Rom</th>
                  <th>Oppgaver</th>
                </tr>
              </thead>
              <tbody>
                {weeks.map((w) => (
                  <tr key={w.uke}>
                    <td style={{ fontWeight: 600 }}>{w.uke}</td>
                    <td>{w.configuredDays} / 7</td>
                    <td>{w.rooms}</td>
                    <td>{w.tasks}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <div className="card">
          <div className="card-head">
            <div>
              <h3>Nyeste brukere</h3>
              <p>Sist registrerte kontoer.</p>
            </div>
            <Link to="/users" className="btn btn-ghost btn-sm">
              Alle
            </Link>
          </div>
          <div className="card-pad" style={{ paddingTop: 6 }}>
            {recent.length === 0 && <p className="muted">Ingen datoer registrert ennå.</p>}
            {recent.map((u) => (
              <div
                key={u.id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 12,
                  padding: '10px 0',
                  borderBottom: '1px dashed var(--line)',
                }}
              >
                <span className="avatar" style={{ width: 34, height: 34, borderRadius: '50%', display: 'grid', placeItems: 'center', background: 'linear-gradient(135deg,#add8e6,#72c0b3)', color: '#fff', fontWeight: 600, fontSize: '0.8rem', flex: 'none' }}>
                  {(u.displayName?.[0] ?? '?').toUpperCase()}
                </span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontWeight: 500, fontSize: '0.92rem' }}>{u.displayName}</div>
                  <div style={{ fontSize: '0.78rem', color: 'var(--ink-faint)' }}>{u.email}</div>
                </div>
                <span className="muted" style={{ fontSize: '0.8rem' }}>{fmtDate(u.createdAtMillis)}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </>
  );
}

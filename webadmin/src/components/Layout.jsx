import { NavLink, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';
import { Grid, Users, Calendar, Home, Sparkle, Logout } from './Icons.jsx';

const NAV = [
  { to: '/', label: 'Oversikt', icon: Grid, end: true, title: 'Oversikt', crumb: 'Dashbord' },
  { to: '/users', label: 'Brukere', icon: Users, title: 'Brukere', crumb: 'Administrasjon' },
  {
    to: '/templates',
    label: 'Ukesmaler',
    icon: Calendar,
    title: 'Ukesmaler',
    crumb: 'Innhold',
  },
  { to: '/rooms', label: 'Rom', icon: Home, title: 'Rom', crumb: 'Innhold' },
];

function initials(nameOrEmail = '') {
  const s = nameOrEmail.trim();
  if (!s) return 'A';
  const parts = s.split(/[\s@.]+/).filter(Boolean);
  return (parts[0]?.[0] ?? 'A').toUpperCase() + (parts[1]?.[0] ?? '').toUpperCase();
}

export default function Layout() {
  const { user, profile, signOut } = useAuth();
  const location = useLocation();
  const current = NAV.find((n) => (n.end ? location.pathname === '/' : location.pathname.startsWith(n.to))) ?? NAV[0];
  const displayName =
    `${profile?.['first name'] ?? ''} ${profile?.['last name'] ?? ''}`.trim() ||
    user?.email ||
    'Admin';

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">
          <span className="logo">
            <Sparkle width={22} height={22} color="#fff" />
          </span>
          <span>
            Ralu Norvegia
            <small>Admin konsoll</small>
          </span>
        </div>

        <div className="nav-group-label">Meny</div>
        <nav>
          {NAV.map(({ to, label, icon: Icon, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
            >
              <Icon width={19} height={19} />
              {label}
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-foot">
          <div className="sidebar-user">
            <span className="avatar">{initials(displayName)}</span>
            <span className="meta">
              <strong>{displayName}</strong>
              <span>{user?.email}</span>
            </span>
          </div>
          <button className="logout-btn" onClick={signOut}>
            <Logout width={18} height={18} /> Logg ut
          </button>
        </div>
      </aside>

      <div className="main">
        <header className="topbar">
          <div>
            <div className="crumb">{current.crumb}</div>
            <h1>{current.title}</h1>
          </div>
        </header>
        <main className="content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

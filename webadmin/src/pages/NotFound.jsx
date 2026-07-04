import { Link } from 'react-router-dom';

export default function NotFound() {
  return (
    <div className="login-wrap">
      <div className="login-card" style={{ textAlign: 'center' }}>
        <div className="empty-emoji">🧭</div>
        <h1>404</h1>
        <p className="sub">Denne siden finnes ikke i admin-konsollet.</p>
        <Link to="/" className="btn btn-primary" style={{ width: '100%' }}>
          Til oversikten
        </Link>
      </div>
    </div>
  );
}

import { Flame, Check, Bell } from './Icons.jsx';

// A stylised in-browser rendering of the mobile app screen. It mirrors the
// Flutter UI (light-blue top bar, points pill, "Ukentlig / Daglige gjøremål"
// tabs, Norwegian room tasks) so the landing page stays truthful to the app
// without shipping binary screenshots.

const WEEKLY = [
  { room: 'Baderom', label: 'Tørk over speil, vask og toalett', done: true },
  { room: 'Kjøkken', label: 'Rydd benkeplater', done: true },
  { room: 'Kjøkken', label: 'Tøm oppvasken', done: false },
  { room: 'Soverom', label: 'Re opp sengen', done: false },
  { room: 'Inngang', label: 'Sett sko tilbake på plass', done: false },
];

export default function PhoneMockup({
  variant = 'weekly',
  points = 240,
  streak = 12,
  className = '',
}) {
  const rows =
    variant === 'daily'
      ? [
          { room: 'Stue og barnerom', label: 'Rydd ting på plass', done: true },
          { room: 'Stue og barnerom', label: 'Tørk søl umiddelbart', done: true },
          { room: 'Inngang', label: 'Heng jakker tilbake', done: true },
          { room: 'Baderom', label: 'Åpne vinduene i 10 min', done: false },
        ]
      : WEEKLY;

  return (
    <div className={`phone ${className}`} role="img" aria-label="Ralu Norvegia mobilapp">
      <div className="phone-notch" />
      <div className="phone-screen">
        <div className="app-top">
          <div className="icon-btn">
            <Bell width={16} height={16} />
          </div>
          <div className="pill">
            <Flame width={14} height={14} />
            {points}
          </div>
          <div className="icon-btn">👤</div>
        </div>
        <div className="app-tabs">
          <span className={`t ${variant === 'weekly' ? 'active' : ''}`}>Ukentlig</span>
          <span className={`t ${variant === 'daily' ? 'active' : ''}`}>Daglige gjøremål</span>
        </div>
        <div className="app-body">
          {variant !== 'streak' && (
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                marginBottom: 4,
              }}
            >
              <strong style={{ fontSize: '0.9rem' }}>
                {variant === 'daily' ? 'I dag' : 'Uke 2 · Tirsdag'}
              </strong>
              <span
                style={{
                  fontSize: '0.72rem',
                  color: '#23767b',
                  background: 'rgba(114,192,179,.16)',
                  padding: '3px 9px',
                  borderRadius: 999,
                  fontWeight: 600,
                }}
              >
                🔥 {streak} dager
              </span>
            </div>
          )}
          {rows.map((r, i) => (
            <div key={i} className={`task-row ${r.done ? 'done' : ''}`}>
              <span className="check">{r.done && <Check width={14} height={14} />}</span>
              <span>
                <span className="label">{r.label}</span>
                <br />
                <span className="room">{r.room}</span>
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

import { stats } from '../content.js';

export default function Stats() {
  return (
    <section className="stats" aria-label="Nøkkeltall">
      <div className="container">
        <div className="stats-grid">
          {stats.map((s) => (
            <div className="stat-box" key={s.label}>
              <div className="s-val">{s.value}</div>
              <div className="s-label">{s.label}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

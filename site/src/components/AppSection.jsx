import PhoneMockup from './PhoneMockup.jsx';
import { Check } from './Icons.jsx';
import { app } from '../content.js';

export default function AppSection() {
  return (
    <section className="appsec" id="app">
      <div className="container appsec-grid">
        <div>
          <span className="eyebrow">Inkludert for kunder</span>
          <h2>{app.title}</h2>
          <p>{app.lead}</p>
          <ul className="app-points">
            {app.points.map((p) => (
              <li key={p}>
                <span className="tick"><Check width={13} height={13} /></span>
                {p}
              </li>
            ))}
          </ul>
        </div>
        <div className="appsec-visual">
          <PhoneMockup variant="weekly" />
        </div>
      </div>
    </section>
  );
}

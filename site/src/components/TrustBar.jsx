import { trustPoints } from '../content.js';

export default function TrustBar() {
  return (
    <section className="trustbar" aria-label="Våre garantier">
      <div className="container trustbar-inner">
        {trustPoints.map((t) => (
          <div className="trust-item" key={t.label}>
            <span className="t-emoji" aria-hidden="true">{t.icon}</span>
            {t.label}
          </div>
        ))}
      </div>
    </section>
  );
}

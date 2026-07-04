import { Check, ArrowRight } from './Icons.jsx';
import { services } from '../content.js';

export default function Services() {
  return (
    <section className="services" id="tjenester">
      <div className="container">
        <div className="section-head">
          <span className="eyebrow">Produkter & Tjenester</span>
          <h2>Renhold gjort enkelt</h2>
          <p>
            Alt du trenger for et renere hjem — fra smarte digitale verktøy til
            profesjonelt utstyr og guider.
          </p>
        </div>

        <div className="service-grid">
          {services.map((s) => (
            <article className={`service-card ${s.featured ? 'featured' : ''}`} key={s.id}>
              {s.featured && <span className="pill-tag">Mest valgt</span>}
              <div className="s-icon" aria-hidden="true">{s.icon}</div>
              <h3>{s.name}</h3>
              <p className="s-text">{s.text}</p>
              <ul className="s-points">
                {s.points.map((p) => (
                  <li key={p}>
                    <span className="tick"><Check width={12} height={12} /></span>
                    {p}
                  </li>
                ))}
              </ul>
              <div className="s-foot">
                <span className="s-price">{s.price}</span>
                <a className="btn btn-ghost" href="#kontakt">
                  Bestill <ArrowRight width={16} height={16} />
                </a>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

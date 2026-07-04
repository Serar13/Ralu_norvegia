import { Check } from './Icons.jsx';
import { pricing } from '../content.js';

export default function Pricing() {
  return (
    <section className="pricing" id="priser">
      <div className="container">
        <div className="section-head">
          <span className="eyebrow">Priser & Pakker</span>
          <h2>Velg det som passer deg best</h2>
          <p>Vi tilbyr både gratis ressurser, en smart mobilapp og komplette utstyrspakker for din husvask.</p>
        </div>

        <div className="price-grid">
          {pricing.plans.map((plan) => (
            <div className={`price-card ${plan.featured ? 'featured' : ''}`} key={plan.id}>
              {plan.tagline && <span className="p-tag">{plan.tagline}</span>}
              <h3>{plan.name}</h3>
              <div className="p-amount">
                <span className="num">{plan.price}</span>
                <span className="unit">{plan.unit}</span>
              </div>
              <ul className="p-includes">
                {plan.includes.map((item) => (
                  <li key={item}>
                    <span className="tick"><Check width={12} height={12} /></span>
                    {item}
                  </li>
                ))}
              </ul>
              <a className={`btn ${plan.featured ? 'btn-primary' : 'btn-ghost'}`} href="#kontakt">
                {plan.cta}
              </a>
            </div>
          ))}
        </div>

        <p className="price-note">{pricing.note}</p>
      </div>
    </section>
  );
}

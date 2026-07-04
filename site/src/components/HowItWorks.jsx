import { steps } from '../content.js';

export default function HowItWorks() {
  return (
    <section className="how" id="slik">
      <div className="container">
        <div className="section-head">
          <span className="eyebrow">Slik funker det</span>
          <h2>Rent hjem i tre enkle steg</h2>
          <p>Kom i gang med gode rengjøringsvaner på en-to-tre.</p>
        </div>

        <div className="steps">
          {steps.map((s) => (
            <article className="step" key={s.title}>
              <div className="s-emoji" aria-hidden="true">{s.icon}</div>
              <h3>{s.title}</h3>
              <p>{s.text}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

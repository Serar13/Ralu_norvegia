import { testimonials } from '../content.js';

export default function Testimonials() {
  return (
    <section className="reviews" id="anmeldelser">
      <div className="container">
        <div className="section-head">
          <span className="eyebrow">Anmeldelser</span>
          <h2>Kunder som elsker et rent hjem</h2>
          <p>Ekte tilbakemeldinger fra familier og bedrifter vi vasker for.</p>
        </div>

        <div className="review-grid">
          {testimonials.map((t) => (
            <figure className="review-card" key={t.name}>
              <div className="r-stars" aria-label={`${t.rating} av 5 stjerner`}>
                {'★'.repeat(t.rating)}
                {'☆'.repeat(5 - t.rating)}
              </div>
              <blockquote className="r-text">“{t.text}”</blockquote>
              <figcaption className="r-author">
                <span className="r-avatar">{t.name[0]}</span>
                <span>
                  <span className="r-name">{t.name}</span>
                  <br />
                  <span className="r-area">{t.area}</span>
                </span>
              </figcaption>
            </figure>
          ))}
        </div>
      </div>
    </section>
  );
}

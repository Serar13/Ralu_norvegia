import { contact } from '../content.js';

export default function CTA() {
  return (
    <section className="cta">
      <div className="container">
        <div className="cta-card">
          <h2>Klar for et skinnende rent hjem?</h2>
          <p>
            Book fast vaskehjelp, engangsvask eller flyttevask i dag. Uforpliktende
            tilbud og 100 % fornøydgaranti.
          </p>
          <div className="cta-actions">
            <a className="btn btn-white btn-lg" href="#kontakt">
              Få gratis pristilbud
            </a>
            <a className="btn btn-outline-white btn-lg" href={contact.phoneHref}>
              📞 {contact.phone}
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}

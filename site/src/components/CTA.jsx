import { Apple, Play } from './Icons.jsx';

export default function CTA() {
  return (
    <section className="cta" id="download">
      <div className="container">
        <div className="cta-card">
          <h2>Klar for et roligere hjem?</h2>
          <p>
            Bli med familiene som gjør husarbeid til en delt, belønnende vane.
            Last ned Ralu Norvegia og start streaken din i dag.
          </p>
          <div className="cta-actions">
            <a className="btn btn-white" href="#">
              <Apple /> Last ned for iOS
            </a>
            <a className="btn btn-outline-white" href="#">
              <Play /> Hent på Google Play
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}

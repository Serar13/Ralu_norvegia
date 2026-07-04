import Illustration from './Illustration.jsx';
import { Sparkle, Check, ArrowRight } from './Icons.jsx';
import { company, contact } from '../content.js';

export default function Hero() {
  return (
    <section className="hero" id="top">
      <div className="container hero-grid">
        <div className="hero-copy">
          <span className="eyebrow">
            <Sparkle /> {company.tagline} · {company.area}
          </span>

          <h1>
            {company.heroTitle.split('—')[0]}
            {company.heroTitle.includes('—') && (
              <>
                — <span className="accent">{company.heroTitle.split('—')[1].trim()}</span>
              </>
            )}
          </h1>

          <p className="lead">{company.heroLead}</p>

          <div className="hero-actions">
            <a className="btn btn-primary btn-lg" href="#kontakt">
              Få gratis pristilbud <ArrowRight width={18} height={18} />
            </a>
            <a className="btn btn-ghost btn-lg" href={contact.phoneHref}>
              📞 Ring oss
            </a>
          </div>

          <div className="hero-proof">
            <div className="avatars" aria-hidden="true">
              <span>R</span>
              <span>N</span>
              <span>K</span>
              <span>+</span>
            </div>
            <div>
              <div className="stars">★★★★★</div>
              <span>Vurdert 4,9 av 1 200+ fornøyde kunder</span>
            </div>
          </div>
        </div>

        <div className="hero-visual">
          <div className="float-card tl">
            <span className="dot" style={{ background: 'linear-gradient(135deg,#72c0b3,#23767b)' }}>
              <Check width={18} height={18} />
            </span>
            <div>
              Fornøydgaranti
              <small>Ikke fornøyd? Vi kommer tilbake</small>
            </div>
          </div>

          <div className="float-card br">
            <span className="dot" style={{ background: 'linear-gradient(135deg,#e18178,#d96a5f)' }}>
              🛡️
            </span>
            <div>
              Fullt forsikret
              <small>Trygt og profesjonelt</small>
            </div>
          </div>

          <div className="photo">
            <Illustration className="photo-illus" />
            <span className="photo-tag">✨ Skinnende rent, hver gang</span>
          </div>
        </div>
      </div>
    </section>
  );
}

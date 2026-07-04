import PhoneMockup from './PhoneMockup.jsx';
import { Sparkle, Flame, Check, Apple, Play } from './Icons.jsx';

export default function Hero() {
  return (
    <section className="hero" id="top">
      <div className="container hero-grid">
        <div className="hero-copy">
          <span className="eyebrow">
            <Sparkle /> Nordisk ro for hjemmet
          </span>

          <h1>
            Et roligere, <span className="accent">renere hjem</span> — én rutine
            om gangen.
          </h1>

          <p className="lead">
            Ralu Norvegia gjør husarbeid til en rolig, belønnende vane. Følg
            ukentlige gjøremål rom for rom, bygg streaks sammen, og la premium
            dyprengjøring gå av seg selv.
          </p>

          <div className="hero-actions">
            <a className="btn btn-primary" href="#download">
              <Apple /> App Store
            </a>
            <a className="btn btn-ghost" href="#download">
              <Play /> Google Play
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
              <span>Elsket av travle familier</span>
            </div>
          </div>
        </div>

        <div className="hero-visual">
          <div className="blob" aria-hidden="true" />

          <div className="float-card streak">
            <span
              className="dot"
              style={{ background: 'linear-gradient(135deg,#e18178,#d96a5f)' }}
            >
              <Flame width={18} height={18} />
            </span>
            <div>
              12 dager på rad
              <small>Streak holdes ved like</small>
            </div>
          </div>

          <div className="float-card done">
            <span
              className="dot"
              style={{ background: 'linear-gradient(135deg,#72c0b3,#23767b)' }}
            >
              <Check width={18} height={18} />
            </span>
            <div>
              Kjøkken ferdig
              <small>+40 poeng i dag</small>
            </div>
          </div>

          <PhoneMockup variant="weekly" />
        </div>
      </div>
    </section>
  );
}

import { Flame, Users, Rooms, Sparkle } from './Icons.jsx';

const FEATURES = [
  {
    icon: Flame,
    grad: 'linear-gradient(135deg,#e18178,#d96a5f)',
    title: 'Streak-oppfølging',
    text: 'Hold flammen i live. Hver fullførte dag bygger streaken din og gir poeng som holder motivasjonen oppe.',
  },
  {
    icon: Users,
    grad: 'linear-gradient(135deg,#add8e6,#72c0b3)',
    title: 'Deling av oppgaver',
    text: 'Fordel gjøremål mellom alle i husstanden. Alle ser hva som er gjort, og hva som gjenstår i sanntid.',
  },
  {
    icon: Rooms,
    grad: 'linear-gradient(135deg,#72c0b3,#23767b)',
    title: 'Egne rom',
    text: 'Baderom, kjøkken, soverom, stue eller inngang — tilpass rom og oppgaver slik at de passer ditt hjem.',
  },
  {
    icon: Sparkle,
    grad: 'linear-gradient(135deg,#8ec9e6,#23767b)',
    title: 'Periodisk dyprengjøring',
    text: 'Ukesmaler (Uke 1–4) roterer automatisk, så sesongvask og dyprengjøring aldri blir glemt.',
  },
];

export default function Features() {
  return (
    <section className="features" id="features">
      <div className="container">
        <div className="section-head">
          <span className="eyebrow">Funksjoner</span>
          <h2>Alt et rolig hjem trenger</h2>
          <p>
            Gjennomtenkte verktøy som gjør husarbeid enklere å dele, lettere å
            fullføre og faktisk givende å holde ved like.
          </p>
        </div>

        <div className="feature-grid">
          {FEATURES.map(({ icon: Icon, grad, title, text }) => (
            <article className="feature-card" key={title}>
              <div className="ficon" style={{ background: grad }}>
                <Icon width={26} height={26} />
              </div>
              <h3>{title}</h3>
              <p>{text}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

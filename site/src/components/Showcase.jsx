import PhoneMockup from './PhoneMockup.jsx';

const SHOTS = [
  {
    variant: 'daily',
    title: 'Daglige gjøremål',
    text: 'Raske rutiner som holder hjemmet friskt hver dag.',
    className: '',
  },
  {
    variant: 'weekly',
    title: 'Ukentlig plan',
    text: 'Roterende ukesmaler, rom for rom.',
    className: 'tall',
  },
  {
    variant: 'streak',
    title: 'Streaks & poeng',
    text: 'Se fremgangen og feir hver milepæl.',
    className: '',
  },
];

export default function Showcase() {
  return (
    <section className="showcase" id="showcase">
      <div className="container">
        <div className="section-head">
          <span className="eyebrow">Appen</span>
          <h2>Laget for å være vakker og enkel</h2>
          <p>
            Et lyst, nordisk grensesnitt med myke former og Kanit-typografi — det
            samme rolige uttrykket i hver skjerm.
          </p>
        </div>

        <div className="showcase-strip">
          {SHOTS.map((s) => (
            <div key={s.title}>
              <PhoneMockup variant={s.variant} className={s.className} />
              <div className="shot-caption">
                <h4>{s.title}</h4>
                <p>{s.text}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

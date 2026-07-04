const STEPS = [
  {
    title: 'Sett opp hjemmet ditt',
    text: 'Legg til rommene dine og velg ukesmalen som passer. Vi starter deg med gjennomtenkte nordiske rutiner.',
  },
  {
    title: 'Del og fullfør',
    text: 'Fordel gjøremål i husstanden. Kryss av oppgaver rom for rom og se poengene vokse.',
  },
  {
    title: 'Bygg streaken',
    text: 'Hold flammen i live dag for dag. Periodisk dyprengjøring dukker opp automatisk til rett tid.',
  },
];

export default function HowItWorks() {
  return (
    <section className="how" id="how">
      <div className="container">
        <div className="section-head">
          <span className="eyebrow">Slik virker det</span>
          <h2>Fra kaos til rutine på tre steg</h2>
          <p>Ingen kompliserte oppsett — bare en rolig rytme hjemmet ditt kan holde.</p>
        </div>

        <div className="steps">
          {STEPS.map((s) => (
            <article className="step" key={s.title}>
              <div className="num" aria-hidden="true" />
              <h3>{s.title}</h3>
              <p>{s.text}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

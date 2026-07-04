import { useState } from 'react';
import { company, contact, services } from '../content.js';

export default function Contact() {
  const [form, setForm] = useState({
    name: '',
    phone: '',
    email: '',
    subject: services[0]?.name ?? 'Generelt spørsmål',
    message: '',
  });

  const update = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  // With no backend, the form composes a pre-filled e-mail.
  function handleSubmit(e) {
    e.preventDefault();
    const mailSubject = `Henvendelse: ${form.subject} — ${form.name}`;
    const body = [
      `Navn: ${form.name}`,
      `Telefon: ${form.phone}`,
      `E-post: ${form.email}`,
      `Henvendelse gjelder: ${form.subject}`,
      '',
      form.message,
    ].join('\n');
    window.location.href = `mailto:${contact.email}?subject=${encodeURIComponent(
      mailSubject,
    )}&body=${encodeURIComponent(body)}`;
  }

  return (
    <section className="contact" id="kontakt">
      <div className="container">
        <div className="section-head">
          <span className="eyebrow">Kontakt</span>
          <h2>Har du spørsmål? Ta kontakt</h2>
          <p>Har du spørsmål om appen, nettbutikken eller de gratis vaskeplanene? Fyll ut skjemaet under så svarer vi deg så fort som mulig.</p>
        </div>

        <div className="contact-card">
          <div className="contact-info">
            <h3>Snakk med oss</h3>
            <p>Vi vil gjerne høre fra deg om du har tilbakemeldinger eller spørsmål.</p>

            <div className="contact-list">
              <a href={contact.phoneHref}>
                <span className="c-ic" aria-hidden="true">📞</span>
                <span>
                  {contact.phone}
                  <small>Ring eller send SMS</small>
                </span>
              </a>
              <a href={`mailto:${contact.email}`}>
                <span className="c-ic" aria-hidden="true">✉️</span>
                <span>
                  {contact.email}
                  <small>Svar innen kort tid</small>
                </span>
              </a>
              <span>
                <span className="c-ic" aria-hidden="true">📍</span>
                <span>
                  {company.area}
                  <small>Tilgjengelig over hele landet</small>
                </span>
              </span>
            </div>

            <div className="contact-socials">
              <a href={contact.instagram} aria-label="Instagram" target="_blank" rel="noreferrer">📸</a>
              <a href={contact.facebook} aria-label="Facebook" target="_blank" rel="noreferrer">👍</a>
            </div>
          </div>

          <form className="contact-form" onSubmit={handleSubmit}>
            <div className="form-row">
              <div className="field">
                <label htmlFor="c-name">Navn</label>
                <input id="c-name" required value={form.name} onChange={update('name')} placeholder="Ola Nordmann" />
              </div>
              <div className="field">
                <label htmlFor="c-phone">Telefon</label>
                <input id="c-phone" type="tel" required value={form.phone} onChange={update('phone')} placeholder="400 00 000" />
              </div>
            </div>

            <div className="field">
              <label htmlFor="c-email">E-post</label>
              <input id="c-email" type="email" required value={form.email} onChange={update('email')} placeholder="deg@epost.no" />
            </div>

            <div className="field">
              <label htmlFor="c-subject">Hva gjelder henvendelsen?</label>
              <select id="c-subject" value={form.subject} onChange={update('subject')}>
                {services.map((s) => (
                  <option key={s.id} value={s.name}>{s.name}</option>
                ))}
                <option value="Generell henvendelse">Generell henvendelse / annet</option>
              </select>
            </div>

            <div className="field">
              <label htmlFor="c-message">Melding</label>
              <textarea
                id="c-message"
                required
                value={form.message}
                onChange={update('message')}
                placeholder="Skriv meldingen din her..."
              />
            </div>

            <button className="btn btn-primary btn-lg" type="submit" style={{ width: '100%' }}>
              Send melding
            </button>
            <p className="form-note">Vi deler aldri opplysningene dine med tredjeparter.</p>
          </form>
        </div>
      </div>
    </section>
  );
}


import { useState } from 'react';
import { company, contact, services } from '../content.js';

export default function Contact() {
  const [form, setForm] = useState({
    name: '',
    phone: '',
    email: '',
    address: '',
    service: services[0]?.name ?? '',
    message: '',
  });

  const update = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  // With no backend, the form composes a pre-filled e-mail to the company.
  // Swap this for a Firestore write or a form service (Formspree, etc.) later.
  function handleSubmit(e) {
    e.preventDefault();
    const subject = `Forespørsel om ${form.service} — ${form.name}`;
    const body = [
      `Navn: ${form.name}`,
      `Telefon: ${form.phone}`,
      `E-post: ${form.email}`,
      `Adresse: ${form.address}`,
      `Tjeneste: ${form.service}`,
      '',
      form.message,
    ].join('\n');
    window.location.href = `mailto:${contact.email}?subject=${encodeURIComponent(
      subject,
    )}&body=${encodeURIComponent(body)}`;
  }

  return (
    <section className="contact" id="kontakt">
      <div className="container">
        <div className="section-head">
          <span className="eyebrow">Kontakt</span>
          <h2>Få et gratis, uforpliktende tilbud</h2>
          <p>Fyll ut skjemaet, så tar vi kontakt innen kort tid med et tilbud tilpasset deg.</p>
        </div>

        <div className="contact-card">
          <div className="contact-info">
            <h3>Snakk med oss</h3>
            <p>Vi svarer gjerne på spørsmål om tjenester, priser og ledige tider.</p>

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
                  <small>Svar innen 24 timer</small>
                </span>
              </a>
              <span>
                <span className="c-ic" aria-hidden="true">📍</span>
                <span>
                  {company.area}
                  <small>Vi kommer til deg</small>
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

            <div className="form-row">
              <div className="field">
                <label htmlFor="c-email">E-post</label>
                <input id="c-email" type="email" value={form.email} onChange={update('email')} placeholder="deg@epost.no" />
              </div>
              <div className="field">
                <label htmlFor="c-address">Adresse</label>
                <input id="c-address" value={form.address} onChange={update('address')} placeholder="Gate 1, 0000 Oslo" />
              </div>
            </div>

            <div className="field">
              <label htmlFor="c-service">Tjeneste</label>
              <select id="c-service" value={form.service} onChange={update('service')}>
                {services.map((s) => (
                  <option key={s.id} value={s.name}>{s.name} — {s.price}</option>
                ))}
              </select>
            </div>

            <div className="field">
              <label htmlFor="c-message">Melding</label>
              <textarea
                id="c-message"
                value={form.message}
                onChange={update('message')}
                placeholder="Fortell oss om boligen din, størrelse, ønsket frekvens…"
              />
            </div>

            <button className="btn btn-primary btn-lg" type="submit" style={{ width: '100%' }}>
              Send forespørsel
            </button>
            <p className="form-note">Vi bruker aldri opplysningene dine til noe annet enn å svare deg.</p>
          </form>
        </div>
      </div>
    </section>
  );
}

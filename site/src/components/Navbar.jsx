import { Sparkle } from './Icons.jsx';
import { company, contact } from '../content.js';

export default function Navbar() {
  return (
    <header className="nav">
      <div className="container nav-inner">
        <a className="brand" href="#top" aria-label={`${company.name} hjem`}>
          <img src="/logo.png" alt={`${company.name} logo`} style={{ width: 40, height: 40, borderRadius: 12, marginRight: 8, objectFit: 'cover' }} />
          <span>
            {company.name}
            <small>{company.tagline}</small>
          </span>
        </a>

        <nav className="nav-links" aria-label="Hovedmeny">
          <a href="#tjenester">Tjenester</a>
          <a href="#priser">Priser</a>
          <a href="#slik">Slik funker det</a>
          <a href="#anmeldelser">Anmeldelser</a>
          <a href="#kontakt">Kontakt</a>
        </nav>

        <div className="nav-cta">
          <a className="nav-phone" href={contact.phoneHref}>
            📞 {contact.phone}
          </a>
          <a className="btn btn-primary" href="#kontakt">
            Bestill vask
          </a>
        </div>
      </div>
    </header>
  );
}

import { Sparkle } from './Icons.jsx';
import { company, contact, services } from '../content.js';

export default function Footer() {
  const year = new Date().getFullYear();
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-grid">
          <div>
            <a className="brand" href="#top">
              <span className="logo">
                <Sparkle width={22} height={22} color="#fff" />
              </span>
              <span>
                {company.name}
                <small>{company.tagline}</small>
              </span>
            </a>
            <p>
              Profesjonelt renhold for hjem og bedrift i {company.area}. Faste,
              forsikrede vaskere og 100 % fornøydgaranti.
            </p>
          </div>

          <div>
            <h5>Tjenester</h5>
            <ul>
              {services.slice(0, 5).map((s) => (
                <li key={s.id}><a href="#tjenester">{s.name}</a></li>
              ))}
            </ul>
          </div>

          <div>
            <h5>Selskap</h5>
            <ul>
              <li><a href="#priser">Priser</a></li>
              <li><a href="#slik">Slik funker det</a></li>
              <li><a href="#anmeldelser">Anmeldelser</a></li>
              <li><a href="#app">Appen</a></li>
            </ul>
          </div>

          <div>
            <h5>Kontakt</h5>
            <ul>
              <li><a href={contact.phoneHref}>{contact.phone}</a></li>
              <li><a href={`mailto:${contact.email}`}>{contact.email}</a></li>
              <li><a href="#kontakt">Få pristilbud</a></li>
            </ul>
          </div>
        </div>

        <div className="footer-bottom">
          <span>© {year} {company.name} · Org.nr {company.orgNr}</span>
          <span>Laget med ro i Norge 🇳🇴</span>
        </div>
      </div>
    </footer>
  );
}

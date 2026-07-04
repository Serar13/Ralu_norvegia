import { Sparkle } from './Icons.jsx';

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
                Ralu Norvegia
                <small>Premium renhold</small>
              </span>
            </a>
            <p>
              En varm, nordisk app for husorganisering og premium renhold.
              Roligere hjem, én rutine om gangen.
            </p>
          </div>

          <div>
            <h5>Produkt</h5>
            <ul>
              <li><a href="#features">Funksjoner</a></li>
              <li><a href="#showcase">Appen</a></li>
              <li><a href="#how">Slik virker det</a></li>
              <li><a href="#download">Last ned</a></li>
            </ul>
          </div>

          <div>
            <h5>Selskap</h5>
            <ul>
              <li><a href="#">Om oss</a></li>
              <li><a href="#">Kontakt</a></li>
              <li><a href="#">Karriere</a></li>
            </ul>
          </div>

          <div>
            <h5>Juridisk</h5>
            <ul>
              <li><a href="#">Personvern</a></li>
              <li><a href="#">Vilkår</a></li>
              <li><a href="#">Cookies</a></li>
            </ul>
          </div>
        </div>

        <div className="footer-bottom">
          <span>© {year} Ralu Norvegia. Alle rettigheter reservert.</span>
          <span>Laget med ro i Norge 🇳🇴</span>
        </div>
      </div>
    </footer>
  );
}

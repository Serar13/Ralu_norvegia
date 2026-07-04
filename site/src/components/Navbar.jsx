import { Sparkle } from './Icons.jsx';

export default function Navbar() {
  return (
    <header className="nav">
      <div className="container nav-inner">
        <a className="brand" href="#top" aria-label="Ralu Norvegia hjem">
          <span className="logo">
            <Sparkle width={22} height={22} color="#fff" />
          </span>
          <span>
            Ralu Norvegia
            <small>Premium renhold</small>
          </span>
        </a>

        <nav className="nav-links" aria-label="Hovedmeny">
          <a href="#features">Funksjoner</a>
          <a href="#showcase">Appen</a>
          <a href="#how">Slik virker det</a>
        </nav>

        <div className="nav-cta">
          <a className="btn btn-ghost" href="#download">
            Logg inn
          </a>
          <a className="btn btn-primary" href="#download">
            Kom i gang
          </a>
        </div>
      </div>
    </header>
  );
}

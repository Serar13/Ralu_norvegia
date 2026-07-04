// =============================================================================
// Ralu Norvegia — single source of truth for all business copy on the site.
// =============================================================================
// EDIT THIS FILE to plug in the real values from vaskmedmeg.no. Everything the
// visitor reads (company info, contact details, services, prices, reviews) is
// here so nobody has to touch the React components.
//
// ⚠️  Values marked `TODO:` are placeholders — replace them with the real data
//     (prices, phone, e-mail, org.nr, reviews) before going live.
// =============================================================================
export const company = {
  name: 'vaskmedmeg',
  tagline: 'veien til et rent hjem',
  heroTitle: 'Gjør husvasken til en lek — med appen og utstyret som funker',
  heroLead:
    'Få kontroll på husvasken med Vaskmedmeg-appen, smarte rutiner og profesjonelle ' +
    'mikrofiberkluter og renholdsutstyr fra nettbutikken vår.',
  area: 'Hele Norge',
  orgNr: '927 671 289 MVA', // Vaskmedmeg AS Org Nr
};

export const contact = {
  phone: '+47 900 00 000',
  phoneHref: 'tel:+4790000000',
  email: 'ralu@vaskmedmeg.no',
  address: 'Norge',
  instagram: 'https://www.instagram.com/vaskmedmeg/',
  facebook: 'https://www.facebook.com/vaskmedmeg/',
};

// Trust signals shown in the strip under the hero.
export const trustPoints = [
  { icon: '📱', label: 'Smart mobilapp' },
  { icon: '🌿', label: 'Renhold uten kjemikalier' },
  { icon: '🛍️', label: 'Profesjonelt utstyr i nettbutikken' },
  { icon: '✨', label: '15 års erfaring fra bransjen' },
];

export const stats = [
  { value: '50 000+', label: 'Følgere på sosiale medier' },
  { value: '4.8★', label: 'App store vurdering' },
  { value: '15 år', label: 'Erfaring i renhold' },
  { value: '100%', label: 'Ren glede' },
];

// Core areas of the website.
export const services = [
  {
    id: 'app',
    icon: '📱',
    name: 'Vaskmedmeg Appen',
    price: 'Prøv gratis i dag',
    text:
      'Organiser husvasken med ukentlige vaskeplaner, streaks, poeng og rom-for-rom ' +
      'instruksjoner. Inviter hele familien til å bidra.',
    points: ['Smarte ukentlige planer', 'Streaks og poeng', 'Familiedeling'],
    featured: true,
  },
  {
    id: 'butikk',
    icon: '🛍️',
    name: 'Nettbutikk',
    price: 'Se alle produkter',
    text:
      'Høykvalitets mikrofiberkluter med ekstrem skure- og absorpsjonsevne, mopper, ' +
      'vindusutstyr og profesjonelle renholdsprodukter.',
    points: ['Kluter for alle overflater', 'Ergonomiske moppesett', 'Rask levering'],
  },
  {
    id: 'planer',
    icon: '📝',
    name: 'Gratis vaskeplaner',
    price: '0 kr — Last ned',
    text:
      'Få tilgang til våre populære vaskeplaner og sjekklister for kjøkken, bad, stue ' +
      'og soverom. Perfekt til å printe ut.',
    points: ['Enkelt å printe ut', 'Klare sjekklister', '5 Startvaner-guide'],
  },
];

// Pricing plans for the App, Resources, and Shop Starter Pack.
export const pricing = {
  note:
    'Appen kan lastes ned gratis på Google Play og App Store. Premium abonnement gir tilgang til avanserte delingsfunksjoner.',
  plans: [
    {
      id: 'free',
      name: 'Gratis vaskeplaner',
      price: '0',
      unit: 'kr / evig',
      tagline: 'For alle',
      includes: [
        'Printbare sjekklister',
        'Ukentlig vaskeplan (PDF)',
        'Gode vasketips på e-post',
        'Ingen binding',
      ],
      cta: 'Last ned gratis',
    },
    {
      id: 'app-premium',
      name: 'Vaskmedmeg App (Premium)',
      price: '49',
      unit: 'kr / mnd',
      tagline: 'Mest populær',
      featured: true,
      includes: [
        'Smarte interaktive sjekklister',
        'Daglige og ukentlige rutiner',
        'Streaks, poeng og statistikk',
        'Familiedeling (hele husstanden)',
        'Ubegrenset antall rom',
      ],
      cta: 'Last ned appen',
    },
    {
      id: 'starter-pack',
      name: 'Nettbutikk Startpakke',
      price: '899',
      unit: 'kr / engang',
      tagline: 'Fysiske produkter',
      includes: [
        'Boken «Vask med meg» av Raluca',
        'Pakke med premium mikrofiberkluter',
        'Ergonomisk gulvmopp og stativ',
        'Vindusskrape og nal',
        'Gratis frakt inkludert',
      ],
      cta: 'Gå til nettbutikk',
    },
  ],
};

export const steps = [
  {
    icon: '📱',
    title: 'Last ned appen',
    text: 'Finn Vaskmedmeg i App Store eller Google Play og sett opp profilene til din husstand.',
  },
  {
    icon: '🧹',
    title: 'Velg riktig utstyr',
    text: 'Bruk våre profesjonelle mikrofiberkluter og moppesett for et raskere og renere resultat uten kjemikalier.',
  },
  {
    icon: '✨',
    title: 'Nyt et rent hjem',
    text: 'Følg rutinene i appen trinn for trinn, hold streaks i gang, og få full kontroll over husarbeidet.',
  },
];

export const testimonials = [
  {
    name: 'Julie S.',
    area: 'Oslo',
    rating: 5,
    text:
      'Helt fantastiske mikrofiberkluter! Sammen med appen har husvasken endelig blitt ' +
      'en lek som hele familien bidrar til hver uke.',
  },
  {
    name: 'Andreas K.',
    area: 'Bergen',
    rating: 5,
    text:
      'Boken «Vask med meg» ga meg så mange gode tips, og appen gjør det superenkelt ' +
      'å holde oversikten over de daglige rutinene.',
  },
  {
    name: 'Lene M.',
    area: 'Trondheim',
    rating: 5,
    text:
      'Kluten gjør rent kun ved bruk av vann, og barna elsker appen! De samler poeng ' +
      'og prøver å slå streaken min hver dag.',
  },
];

// The mobile app showcase section.
export const app = {
  title: 'Vaskmedmeg appen',
  lead:
    'Gjør husvasken til en lek og en god vane. Med appen får du fulle vaskeplaner ' +
    'rom for rom, poeng, streaks og full oversikt over hvem som gjør hva.',
  points: [
    'Smarte ukentlige planer og daglige rutiner',
    'Streaks og poeng som motiverer hele familien',
    'Skreddersydde rom, oppgaver og instruksjoner',
  ],
};

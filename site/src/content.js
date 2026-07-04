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
  name: 'Ralu Norvegia', // TODO: confirm public brand name (e.g. "Vask med meg")
  tagline: 'Premium renhold',
  // Short value proposition shown in the hero.
  heroTitle: 'Et skinnende rent hjem — helt uten stress',
  heroLead:
    'Profesjonell vaskehjelp for hjem og bedrift i Oslo og omegn. Faste, ' +
    'håndplukkede vaskere, miljøvennlige produkter og 100 % fornøydgaranti.',
  area: 'Oslo og omegn', // TODO: confirm service area
  orgNr: '000 000 000 MVA', // TODO: real organisasjonsnummer
};

export const contact = {
  phone: '+47 400 00 000', // TODO: real phone number
  phoneHref: 'tel:+4740000000', // TODO: keep in sync with phone
  email: 'post@ralunorvegia.no', // TODO: real e-mail
  address: 'Oslo, Norge', // TODO: real address if any
  instagram: 'https://instagram.com/', // TODO: real profile
  facebook: 'https://facebook.com/', // TODO: real profile
};

// Trust signals shown in the strip under the hero.
export const trustPoints = [
  { icon: '🛡️', label: 'Fullt forsikret' },
  { icon: '✅', label: '100 % fornøydgaranti' },
  { icon: '🌿', label: 'Miljøvennlige produkter' },
  { icon: '👥', label: 'Faste, håndplukkede vaskere' },
];

export const stats = [
  { value: '1 200+', label: 'Fornøyde kunder' }, // TODO: real numbers
  { value: '4,9★', label: 'Snittvurdering' },
  { value: '8 år', label: 'Erfaring' },
  { value: '100 %', label: 'Fornøydgaranti' },
];

// -----------------------------------------------------------------------------
// Services — the core of the site. `price` is a short "from" indicator.
// -----------------------------------------------------------------------------
export const services = [
  {
    id: 'fast',
    icon: '🏠',
    name: 'Fast vaskehjelp',
    price: 'fra 549 kr/time',
    text:
      'Jevnlig renhold av hjemmet ditt — ukentlig eller annenhver uke. Du får ' +
      'den samme vaskeren hver gang, som blir kjent med hjemmet og ønskene dine.',
    points: ['Fast vasker hver gang', 'Fleksibel frekvens', 'Enkel av- og påmelding'],
    featured: true,
  },
  {
    id: 'engang',
    icon: '✨',
    name: 'Engangsvask',
    price: 'fra 649 kr/time',
    text:
      'En grundig vask når du trenger det — før gjester, etter fest eller bare ' +
      'for en frisk start. Ingen binding.',
    points: ['Grundig rengjøring', 'Uten binding', 'Rask booking'],
  },
  {
    id: 'flytte',
    icon: '📦',
    name: 'Flyttevask',
    price: 'fra 2 990 kr',
    text:
      'Komplett flyttevask med garanti for godkjent overtakelse. Vi tar hånd om ' +
      'alt fra ovn og vifte til lister og vinduer.',
    points: ['Overtakelsesgaranti', 'Fast pris etter areal', 'Godkjent standard'],
  },
  {
    id: 'hoved',
    icon: '🧽',
    name: 'Hovedrengjøring',
    price: 'fra 899 kr/time',
    text:
      'Dyprengjøring av hele boligen — perfekt til vår og høst. Vi tar de ' +
      'stedene hverdagsvasken ikke rekker.',
    points: ['Fra topp til gulv', 'Sesongvask', 'Skreddersydd omfang'],
  },
  {
    id: 'kontor',
    icon: '🏢',
    name: 'Kontor & næring',
    price: 'etter avtale',
    text:
      'Renhold for kontorer, butikker og næringslokaler. Rene, representative ' +
      'lokaler tilpasset åpningstidene deres.',
    points: ['Fleksible tider', 'Fast kontaktperson', 'Faktura til bedrift'],
  },
  {
    id: 'vindu',
    icon: '🪟',
    name: 'Vindusvask',
    price: 'fra 690 kr',
    text:
      'Skinnende rene vinduer inn- og utvendig. Kan bestilles alene eller som ' +
      'tillegg til annen vask.',
    points: ['Inn- og utvendig', 'Strimefritt resultat', 'Tillegg eller alene'],
  },
];

// -----------------------------------------------------------------------------
// Pricing packages. `price` + `unit` render as the big number; `featured`
// highlights the recommended plan.
// -----------------------------------------------------------------------------
export const pricing = {
  note:
    'Alle priser er veiledende og inkl. mva. Endelig pris avhenger av boligens ' +
    'størrelse, tilstand og frekvens. Kontakt oss for et uforpliktende tilbud.',
  plans: [
    {
      id: 'annenhver',
      name: 'Annenhver uke',
      price: '549',
      unit: 'kr / time',
      tagline: 'Mest populært',
      featured: true,
      includes: [
        'Fast vasker hver gang',
        'Kjøkken, bad, stue og soverom',
        'Støvsuging og vask av gulv',
        'Miljøvennlige produkter',
        '100 % fornøydgaranti',
      ],
      cta: 'Bestill fast vask',
    },
    {
      id: 'ukentlig',
      name: 'Ukentlig',
      price: '499',
      unit: 'kr / time',
      tagline: 'Best pris per time',
      includes: [
        'Alt i «Annenhver uke»',
        'Lavere timepris',
        'Alltid et rent hjem',
        'Prioritert booking',
        'Enkel pausemulighet',
      ],
      cta: 'Bestill ukentlig',
    },
    {
      id: 'engangs',
      name: 'Engangs & flytting',
      price: '649',
      unit: 'kr / time',
      tagline: 'Uten binding',
      includes: [
        'Engangsvask eller flyttevask',
        'Grundig dyprengjøring',
        'Overtakelsesgaranti ved flytting',
        'Fast pris etter befaring',
        'Ingen binding',
      ],
      cta: 'Få pristilbud',
    },
  ],
};

export const steps = [
  {
    icon: '📝',
    title: 'Bestill enkelt',
    text: 'Fortell oss hva du trenger via skjemaet eller en telefon. Du får raskt et uforpliktende tilbud.',
  },
  {
    icon: '🧹',
    title: 'Vi vasker',
    text: 'Din faste, forsikrede vasker kommer til avtalt tid og gjør hjemmet ditt skinnende rent.',
  },
  {
    icon: '😊',
    title: 'Du slapper av',
    text: 'Nyt et rent hjem. Ikke fornøyd? Vi kommer tilbake og retter opp — helt gratis.',
  },
];

// TODO: replace with real reviews (name + area + text + rating 1–5).
export const testimonials = [
  {
    name: 'Ingrid H.',
    area: 'Oslo',
    rating: 5,
    text:
      'Endelig en vaskehjelp jeg kan stole på! Samme hyggelige vasker hver gang, ' +
      'og hjemmet skinner alltid når jeg kommer hjem.',
  },
  {
    name: 'Martin & Sofie',
    area: 'Bærum',
    rating: 5,
    text:
      'Bestilte flyttevask og fikk godkjent overtakelse uten en eneste anmerkning. ' +
      'Profesjonelt fra start til slutt.',
  },
  {
    name: 'Anette L.',
    area: 'Lørenskog',
    rating: 5,
    text:
      'Super service og miljøvennlige produkter. Elsker at jeg kan følge med på ' +
      'vasken i appen deres. Anbefales på det sterkeste!',
  },
];

// The mobile app is a differentiator, not the whole story — kept as one section.
export const app = {
  title: 'Følg med i appen',
  lead:
    'Som kunde får du tilgang til Ralu Norvegia-appen: se planlagte vask, hold ' +
    'oversikt over hva som er gjort, og hold streaken i gang med dine egne ' +
    'daglige rutiner mellom besøkene.',
  points: [
    'Ukentlig plan rom for rom',
    'Streaks og poeng for daglige rutiner',
    'Egne rom og oppgaver',
  ],
};

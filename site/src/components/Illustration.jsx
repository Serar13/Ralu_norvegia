// An elegant, self-contained cleaning-scene illustration used in the hero
// "photo" panel. Vector art keeps the page fast and lets the team drop in a
// real photograph later (see public/images/README.md).

export default function Illustration(props) {
  return (
    <svg viewBox="0 0 320 360" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      {/* sparkles */}
      <g fill="#ffffff" opacity="0.9">
        <path d="M60 60c2 6 5 9 11 11-6 2-9 5-11 11-2-6-5-9-11-11 6-2 9-5 11-11Z" />
        <path d="M250 40c1.4 4.5 3.6 6.6 8 8-4.4 1.4-6.6 3.5-8 8-1.4-4.5-3.6-6.6-8-8 4.4-1.4 6.6-3.5 8-8Z" />
        <path d="M280 150c1.1 3.4 2.8 5 6 6-3.2 1.1-4.9 2.6-6 6-1.1-3.4-2.8-5-6-6 3.2-1 4.9-2.6 6-6Z" opacity="0.7" />
      </g>

      {/* spray bottle */}
      <g>
        <rect x="118" y="150" width="84" height="120" rx="18" fill="#ffffff" />
        <rect x="118" y="150" width="84" height="120" rx="18" fill="#23767b" opacity="0.08" />
        <rect x="132" y="182" width="56" height="60" rx="10" fill="#72c0b3" opacity="0.55" />
        <rect x="140" y="120" width="30" height="34" rx="6" fill="#ffffff" />
        <path d="M170 126h34a10 10 0 0 1 10 10v6a8 8 0 0 1-8 8h-36v-24Z" fill="#e18178" />
        <path d="M204 132h20" stroke="#ffffff" strokeWidth="5" strokeLinecap="round" />
        <path d="M170 112h6a8 8 0 0 1 8 8v6h-14v-14Z" fill="#23767b" />
        {/* spray dots */}
        <g fill="#ffffff">
          <circle cx="236" cy="120" r="3.4" />
          <circle cx="250" cy="132" r="2.6" />
          <circle cx="248" cy="108" r="2.6" />
          <circle cx="262" cy="122" r="2" />
        </g>
      </g>

      {/* bubbles */}
      <g fill="#ffffff" opacity="0.85">
        <circle cx="96" cy="250" r="16" />
        <circle cx="72" cy="278" r="10" />
        <circle cx="228" cy="262" r="13" />
        <circle cx="248" cy="288" r="8" />
      </g>
      <g fill="#23767b" opacity="0.14">
        <circle cx="96" cy="250" r="16" />
        <circle cx="228" cy="262" r="13" />
      </g>
    </svg>
  );
}

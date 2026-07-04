// Inline stroke icons for the admin UI (inherit currentColor).
const base = {
  width: 20,
  height: 20,
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 1.9,
  strokeLinecap: 'round',
  strokeLinejoin: 'round',
};

export const Grid = (p) => (
  <svg {...base} {...p}>
    <rect x="3" y="3" width="7" height="7" rx="1.6" />
    <rect x="14" y="3" width="7" height="7" rx="1.6" />
    <rect x="14" y="14" width="7" height="7" rx="1.6" />
    <rect x="3" y="14" width="7" height="7" rx="1.6" />
  </svg>
);

export const Users = (p) => (
  <svg {...base} {...p}>
    <circle cx="9" cy="8" r="3.2" />
    <path d="M3.5 19a5.5 5.5 0 0 1 11 0" />
    <path d="M16 6.2a3 3 0 0 1 0 5.6M17 13.5a5.5 5.5 0 0 1 3.5 5.1" />
  </svg>
);

export const Calendar = (p) => (
  <svg {...base} {...p}>
    <rect x="3" y="5" width="18" height="16" rx="3" />
    <path d="M3 9h18M8 3v4M16 3v4" />
  </svg>
);

export const Home = (p) => (
  <svg {...base} {...p}>
    <path d="M3 10.5 12 4l9 6.5M5 9.5V20h14V9.5M10 20v-5h4v5" />
  </svg>
);

export const Flame = (p) => (
  <svg {...base} {...p}>
    <path d="M12 3c1 3 4 4.5 4 8a4 4 0 0 1-8 0c0-1.2.4-2 1-2.7C8.5 9 9 5.5 12 3Z" />
  </svg>
);

export const Sparkle = (p) => (
  <svg {...base} {...p}>
    <path d="M12 7c.7 2.6 2.4 4.3 5 5-2.6.7-4.3 2.4-5 5-.7-2.6-2.4-4.3-5-5 2.6-.7 4.3-2.4 5-5Z" />
  </svg>
);

export const Plus = (p) => (
  <svg {...base} {...p}>
    <path d="M12 5v14M5 12h14" />
  </svg>
);

export const Trash = (p) => (
  <svg {...base} {...p}>
    <path d="M4 7h16M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2M6 7l1 13a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1l1-13" />
  </svg>
);

export const Edit = (p) => (
  <svg {...base} {...p}>
    <path d="M12 20h9" />
    <path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z" />
  </svg>
);

export const Search = (p) => (
  <svg {...base} {...p}>
    <circle cx="11" cy="11" r="7" />
    <path d="m20 20-3-3" />
  </svg>
);

export const Logout = (p) => (
  <svg {...base} {...p}>
    <path d="M15 12H3M8 7l-5 5 5 5M9 4h8a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H9" />
  </svg>
);

export const Check = (p) => (
  <svg {...base} strokeWidth={2.6} {...p}>
    <path d="M20 6 9 17l-5-5" />
  </svg>
);

export const Save = (p) => (
  <svg {...base} {...p}>
    <path d="M5 3h11l3 3v13a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2Z" />
    <path d="M8 3v5h7M8 21v-6h8v6" />
  </svg>
);

export const Refresh = (p) => (
  <svg {...base} {...p}>
    <path d="M21 12a9 9 0 1 1-3-6.7L21 8M21 3v5h-5" />
  </svg>
);

// Lightweight inline SVG icons (stroke-based, inherit currentColor).
// Keeping them inline keeps the bundle self-contained with no icon dependency.

const base = {
  width: 24,
  height: 24,
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 1.9,
  strokeLinecap: 'round',
  strokeLinejoin: 'round',
};

export const Flame = (p) => (
  <svg {...base} {...p}>
    <path d="M12 3c1 3 4 4.5 4 8a4 4 0 0 1-8 0c0-1.2.4-2 1-2.7C8.5 9 9 5.5 12 3Z" />
    <path d="M12 21a4 4 0 0 0 4-4c0-2-2-3-4-6-2 3-4 4-4 6a4 4 0 0 0 4 4Z" opacity=".55" />
  </svg>
);

export const Users = (p) => (
  <svg {...base} {...p}>
    <circle cx="9" cy="8" r="3.2" />
    <path d="M3.5 19a5.5 5.5 0 0 1 11 0" />
    <path d="M16 6.2a3 3 0 0 1 0 5.6" />
    <path d="M17 13.5a5.5 5.5 0 0 1 3.5 5.1" />
  </svg>
);

export const Rooms = (p) => (
  <svg {...base} {...p}>
    <path d="M3 10.5 12 4l9 6.5" />
    <path d="M5 9.5V20h14V9.5" />
    <path d="M10 20v-5h4v5" />
  </svg>
);

export const Sparkle = (p) => (
  <svg {...base} {...p}>
    <path d="M12 3v4M12 17v4M5 12H1M23 12h-4" opacity=".5" />
    <path d="M12 7c.7 2.6 2.4 4.3 5 5-2.6.7-4.3 2.4-5 5-.7-2.6-2.4-4.3-5-5 2.6-.7 4.3-2.4 5-5Z" />
  </svg>
);

export const Check = (p) => (
  <svg {...base} strokeWidth={2.6} {...p}>
    <path d="M20 6 9 17l-5-5" />
  </svg>
);

export const Bell = (p) => (
  <svg {...base} {...p}>
    <path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9" />
    <path d="M13.7 21a2 2 0 0 1-3.4 0" />
  </svg>
);

export const Calendar = (p) => (
  <svg {...base} {...p}>
    <rect x="3" y="5" width="18" height="16" rx="3" />
    <path d="M3 9h18M8 3v4M16 3v4" />
  </svg>
);

export const Chart = (p) => (
  <svg {...base} {...p}>
    <path d="M4 20V10M10 20V4M16 20v-7M22 20H2" />
  </svg>
);

export const ArrowRight = (p) => (
  <svg {...base} {...p}>
    <path d="M5 12h14M13 6l6 6-6 6" />
  </svg>
);

export const Apple = (p) => (
  <svg viewBox="0 0 24 24" fill="currentColor" width="20" height="20" {...p}>
    <path d="M16.4 12.9c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.9-3.5.9s-1.8-.8-3-.8c-1.5 0-3 .9-3.8 2.3-1.6 2.8-.4 7 1.2 9.3.8 1.1 1.7 2.4 2.9 2.3 1.2 0 1.6-.7 3-.7s1.8.7 3 .7 2-1 2.8-2.1c.9-1.3 1.2-2.5 1.3-2.6-.1 0-2.5-1-2.5-3.7ZM14.2 6.2c.6-.8 1-1.9.9-3-.9 0-2 .6-2.7 1.4-.6.7-1.1 1.8-.9 2.9 1 .1 2.1-.5 2.7-1.3Z" />
  </svg>
);

export const Play = (p) => (
  <svg viewBox="0 0 24 24" fill="currentColor" width="20" height="20" {...p}>
    <path d="M4 3.5v17c0 .8.9 1.3 1.6.9l14-8.5c.6-.4.6-1.4 0-1.8l-14-8.5C4.9 2.2 4 2.7 4 3.5Z" />
  </svg>
);

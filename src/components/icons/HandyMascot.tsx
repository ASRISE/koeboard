// Koeboard: the onboarding mascot is the app's keycap with a waveform.
// Kept under the upstream component name so merges from Handy stay small.
const HandyMascot = ({ className }: { className?: string }) => (
  <svg
    className={className}
    viewBox="0 0 300 336"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    aria-hidden="true"
  >
    <rect x="10" y="40" width="280" height="270" rx="60" fill="#B9BED6" />
    <rect
      x="34"
      y="20"
      width="232"
      height="252"
      rx="48"
      fill="#FFFFFF"
      stroke="var(--color-mascot-line)"
      strokeWidth="6"
    />
    {[0.3, 0.58, 0.86, 1, 0.72, 0.46, 0.26].map((h, i) => (
      <rect
        key={i}
        x={70 + i * 25}
        y={146 - (h * 130) / 2}
        width="16"
        height={h * 130}
        rx="8"
        fill="#FF5A6E"
      />
    ))}
  </svg>
);

export default HandyMascot;

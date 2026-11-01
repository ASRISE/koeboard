// Koeboard: the key-with-waveform glyph (replaces Handy's hand). Kept under
// the upstream component name so merges from Handy stay small.
const HandyHand = ({
  width,
  height,
}: {
  width?: number | string;
  height?: number | string;
  // The sidebar passes a className for its icons; the glyph ignores it.
  className?: string;
}) => (
  <svg
    width={width || 126}
    height={height || 135}
    viewBox="0 0 64 64"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    <rect
      x="5"
      y="12"
      width="54"
      height="40"
      rx="11"
      className="stroke-text"
      strokeWidth="5"
    />
    {[0.35, 0.7, 1, 0.6, 0.35].map((h, i) => (
      <rect
        key={i}
        x={19.75 + i * 8.5}
        y={32 - (h * 26) / 2}
        width="4.5"
        height={h * 26}
        rx="2.25"
        className="fill-text"
      />
    ))}
  </svg>
);

export default HandyHand;

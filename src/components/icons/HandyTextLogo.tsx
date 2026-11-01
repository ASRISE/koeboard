// Koeboard: the wordmark (key with a waveform + "Koeboard"). Kept under the
// upstream component name so merges from Handy stay small.
// The product name is a brand, not translatable copy.
const APP_NAME = "Koeboard";

const HandyTextLogo = ({
  width,
  height,
  className,
}: {
  width?: number;
  height?: number;
  className?: string;
}) => {
  return (
    <svg
      width={width}
      height={height}
      className={className}
      viewBox="0 0 640 140"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      role="img"
      aria-label="Koeboard"
    >
      <rect
        x="6"
        y="14"
        width="150"
        height="112"
        rx="30"
        className="logo-key"
      />
      {[0.35, 0.7, 1, 0.6, 0.35].map((h, i) => (
        <rect
          key={i}
          x={41 + i * 18}
          y={70 - (h * 70) / 2}
          width="10"
          height={h * 70}
          rx="5"
          className="logo-bar"
        />
      ))}
      <text
        x="182"
        y="104"
        fontSize="96"
        fontWeight="700"
        fontFamily="ui-sans-serif, system-ui, -apple-system, 'Segoe UI', sans-serif"
        letterSpacing="-2"
        className="logo-primary"
      >
        {APP_NAME}
      </text>
    </svg>
  );
};

export default HandyTextLogo;

import React from "react";
import { Easing, interpolate, useCurrentFrame } from "remotion";
import { loadFont } from "@remotion/google-fonts/Lexend";
import { T } from "./tokens";

const { fontFamily } = loadFont();
export const lexend = fontFamily;

// Fade + gentle rise, staggered by `delay` frames.
export const useReveal = (delay: number, duration = 24) => {
  const frame = useCurrentFrame();
  const t = interpolate(frame - delay, [0, duration], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.16, 1, 0.3, 1),
  });
  return {
    opacity: t,
    transform: `translateY(${(1 - t) * 28}px)`,
  };
};

export const Reveal: React.FC<{
  delay: number;
  children: React.ReactNode;
  style?: React.CSSProperties;
}> = ({ delay, children, style }) => {
  const anim = useReveal(delay);
  return <div style={{ ...anim, ...style }}>{children}</div>;
};

// Small-caps overline label ("TODAY'S SALES" treatment).
export const Overline: React.FC<{ children: React.ReactNode; onDark?: boolean }> = ({
  children,
  onDark,
}) => (
  <div
    style={{
      fontFamily: lexend,
      fontSize: 26,
      fontWeight: 600,
      letterSpacing: "0.14em",
      textTransform: "uppercase",
      color: onDark ? "rgba(242,247,244,0.6)" : T.inkMuted,
    }}
  >
    {children}
  </div>
);

export const money = (cents: number) =>
  `KES ${Math.round(cents).toLocaleString("en-KE")}`;

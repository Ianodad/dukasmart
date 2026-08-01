import {
  AbsoluteFill,
  Easing,
  Img,
  Sequence,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { loadFont } from "@remotion/google-fonts/Lexend";

const { fontFamily } = loadFont();

// DESIGN.md tokens (Slate + Emerald Pro).
const T = {
  bg: "#182420",
  bgLift: "#22312B",
  onDark: "#F2F7F4",
  onDarkMuted: "#9AABA2",
  emerald: "#059669",
  emeraldBright: "#0BB77F",
  border: "#31413A",
};

const FPS = 30;
const INTRO = 4 * FPS;
const BEAT = Math.round(3.4 * FPS);
// Typographic card that opens the AI section. Real 860x1864 captures of the
// AI surfaces now exist (see AI_BEATS below), so this card no longer stands
// in for a screenshot — it is a short section intro, the same way Intro opens
// the core beats, immediately followed by ordinary PhoneBeat entries.
const FEATURE = Math.round(4.2 * FPS);
const OUTRO = 5 * FPS;

type Beat = { img: string; kicker?: string; title: string; line: string };

const BEATS: Beat[] = [
  { img: "13-dashboard-live.png", title: "Today at a glance", line: "Sales, cash vs M-PESA, and what needs attention." },
  { img: "04-pos-sell.png", title: "Fast point of sale", line: "Tap a product to sell. Search or scan a barcode." },
  { img: "10-pos-cart.png", title: "A cart that adds up", line: "Live totals, quantity steppers, no overselling." },
  { img: "11-payment.png", title: "Cash or M-PESA", line: "Change is computed the moment cash is entered." },
  { img: "12-sale-success.png", title: "Sale complete", line: "Stock reduces automatically. Every movement recorded." },
  { img: "03-add-product.png", title: "Add products in seconds", line: "Profit per unit previewed as you type." },
  { img: "07-add-stock.png", title: "Restock honestly", line: "Till cash-outs tracked so the drawer reconciles." },
  { img: "14-close-day-live.png", title: "Close the day", line: "Gross, net, expected cash — a ledger, not a guess." },
];

// One beat per real AI-surface capture. Only screens that actually exist —
// no beat for the answered-question or AI-insight surfaces (see "Keeping it
// honest" in remotion/README.md).
const AI_BEATS: Beat[] = [
  { img: "15-dashboard-ai.png", kicker: "AI · optional", title: "The dashboard grows an ask bar", line: "Same shop, same numbers — plus a place to ask about them." },
  { img: "16-ask-suggestions.png", kicker: "AI · optional", title: "Ask your duka", line: "In English au Kiswahili — answered from your own ledger, read-only." },
];

export const PROMO_DURATION_FRAMES =
  INTRO + BEATS.length * BEAT + FEATURE + AI_BEATS.length * BEAT + OUTRO;

const ease = Easing.bezier(0.16, 1, 0.3, 1);

const Intro: React.FC = () => {
  const frame = useCurrentFrame();
  const title = interpolate(frame, [0, 20], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease });
  const tag = interpolate(frame, [14, 38], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease });
  const sweep = interpolate(frame, [20, 50], [0, 420], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease });
  const out = interpolate(frame, [INTRO - 12, INTRO], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", opacity: out }}>
      <div style={{ textAlign: "center" }}>
        <div style={{ fontSize: 128, fontWeight: 700, color: T.onDark, opacity: title, transform: `translateY(${(1 - title) * 40}px)` }}>
          Duka<span style={{ color: T.emeraldBright }}>Smart</span>
        </div>
        <div style={{ height: 6, width: sweep, background: T.emerald, borderRadius: 3, margin: "28px auto 0" }} />
        <div style={{ fontSize: 44, marginTop: 36, color: T.onDarkMuted, opacity: tag, transform: `translateY(${(1 - tag) * 24}px)` }}>
          Know your stock. Grow your business.
        </div>
      </div>
    </AbsoluteFill>
  );
};

const PhoneBeat: React.FC<{ beat: Beat; index: number }> = ({ beat, index }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const enter = spring({ frame, fps, config: { damping: 200, stiffness: 90 } });
  const exit = interpolate(frame, [BEAT - 10, BEAT], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  // Slow pan down the tall screenshot inside the phone frame. The scaled
  // image is ~888px tall in an 840px window, so -48 is the deepest safe pan.
  const pan = interpolate(frame, [10, BEAT], [0, -48], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.linear,
  });

  const phoneW = 430;
  const phoneH = 860;

  return (
    <AbsoluteFill style={{ flexDirection: "row", alignItems: "center", opacity: exit }}>
      <div style={{ flex: 1, paddingLeft: 140, maxWidth: 900 }}>
        <div style={{ fontSize: 30, fontWeight: 600, letterSpacing: 6, color: T.emeraldBright, opacity: enter, textTransform: "uppercase" }}>
          {beat.kicker ?? String(index + 1).padStart(2, "0")}
        </div>
        <div
          style={{
            fontSize: 76,
            fontWeight: 700,
            color: T.onDark,
            marginTop: 18,
            lineHeight: 1.05,
            opacity: enter,
            transform: `translateY(${(1 - enter) * 50}px)`,
          }}
        >
          {beat.title}
        </div>
        <div
          style={{
            fontSize: 40,
            color: T.onDarkMuted,
            marginTop: 26,
            lineHeight: 1.4,
            opacity: interpolate(enter, [0, 1], [0, 1]),
            transform: `translateY(${(1 - enter) * 70}px)`,
          }}
        >
          {beat.line}
        </div>
      </div>
      <div style={{ width: 760, display: "flex", justifyContent: "center" }}>
        <div
          style={{
            width: phoneW,
            height: phoneH,
            borderRadius: 44,
            border: `10px solid ${T.border}`,
            background: T.bgLift,
            overflow: "hidden",
            transform: `translateY(${(1 - enter) * 240}px) scale(${0.94 + enter * 0.06})`,
            boxShadow: "0 40px 90px rgba(0,0,0,0.45)",
          }}
        >
          <Img
            src={staticFile(`screens/${beat.img}`)}
            style={{ width: phoneW - 20, transform: `translateY(${pan}px)` }}
          />
        </div>
      </div>
    </AbsoluteFill>
  );
};

const AiCard: React.FC = () => {
  const frame = useCurrentFrame();
  const kicker = interpolate(frame, [0, 18], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease });
  const title = interpolate(frame, [10, 32], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease });
  const line = interpolate(frame, [22, 46], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease });
  const note = interpolate(frame, [40, 64], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease });
  const rule = interpolate(frame, [16, 44], [0, 300], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease });
  const out = interpolate(frame, [FEATURE - 12, FEATURE], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  return (
    <AbsoluteFill style={{ justifyContent: "center", paddingLeft: 140, paddingRight: 140, opacity: out }}>
      <div style={{ fontSize: 30, fontWeight: 600, letterSpacing: 6, color: T.emeraldBright, textTransform: "uppercase", opacity: kicker }}>
        The AI layer
      </div>
      <div style={{ height: 6, width: rule, background: T.emerald, borderRadius: 3, marginTop: 24 }} />
      <div
        style={{
          fontSize: 96,
          fontWeight: 700,
          color: T.onDark,
          marginTop: 34,
          lineHeight: 1.05,
          opacity: title,
          transform: `translateY(${(1 - title) * 44}px)`,
        }}
      >
        Ask your duka.
      </div>
      <div
        style={{
          fontSize: 44,
          color: T.onDarkMuted,
          marginTop: 30,
          lineHeight: 1.4,
          maxWidth: 1300,
          opacity: line,
          transform: `translateY(${(1 - line) * 40}px)`,
        }}
      >
        Plain-language questions about your own numbers — in English or Swahili.
        Plus an AI read on the daily report.
      </div>
      <div
        style={{
          fontSize: 32,
          color: T.onDarkMuted,
          marginTop: 44,
          opacity: note * 0.75,
        }}
      >
        Optional and read-only. No key, no AI, no network — the app is unchanged.
      </div>
    </AbsoluteFill>
  );
};

const Outro: React.FC = () => {
  const frame = useCurrentFrame();
  const a = interpolate(frame, [0, 22], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease });
  const b = interpolate(frame, [12, 36], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease });

  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center" }}>
      <div style={{ textAlign: "center" }}>
        <div style={{ fontSize: 92, fontWeight: 700, color: T.onDark, opacity: a, transform: `translateY(${(1 - a) * 30}px)` }}>
          Duka<span style={{ color: T.emeraldBright }}>Smart</span>
        </div>
        <div style={{ fontSize: 40, marginTop: 30, color: T.onDarkMuted, opacity: b }}>
          Flutter · offline-first · AI-optional · open source (MIT)
        </div>
        <div
          style={{
            fontSize: 42,
            marginTop: 40,
            color: T.onDark,
            background: T.emerald,
            padding: "18px 44px",
            borderRadius: 999,
            display: "inline-block",
            opacity: b,
            fontWeight: 600,
          }}
        >
          github.com/Ianodad/dukasmart
        </div>
      </div>
    </AbsoluteFill>
  );
};

export const DukaPromo: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: T.bg, fontFamily }}>
      <Sequence durationInFrames={INTRO}>
        <Intro />
      </Sequence>
      {BEATS.map((beat, i) => (
        <Sequence key={beat.img} from={INTRO + i * BEAT} durationInFrames={BEAT}>
          <PhoneBeat beat={beat} index={i} />
        </Sequence>
      ))}
      <Sequence from={INTRO + BEATS.length * BEAT} durationInFrames={FEATURE}>
        <AiCard />
      </Sequence>
      {AI_BEATS.map((beat, i) => (
        <Sequence
          key={beat.img}
          from={INTRO + BEATS.length * BEAT + FEATURE + i * BEAT}
          durationInFrames={BEAT}
        >
          <PhoneBeat beat={beat} index={BEATS.length + i} />
        </Sequence>
      ))}
      <Sequence
        from={INTRO + BEATS.length * BEAT + FEATURE + AI_BEATS.length * BEAT}
        durationInFrames={OUTRO}
      >
        <Outro />
      </Sequence>
    </AbsoluteFill>
  );
};

import React from "react";
import { AbsoluteFill, Easing, interpolate, useCurrentFrame } from "remotion";
import { T, cardShadow } from "./tokens";
import { Overline, Reveal, lexend, money } from "./ui";

// ---------- shared chrome ----------

// Echo of the app's dark slate header band: left-aligned title, never centered.
const HeaderBand: React.FC<{ title: string; index: number }> = ({ title, index }) => (
  <Reveal delay={0}>
    <div
      style={{
        backgroundColor: T.surfaceDark,
        height: 128,
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        padding: "0 96px",
      }}
    >
      <div style={{ fontFamily: lexend, fontSize: 46, fontWeight: 600, color: T.onDark }}>
        {title}
      </div>
      <div
        style={{
          fontFamily: lexend,
          fontSize: 26,
          fontWeight: 500,
          color: "rgba(242,247,244,0.55)",
          fontVariantNumeric: "tabular-nums",
        }}
      >
        DukaSmart · {index}/9
      </div>
    </div>
  </Reveal>
);

const LightSlide: React.FC<{ title: string; index: number; children: React.ReactNode }> = ({
  title,
  index,
  children,
}) => (
  <AbsoluteFill style={{ backgroundColor: T.bg }}>
    <HeaderBand title={title} index={index} />
    <div style={{ flex: 1, padding: "72px 96px", display: "flex", flexDirection: "column" }}>
      {children}
    </div>
  </AbsoluteFill>
);

const Card: React.FC<{ children: React.ReactNode; style?: React.CSSProperties }> = ({
  children,
  style,
}) => (
  <div
    style={{
      backgroundColor: T.surface,
      border: `1px solid ${T.border}`,
      borderRadius: 14,
      boxShadow: cardShadow,
      padding: 40,
      ...style,
    }}
  >
    {children}
  </div>
);

const Dot: React.FC<{ color: string }> = ({ color }) => (
  <span
    style={{
      display: "inline-block",
      width: 18,
      height: 18,
      borderRadius: 9,
      backgroundColor: color,
      marginRight: 16,
    }}
  />
);

// ---------- 1 · Title ----------

export const S1Title: React.FC = () => (
  <AbsoluteFill
    style={{
      backgroundColor: T.surfaceDark,
      justifyContent: "center",
      padding: "0 160px",
    }}
  >
    <Reveal delay={4}>
      <Overline onDark>DukaSmart · Duka point of sale</Overline>
    </Reveal>
    <Reveal delay={14} style={{ marginTop: 40 }}>
      <div style={{ fontFamily: lexend, fontSize: 128, fontWeight: 700, color: T.onDark, lineHeight: 1.05 }}>
        Know your stock.
      </div>
      <div style={{ fontFamily: lexend, fontSize: 128, fontWeight: 700, color: T.emerald, lineHeight: 1.05 }}>
        Grow your business.
      </div>
    </Reveal>
    <Reveal delay={30} style={{ marginTop: 56 }}>
      <div style={{ fontFamily: lexend, fontSize: 34, fontWeight: 400, color: "rgba(242,247,244,0.75)" }}>
        Inventory, sales and daily close for one Kenyan kiosk — local-first, on the
        owner's own phone.
      </div>
    </Reveal>
  </AbsoluteFill>
);

// ---------- 2 · The problem ----------

export const S2Problem: React.FC = () => (
  <LightSlide title="The problem" index={2}>
    <Reveal delay={8}>
      <div style={{ fontFamily: lexend, fontSize: 76, fontWeight: 700, color: T.ink, lineHeight: 1.1 }}>
        The paper notebook doesn't add up.
      </div>
    </Reveal>
    <div style={{ marginTop: 64, display: "flex", flexDirection: "column", gap: 28 }}>
      {[
        "One owner, one kiosk, one Android phone — used one-handed at the counter.",
        "Bright daylight, a customer waiting. No time to scroll or search.",
        "Cash mixed with M-PESA, stock counted from memory, expenses forgotten.",
      ].map((line, i) => (
        <Reveal key={line} delay={22 + i * 10}>
          <div style={{ fontFamily: lexend, fontSize: 36, fontWeight: 400, color: T.inkSecondary, display: "flex", alignItems: "center" }}>
            <Dot color={T.emerald} />
            {line}
          </div>
        </Reveal>
      ))}
    </div>
    <Reveal delay={58} style={{ marginTop: "auto" }}>
      <div
        style={{
          backgroundColor: T.amberContainer,
          border: `1px solid ${T.amber}22`,
          borderRadius: 14,
          padding: "32px 40px",
          fontFamily: lexend,
          fontSize: 36,
          fontWeight: 600,
          color: T.amber,
          alignSelf: "flex-start",
          display: "inline-block",
        }}
      >
        At day's end: does the drawer actually reconcile?
      </div>
    </Reveal>
  </LightSlide>
);

// ---------- 3 · What it is ----------

export const S3What: React.FC = () => (
  <LightSlide title="What DukaSmart is" index={3}>
    <Reveal delay={8}>
      <div style={{ fontFamily: lexend, fontSize: 60, fontWeight: 700, color: T.ink, lineHeight: 1.15, maxWidth: 1500 }}>
        A serious merchant tool that replaces the notebook — inventory, sales and
        the daily close, fully offline.
      </div>
    </Reveal>
    <div style={{ marginTop: 72, display: "flex", gap: 32 }}>
      {[
        {
          title: "Sell",
          body: "Ring up cash or M-PESA sales in seconds; stock reduces automatically.",
        },
        {
          title: "Stock",
          body: "Add products and deliveries; low-stock items surface before they run out.",
        },
        {
          title: "Close the day",
          body: "Count the drawer, reconcile against recorded sales, read a plain-language summary.",
        },
      ].map((c, i) => (
        <Reveal key={c.title} delay={26 + i * 10} style={{ flex: 1 }}>
          <Card style={{ height: 320 }}>
            <div style={{ fontFamily: lexend, fontSize: 40, fontWeight: 600, color: T.emeraldDeep }}>
              {c.title}
            </div>
            <div style={{ marginTop: 24, fontFamily: lexend, fontSize: 32, fontWeight: 400, color: T.inkSecondary, lineHeight: 1.45 }}>
              {c.body}
            </div>
          </Card>
        </Reveal>
      ))}
    </div>
  </LightSlide>
);

// ---------- 4 · A day at the duka ----------

export const S4Workflow: React.FC = () => (
  <LightSlide title="A day at the duka" index={4}>
    <div style={{ display: "flex", flexDirection: "column", gap: 26, marginTop: 8 }}>
      {[
        ["Morning", "Receive stock — quantities and buy prices logged in seconds."],
        ["All day", "Ring up sales — product tiles, cart, cash or M-PESA payment."],
        ["Automatically", "Stock counts fall with every sale; low items turn amber."],
        ["As they happen", "Expenses recorded the moment money leaves the drawer."],
        ["Evening", "Close the day — count cash, reconcile, read the daily report."],
      ].map(([when, what], i) => (
        <Reveal key={when} delay={10 + i * 11}>
          <div style={{ display: "flex", alignItems: "center", gap: 32 }}>
            <div
              style={{
                width: 300,
                fontFamily: lexend,
                fontSize: 26,
                fontWeight: 600,
                letterSpacing: "0.1em",
                textTransform: "uppercase",
                color: T.inkMuted,
                textAlign: "right",
                flexShrink: 0,
              }}
            >
              {when}
            </div>
            <div
              style={{
                width: 16,
                height: 16,
                borderRadius: 8,
                backgroundColor: i === 4 ? T.emerald : T.surfaceMuted,
                border: `2px solid ${i === 4 ? T.emerald : T.border}`,
                flexShrink: 0,
              }}
            />
            <div style={{ fontFamily: lexend, fontSize: 38, fontWeight: i === 4 ? 600 : 400, color: i === 4 ? T.ink : T.inkSecondary }}>
              {what}
            </div>
          </div>
        </Reveal>
      ))}
    </div>
    <Reveal delay={70} style={{ marginTop: "auto" }}>
      <div style={{ fontFamily: lexend, fontSize: 32, fontWeight: 400, color: T.inkMuted }}>
        Every session is a task. No feeds, no exploration — glanceable numbers, then
        back to the customer.
      </div>
    </Reveal>
  </LightSlide>
);

// ---------- 5 · Money you can trust ----------

export const S5Money: React.FC = () => {
  const frame = useCurrentFrame();
  const total = interpolate(frame, [14, 60], [0, 12450], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.16, 1, 0.3, 1),
  });
  return (
    <LightSlide title="Money you can trust" index={5}>
      <div style={{ display: "flex", gap: 96, alignItems: "flex-start", flex: 1 }}>
        <div>
          <Reveal delay={8}>
            <Overline>Today's sales</Overline>
          </Reveal>
          <div
            style={{
              marginTop: 20,
              fontFamily: lexend,
              fontSize: 150,
              fontWeight: 700,
              color: T.ink,
              fontVariantNumeric: "tabular-nums",
              opacity: frame > 12 ? 1 : 0,
            }}
          >
            {money(total)}
          </div>
          <div style={{ marginTop: 36, display: "flex", gap: 56 }}>
            <Reveal delay={44}>
              <div style={{ fontFamily: lexend, fontSize: 38, fontWeight: 600, color: T.ink, display: "flex", alignItems: "center", fontVariantNumeric: "tabular-nums" }}>
                <Dot color={T.emerald} />
                Cash&nbsp;&nbsp;{money(8200)}
              </div>
            </Reveal>
            <Reveal delay={52}>
              <div style={{ fontFamily: lexend, fontSize: 38, fontWeight: 600, color: T.ink, display: "flex", alignItems: "center", fontVariantNumeric: "tabular-nums" }}>
                <Dot color={T.blue} />
                M-PESA&nbsp;&nbsp;{money(4250)}
              </div>
            </Reveal>
          </div>
          <Reveal delay={66} style={{ marginTop: 48 }}>
            <div
              style={{
                backgroundColor: T.emeraldContainer,
                borderRadius: 14,
                padding: "28px 40px",
                fontFamily: lexend,
                fontSize: 38,
                fontWeight: 600,
                color: T.emeraldDeep,
                display: "inline-block",
              }}
            >
              ✓ Drawer reconciled — difference KES 0
            </div>
          </Reveal>
        </div>
        <Reveal delay={58} style={{ marginTop: 24, maxWidth: 520 }}>
          <Card>
            <div style={{ fontFamily: lexend, fontSize: 30, fontWeight: 600, color: T.ink }}>
              Why the math holds
            </div>
            <div style={{ marginTop: 20, fontFamily: lexend, fontSize: 27, fontWeight: 400, color: T.inkSecondary, lineHeight: 1.55 }}>
              Every shilling is stored as integer cents — no floating-point drift.
              A sale writes its line items, stock changes and movements in one
              transaction. Closing the day computes the figures and stores them,
              so a sale recorded afterwards cannot quietly move a closed day —
              only deliberately re-closing it recomputes the record.
            </div>
          </Card>
        </Reveal>
      </div>
    </LightSlide>
  );
};

// ---------- 6 · Design system ----------

const Swatch: React.FC<{ hex: string; name: string; light?: boolean }> = ({ hex, name, light }) => (
  <div style={{ flex: 1 }}>
    <div
      style={{
        height: 130,
        backgroundColor: hex,
        borderRadius: 14,
        border: `1px solid ${T.border}`,
        display: "flex",
        alignItems: "flex-end",
        padding: 18,
      }}
    >
      <span
        style={{
          fontFamily: lexend,
          fontSize: 24,
          fontWeight: 600,
          color: light ? T.onDark : T.ink,
          fontVariantNumeric: "tabular-nums",
        }}
      >
        {hex}
      </span>
    </div>
    <div style={{ marginTop: 12, fontFamily: lexend, fontSize: 25, fontWeight: 500, color: T.inkSecondary }}>
      {name}
    </div>
  </div>
);

export const S6Design: React.FC = () => (
  <LightSlide title="Slate + Emerald Pro" index={6}>
    <Reveal delay={8}>
      <div style={{ fontFamily: lexend, fontSize: 44, fontWeight: 600, color: T.ink, maxWidth: 1500, lineHeight: 1.3 }}>
        Green-tinted slate carries the UI. Emerald appears only on primary actions,
        success and money-positive signals.
      </div>
    </Reveal>
    <Reveal delay={26} style={{ marginTop: 56 }}>
      <div style={{ display: "flex", gap: 28 }}>
        <Swatch hex={T.bg} name="bg" />
        <Swatch hex={T.surfaceMuted} name="surfaceMuted" />
        <Swatch hex={T.surfaceDark} name="surfaceDark" light />
        <Swatch hex={T.emerald} name="emerald" light />
        <Swatch hex={T.amber} name="amber" light />
        <Swatch hex={T.blue} name="blue · M-PESA" light />
      </div>
    </Reveal>
    <div style={{ marginTop: "auto", display: "flex", gap: 32 }}>
      {[
        "Money is the hierarchy — the biggest thing on any screen is the number the owner came for.",
        "Glanceable under sunlight — AA+ contrast, large Lexend type, readable at arm's length.",
        "Consistency is trust — a POS that looks stable feels financially reliable.",
      ].map((p, i) => (
        <Reveal key={p} delay={44 + i * 9} style={{ flex: 1 }}>
          <div style={{ fontFamily: lexend, fontSize: 29, fontWeight: 400, color: T.inkSecondary, lineHeight: 1.45, borderTop: `3px solid ${T.emerald}`, paddingTop: 20 }}>
            {p}
          </div>
        </Reveal>
      ))}
    </div>
  </LightSlide>
);

// ---------- 7 · Built lean ----------

export const S7Built: React.FC = () => (
  <LightSlide title="Built lean, on purpose" index={7}>
    <div style={{ display: "flex", gap: 40, flex: 1 }}>
      <Reveal delay={10} style={{ flex: 1 }}>
        <Card style={{ height: "100%" }}>
          <div style={{ fontFamily: lexend, fontSize: 36, fontWeight: 600, color: T.emeraldDeep }}>
            Inside
          </div>
          <div style={{ marginTop: 28, display: "flex", flexDirection: "column", gap: 22 }}>
            {[
              "Flutter + Drift (SQLite) — one codebase, local-first data",
              "Integer-cents money math, frozen data layer with DAO invariants",
              "269 tests: money math, close-day math, DAO invariants, the AI gateway, widgets",
              "Rule-based daily insight — deterministic, now the offline fallback",
            ].map((t) => (
              <div key={t} style={{ fontFamily: lexend, fontSize: 31, fontWeight: 400, color: T.inkSecondary, display: "flex", alignItems: "center" }}>
                <Dot color={T.emerald} />
                {t}
              </div>
            ))}
          </div>
        </Card>
      </Reveal>
      <Reveal delay={26} style={{ flex: 1 }}>
        <Card style={{ height: "100%", backgroundColor: T.surfaceMuted }}>
          <div style={{ fontFamily: lexend, fontSize: 36, fontWeight: 600, color: T.inkMuted }}>
            Deliberately out (MVP)
          </div>
          <div style={{ marginTop: 28, display: "flex", flexDirection: "column", gap: 22 }}>
            {[
              "No cloud sync, backend, or accounts — nothing to break offline",
              "No live M-PESA API — payments recorded manually, code optional",
              "No receipt printing, refunds, or split payments",
              "No push notifications, no multi-branch",
            ].map((t) => (
              <div key={t} style={{ fontFamily: lexend, fontSize: 31, fontWeight: 400, color: T.inkMuted, display: "flex", alignItems: "center" }}>
                <Dot color={T.border} />
                {t}
              </div>
            ))}
          </div>
        </Card>
      </Reveal>
    </div>
    <Reveal delay={48} style={{ marginTop: 48 }}>
      <div style={{ fontFamily: lexend, fontSize: 32, fontWeight: 400, color: T.inkMuted }}>
        A small tool the owner can trust beats a big one they can't.
      </div>
    </Reveal>
  </LightSlide>
);

// ---------- 8 · The AI layer ----------

export const S8Ai: React.FC = () => (
  <LightSlide title="The AI layer, done honestly" index={8}>
    <Reveal delay={8}>
      <div style={{ fontFamily: lexend, fontSize: 44, fontWeight: 600, color: T.ink, maxWidth: 1500, lineHeight: 1.3 }}>
        An owner can now ask their shop questions in plain language — without
        changing anything this deck already promised about trust and offline use.
      </div>
    </Reveal>
    <div style={{ marginTop: 56, display: "flex", gap: 40, flex: 1 }}>
      <Reveal delay={24} style={{ flex: 1 }}>
        <Card style={{ height: "100%" }}>
          <div style={{ fontFamily: lexend, fontSize: 36, fontWeight: 600, color: T.emeraldDeep }}>
            What's new
          </div>
          <div style={{ marginTop: 28, display: "flex", flexDirection: "column", gap: 22 }}>
            {[
              "Ask your duka — plain-language questions about the shop's numbers, English or Swahili",
              "An AI insight on the daily report, on top of the deterministic rule-based summary",
            ].map((t) => (
              <div key={t} style={{ fontFamily: lexend, fontSize: 31, fontWeight: 400, color: T.inkSecondary, display: "flex", alignItems: "center" }}>
                <Dot color={T.emerald} />
                {t}
              </div>
            ))}
          </div>
        </Card>
      </Reveal>
      <Reveal delay={38} style={{ flex: 1 }}>
        <Card style={{ height: "100%" }}>
          <div style={{ fontFamily: lexend, fontSize: 36, fontWeight: 600, color: T.emeraldDeep }}>
            What never changes
          </div>
          <div style={{ marginTop: 28, display: "flex", flexDirection: "column", gap: 22 }}>
            {[
              "Enabled at build time by whoever ships the app — no key means no AI surfaces and no network calls",
              "Read-only — never writes to the database; money is computed by the app, and the model is told to quote it verbatim",
            ].map((t) => (
              <div key={t} style={{ fontFamily: lexend, fontSize: 31, fontWeight: 400, color: T.inkSecondary, display: "flex", alignItems: "center" }}>
                <Dot color={T.emerald} />
                {t}
              </div>
            ))}
          </div>
        </Card>
      </Reveal>
    </div>
    <Reveal delay={60} style={{ marginTop: 48 }}>
      <div style={{ fontFamily: lexend, fontSize: 32, fontWeight: 400, color: T.inkMuted }}>
        Off unless deliberately built in. Read-only always.
      </div>
    </Reveal>
  </LightSlide>
);

// ---------- 9 · Close ----------

export const S9Close: React.FC = () => {
  const frame = useCurrentFrame();
  const scale = interpolate(frame, [6, 30], [0.6, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.16, 1, 0.3, 1),
  });
  return (
    <AbsoluteFill
      style={{
        backgroundColor: T.surfaceDark,
        justifyContent: "center",
        alignItems: "center",
      }}
    >
      <div
        style={{
          width: 160,
          height: 160,
          borderRadius: 80,
          backgroundColor: T.emerald,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          transform: `scale(${scale})`,
          opacity: interpolate(frame, [6, 20], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        <span style={{ fontFamily: lexend, fontSize: 84, fontWeight: 700, color: T.onEmerald }}>✓</span>
      </div>
      <Reveal delay={24} style={{ marginTop: 64, textAlign: "center" }}>
        <div style={{ fontFamily: lexend, fontSize: 80, fontWeight: 700, color: T.onDark, lineHeight: 1.15 }}>
          Close every day
          <br />
          knowing your numbers.
        </div>
      </Reveal>
      <Reveal delay={44} style={{ marginTop: 48, textAlign: "center" }}>
        <Overline onDark>DukaSmart — Know your stock. Grow your business.</Overline>
      </Reveal>
    </AbsoluteFill>
  );
};

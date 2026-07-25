# DESIGN.md — DukaSmart visual system ("Slate + Emerald Pro")

Approved by Ian 2026-07-26. Register: product. Theme: light only (bright-daylight
kiosk use). This file is the single source of truth for all UI styling; screens
consume tokens/theme — no local hardcoded colors or ad-hoc text styles.

## Color strategy
Restrained with one committed element: green-tinted slate neutrals carry the UI;
**emerald appears only on primary actions, success, and money-positive signals**
(≤ ~10% of any screen). The **dark slate header band** is the single committed
dark element per screen. Never pure #000/#FFF — every neutral is tinted toward
the brand green.

## Tokens (Flutter `AppTokens`)

### Neutrals (green-tinted slate)
| Token | Hex | Use |
|---|---|---|
| bg | #F7FAF8 | Scaffold background |
| surface | #FCFDFD | Cards, sheets, nav bar |
| surfaceMuted | #EDF1EE | Input fills, tonal buttons, inactive chips |
| surfaceDark | #182420 | App header band, splash — the committed dark slate |
| ink | #101915 | Primary text, big money numbers |
| inkSecondary | #51605A | Secondary text |
| inkMuted | #6F7D77 | Labels, small-caps captions, disabled |
| border | #DFE6E2 | Hairline card/input borders |
| onDark | #F2F7F4 | Text/icons on surfaceDark |

### Brand + semantic
| Token | Hex | Use |
|---|---|---|
| emerald | #059669 | Primary actions, active nav, success, money-positive |
| emeraldPressed | #047857 | Pressed/active state |
| emeraldContainer | #D7F0E5 | Success tints, active indicator pill |
| onEmerald | #F6FBF8 | Text on emerald |
| emeraldDeep | #065F46 | Text on emeraldContainer |
| amber | #B45309 | Low-stock text/icons (AA on light) |
| amberContainer | #FBEED9 | Attention/low-stock tint blocks |
| red | #D92D20 | Errors, out-of-stock |
| redContainer | #FDE8E6 | Error tints |
| blue | #2563EB | M-PESA info ONLY (no M-PESA branding) |
| blueContainer | #E3EBFC | M-PESA chip/tint |

Rule: tint containers always pair with their deep text color (amberContainer +
amber text, etc.), never with ink.

## Typography
Family: **Lexend** (bundled TTF assets, offline — weights 400/500/600/700);
fallback chain: Inter (if Lexend fetch fails) → system sans. Scale (≈1.2 ratio):

| Style | Size/Weight | Use |
|---|---|---|
| moneyDisplay | 36 / 700 | The one big number per screen (today total, sale total, change due) |
| moneyMedium | 28 / 700 | Section money (close-day figures, payment total) |
| moneySmall | 20 / 600 | Row amounts, cart totals |
| headline | 23 / 600 | Screen titles in app bar band |
| title | 19 / 600 | Section headers, dialog titles |
| body | 16 / 400 | Default text |
| bodyStrong | 16 / 600 | Emphasis, button labels |
| caption | 13 / 500 | Meta text, timestamps |
| overline | 12 / 600, +0.8 letterspacing, UPPERCASE, inkMuted | Small-caps labels above money ("TODAY'S SALES") |

Money strings keep `KES 12,450` formatting via frozen `formatCents()`; apply
`FontFeature.tabularFigures()` on money styles.

## Shape & elevation
- Cards: radius 14, surface fill, hairline border (border token) + soft shadow
  `rgba(16,25,21,0.06), blur 12, y 2`. Never nested cards.
- Buttons: pill (StadiumBorder). Primary = FilledButton emerald/onEmerald;
  Secondary = tonal (surfaceMuted fill, ink text); Destructive = red.
  Height 52, full-width for primary screen actions.
- Inputs: filled surfaceMuted, radius 12, no border at rest; 1.5px emerald
  border + surface fill on focus; floating labels.
- Chips/status: pill, tint container + deep text (see color rule).
- Bottom sheets: surface, top radius 20, drag handle.
- App bar: **surfaceDark band**, onDark title LEFT-aligned (never centered),
  headline style; no elevation/shadow.
- Bottom nav: surface bar, hairline top border; active = emerald icon+label with
  emeraldContainer indicator pill; inactive = inkMuted.

## Spacing
Scale 4/8/12/16/24/32. Screen gutter 16; between sections 24; inside cards 16;
list row vertical 12. Vary section rhythm — do not equal-pad everything.

## Motion
180ms standard, easeOutCubic. Press feedback on all primary buttons:
AnimatedScale to 0.97 on tap-down (PrimaryButton widget owns this). Motion only
for state (press, reveal, sheet). No page-load choreography, no bounce/elastic.

## Component vocabulary (lib/core/widgets — restyle in place, same APIs)
- **SummaryCard**: overline label + moneyMedium value; NO icon-gradient decor.
- **MoneyText**: money styles + tabular figures; emerald only when explicitly
  positive-delta, otherwise ink.
- **StockStatusChip**: In Stock = surfaceMuted/inkSecondary; Low = amber pair;
  Out = red pair.
- **PrimaryButton**: emerald pill + press scale + loading spinner state.
- **EmptyState**: icon in surfaceMuted circle, title + one-line hint, optional
  action — teaches the screen, never just "nothing here".
- **SectionHeader**: title style + optional trailing action, 24 top space.
- **PaymentMethodSelector**: segmented pills — Cash (emerald when selected),
  M-PESA (blue pair when selected).

## Screen notes
- **Dashboard**: header band (app name + date, settings). Content directly on bg
  (not carded): overline "TODAY'S SALES" + moneyDisplay total, then cash/M-PESA
  as two dot-chips (emerald dot / blue dot). Attention block = amberContainer,
  FULL border, count + top items, tap → Low stock. Quick actions: 2×2 tonal
  grid, emerald icons. New Sale = full-width primary pill pinned above nav.
- **POS/Sell**: product tiles surface+border, name bodyStrong, price moneySmall,
  small stock caption; out-of-stock tiles dimmed with red chip. Cart bar: dark
  slate strip with onDark total + emerald Proceed button.
- **Payment**: moneyDisplay total centered on bg; method segmented; change due
  in emeraldContainer block with emeraldDeep moneyMedium.
- **Sale success**: the one emerald-committed moment — emerald circle check,
  moneyMedium total, change prominent; actions stacked pills.
- **Close day / Report**: figures in a clean two-column ledger list (label
  inkSecondary / value moneySmall ink), NOT a card grid; cash difference:
  emerald pair when over/zero, red pair when short. Insight in surfaceMuted
  block with quote treatment.
- **Forms** (Add product/stock/expense): single column, floating labels, helper
  text caption/inkMuted; profit-per-unit preview as emerald caption when
  positive, red when negative.

## Bans (absolute)
No side-stripe borders (border-left accents). No gradient text or gradient CTA
fills. No glassmorphism/blur decor. No hero-metric gradient stat cards. No
identical icon+heading+text card grids. No emoji as icons. No centered app bar
titles. No pure #000/#FFF. No local Colors.* / ad-hoc TextStyles in screens —
tokens/theme only.

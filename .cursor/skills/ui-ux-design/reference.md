# UI/UX - user interface / user experience reference (WCAG - Web Content Accessibility Guidelines–oriented)

## Abbreviations

- **WCAG** - Web Content Accessibility Guidelines
- **AA** - WCAG conformance level AA
- **UI** - user interface
- **UX** - user experience
- **AT** - assistive technology
- **RN** - React Native
- **OTP** - one-time password
- **SSO** - single sign-on
- **CSS** - Cascading Style Sheets

Use as a **spot-check** when polishing or reviewing UI—not as legal compliance documentation. Prefer **WCAG - Web Content Accessibility Guidelines 2.2** at **AA - WCAG conformance level AA** for this codebase’s default bar.

## Perceivable

| Topic | Checks (target **AA - WCAG conformance level AA**) |
|--------|-------------------|
| **Text contrast** | Normal text ≥ 4.5:1; large text (≥18pt regular or 14pt bold) ≥ 3:1 vs adjacent background. UI chrome (borders, icons that convey state) often needs 3:1 when they carry meaning. |
| **Non-text contrast** | Focus rings, toggles, graph lines: ≥ 3:1 against adjacent colors when they communicate state or identity. |
| **Resize** | Content usable at ~200% zoom (web); no loss of function from reflow where applicable. |
| **Images** | Informative images have text or accessible names; decorative images hidden from **AT - assistive technology** or empty alt pattern. |

## Operable

| Topic | Checks (target **AA - WCAG conformance level AA**) |
|--------|-------------------|
| **Keyboard** | All interactive content operable without pointer; focus order follows reading order; no keyboard trap (modals: Esc / focus return documented in app patterns). |
| **Focus visible** | Focus indicator visible; **2.4.11** (Focus Not Obscured—Minimum): focused item not fully hidden by sticky headers/modals. |
| **Target size (2.5.8)** | Minimum **24×24 CSS pixels** for targets (**WCAG - Web Content Accessibility Guidelines**); **44×44 pt** remains a good iOS/Android UX - user experience baseline when space allows. |
| **Dragging (2.5.7)** | If action uses dragging, provide single-pointer alternative unless essential. |
| **Motion (2.3.3)** | Animations from interactions can be disabled unless essential; no seizure-inducing flashes. |

## Understandable

| Topic | Checks (target **AA - WCAG conformance level AA**) |
|--------|-------------------|
| **Labels** | Inputs have visible labels; instructions before errors where needed. |
| **Error identification (3.3.1)** | Errors described in text; field association clear. |
| **Labels / instructions (3.3.2)** | Labels or instructions when user input required. |
| **Consistent navigation (3.2.3)** | Repeated nav components in consistent order. |
| **Redundant entry (3.3.7)** | Don’t ask for same info twice in a session when it can be auto-filled or selected—reduces fatigue and errors. |
| **Help placement (3.2.6)** | Human contact / self-help links in consistent predictable places when offered. |

## Robust

| Topic | Checks |
|--------|--------|
| **Parsing / roles** | Valid structure on web; **RN - React Native**: `accessibilityRole`, `accessibilityState`, and names match behavior. |
| **Status messages** | Important dynamic updates (errors, success) exposed to **AT - assistive technology** without stealing focus when inappropriate—use `aria-live` patterns on web; **RN - React Native** accessibility patterns as appropriate. |

## Authentication (3.3.8 **AA - WCAG conformance level AA**)

- Avoid cognitive tests (e.g. “pick all traffic lights”) as the only method.
- Offer alternatives: paste-friendly **OTP - one-time password**, password managers, **SSO - single sign-on** where product allows.

---

**Escape hatch**: If **AA - WCAG conformance level AA** is impossible without redesign, document the gap, propose a fix, and avoid making contrast or focus **worse** than surrounding UI.

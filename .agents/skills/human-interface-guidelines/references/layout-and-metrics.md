# Layout & Spatial Metrics Reference

This document outlines structural measurements, layout hierarchies, and spacing standards derived from Apple's Human Interface Guidelines.

---

## 1. The 8pt Spatial System

All margins, paddings, and dimension constraints should be anchored to increments of 8, with a 4pt micro-increment for compact elements:

| Step | Value | Common Usage |
| :--- | :--- | :--- |
| `2xs` | 2px / 0.125rem | Hairline borders, focus ring offsets |
| `xs` | 4px / 0.25rem | Micro-spacing between icon and badge counter, tight chip padding |
| `sm` | 8px / 0.5rem | Gap between icon and label, compact stack separation |
| `md` | 12px / 0.75rem | Internal button vertical padding, form input inline spacing |
| `lg` | 16px / 1.0rem | Standard screen margin, card padding, default stack gap |
| `xl` | 24px / 1.5rem | Section spacing, container gap, card-to-card margin |
| `2xl`| 32px / 2.0rem | Header margin, modal dialog interior padding |
| `3xl`| 48px / 3.0rem | Hero section margin, prominent visual separation |
| `4xl`| 64px / 4.0rem | Large desktop layout gaps |

---

## 2. Touch Target Ergonomics

Human fingers have a contact patch of approximately 7–10 mm.

```
       ┌────────────────────────┐
       │   44pt x 44pt Target   │
       │     ┌────────────┐     │
       │     │ 20pt Icon  │     │
       │     └────────────┘     │
       │                        │
       └────────────────────────┘
```

- **Minimum Hit Bounds**: 44 × 44 pt (CSS px).
- **Embedded Icons**: When an icon glyph is small (e.g. 18px–24px), use `padding`, negative margins, or an invisible bounding container to preserve the 44px hit test region.
- **Stacked Targets**: Maintain at least an 8pt gap between adjacent touch targets to prevent mis-taps.

---

## 3. Safe Areas & Margins

Applications must always respect hardware display boundaries:
- **Mobile Safe Areas**: Respect `env(safe-area-inset-top)` and `env(safe-area-inset-bottom)` for home indicators and notches/islands.
- **Navigation Bars**: Top navigation bars should sit at 44pt standard height (mobile) or 52pt (desktop), expanding for large titles.
- **Tab Bars / Bottom Nav**: Bottom bars should provide 49pt to 56pt height plus bottom safe-area insets.
- **Margins by Breakpoint**:
  - Compact (Mobile, < 600px): 16px horizontal margins.
  - Regular (Tablet, 600px - 1024px): 24px - 32px horizontal margins.
  - Expanded (Desktop, > 1024px): Max-width content containers (e.g., 960px, 1200px) centered with automatic margins.

---

## 4. Elevation & Surface Hierarchy

Surfaces should reflect logical depth from background to interactive foreground:

1. **Level 0 (Canvas / Base)**: System background (`--bg-primary`).
2. **Level 1 (Grouped Content / Cards)**: Secondary grouped background (`--bg-secondary`) with 1px border or subtle elevation.
3. **Level 2 (Floating Bars / Headers)**: Semi-translucent material with backdrop blur (`backdrop-filter: blur(20px)`).
4. **Level 3 (Overlays / Modals / Sheets)**: High elevation drop shadow, dimming overlay behind (`rgba(0, 0, 0, 0.4)`).

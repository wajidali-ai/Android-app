# Color Systems & Accessibility (a11y)

In human-centric design, color is semantic rather than purely decorative. Colors must automatically adapt to light and dark appearances, adhere to contrast requirements, and never be the sole carrier of information.

---

## 1. Semantic Color Architecture

Avoid hardcoding hex codes directly in components. Structure colors into semantic tiers:

### Semantic Tokens (Light & Dark Mode)

```css
:root {
  /* Surfaces & Backgrounds */
  --color-bg-primary: #FFFFFF;
  --color-bg-secondary: #F2F2F7;
  --color-bg-tertiary: #E5E5EA;
  --color-bg-grouped: #F2F2F7;

  /* Text & Labels */
  --color-label-primary: #000000;
  --color-label-secondary: rgba(60, 60, 67, 0.6);
  --color-label-tertiary: rgba(60, 60, 67, 0.3);
  --color-label-quaternary: rgba(60, 60, 67, 0.18);

  /* Separators & Fills */
  --color-separator: rgba(60, 60, 67, 0.29);
  --color-separator-opaque: #C6C6C8;
  --color-fill-quaternary: rgba(116, 116, 128, 0.08);

  /* System Accents */
  --color-accent: #007AFF;
  --color-accent-hover: #0062CC;
  --color-success: #34C759;
  --color-warning: #FF9500;
  --color-destructive: #FF3B30;
}

@media (prefers-color-scheme: dark) {
  :root {
    /* Surfaces & Backgrounds */
    --color-bg-primary: #000000;
    --color-bg-secondary: #1C1C1E;
    --color-bg-tertiary: #2C2C2E;
    --color-bg-grouped: #1C1C1E;

    /* Text & Labels */
    --color-label-primary: #FFFFFF;
    --color-label-secondary: rgba(235, 235, 245, 0.6);
    --color-label-tertiary: rgba(235, 235, 245, 0.3);
    --color-label-quaternary: rgba(235, 235, 245, 0.18);

    /* Separators & Fills */
    --color-separator: rgba(84, 84, 88, 0.65);
    --color-separator-opaque: #38383A;
    --color-fill-quaternary: rgba(118, 118, 128, 0.24);

    /* System Accents */
    --color-accent: #0A84FF;
    --color-accent-hover: #409CFF;
    --color-success: #30D158;
    --color-warning: #FF9F0A;
    --color-destructive: #FF453A;
  }
}
```

---

## 2. Contrast Requirements (WCAG 2.1 AA)

- **Standard Text**: Contrast ratio must be at least **4.5:1** against the backing surface.
- **Large Text** (≥18pt or ≥14pt bold): Contrast ratio must be at least **3.0:1**.
- **Interface Controls & Icons**: Functional boundaries and active indicators must be at least **3.0:1**.

---

## 3. Typography Hierarchy & Optical Sizing

Use system fonts with optical size support:

```css
font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display",
             "Inter", "Segoe UI", Roboto, sans-serif;
```

| Text Style | Size | Weight | Line Height | Tracking (Letter Spacing) |
| :--- | :--- | :--- | :--- | :--- |
| **Large Title** | 34px (2.125rem) | 700 (Bold) | 41px | 0.37px |
| **Title 1** | 28px (1.75rem) | 700 (Bold) | 34px | 0.36px |
| **Title 2** | 22px (1.375rem) | 600 (Semibold) | 28px | -0.26px |
| **Title 3** | 20px (1.25rem) | 600 (Semibold) | 25px | -0.45px |
| **Headline** | 17px (1.0625rem) | 600 (Semibold) | 22px | -0.43px |
| **Body** | 17px (1.0625rem) | 400 (Regular) | 22px | -0.43px |
| **Callout** | 16px (1.0rem) | 400 (Regular) | 21px | -0.32px |
| **Subheadline** | 15px (0.9375rem) | 400 (Regular) | 20px | -0.24px |
| **Footnote** | 13px (0.8125rem) | 400 (Regular) | 18px | -0.08px |
| **Caption 1** | 12px (0.75rem) | 400 (Regular) | 16px | 0.0px |
| **Caption 2** | 11px (0.6875rem) | 400 (Regular) | 13px | 0.07px |

---

## 4. Accessibility Checklist

- **Screen Readers**: All buttons and icon-only triggers must have accessible labels (`aria-label` or visible text).
- **Focus Rings**: Keyboard focus must display high-visibility focus indicators (`:focus-visible`).
- **Dynamic Sizing**: Use `rem`/`em` units so layouts gracefully respond when users configure larger default font sizes.

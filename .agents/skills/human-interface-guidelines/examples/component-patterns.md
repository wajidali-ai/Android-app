# Component Patterns Reference

Tested UI component patterns adhering to Apple Human Interface Guidelines and modern ergonomic standards.

---

## 1. Ergonomic Button (44pt Hit Target + Spring Active State)

```css
.btn-hig {
  /* Metrics & Touch Target */
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 44px;
  min-width: 44px;
  padding: 10px 20px;
  border-radius: 12px; /* Smooth corner curvature */
  font-family: inherit;
  font-size: 17px;
  font-weight: 600;
  text-decoration: none;
  border: none;
  cursor: pointer;
  user-select: none;
  outline: none;

  /* Colors */
  background-color: var(--color-accent, #007AFF);
  color: #FFFFFF;

  /* Fluid Motion */
  transition: transform 0.18s cubic-bezier(0.2, 0.8, 0.2, 1),
              background-color 0.15s ease,
              box-shadow 0.2s ease;
}

.btn-hig:hover {
  background-color: var(--color-accent-hover, #0062CC);
}

.btn-hig:active {
  transform: scale(0.96); /* Instant tactile compression */
}

.btn-hig:focus-visible {
  box-shadow: 0 0 0 4px rgba(0, 122, 255, 0.35);
}
```

---

## 2. Frosted Glass Header / Floating Navigation Bar

```css
.nav-hig {
  position: sticky;
  top: 0;
  z-index: 100;
  height: 52px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 16px;
  
  /* Translucent Material & Depth */
  background-color: rgba(255, 255, 255, 0.72);
  backdrop-filter: blur(20px) saturate(180%);
  -webkit-backdrop-filter: blur(20px) saturate(180%);
  border-bottom: 0.5px solid var(--color-separator, rgba(60, 60, 67, 0.29));
}

@media (prefers-color-scheme: dark) {
  .nav-hig {
    background-color: rgba(28, 28, 30, 0.75);
    border-bottom: 0.5px solid var(--color-separator, rgba(84, 84, 88, 0.65));
  }
}
```

---

## 3. Segmented Control

```css
.segmented-control {
  display: inline-flex;
  padding: 2px;
  background-color: var(--color-fill-quaternary, rgba(118, 118, 128, 0.12));
  border-radius: 9px;
  min-height: 36px;
}

.segment-item {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 6px 14px;
  font-size: 13px;
  font-weight: 500;
  color: var(--color-label-secondary, #666);
  background: transparent;
  border: none;
  border-radius: 7px;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  min-height: 32px;
}

.segment-item[aria-selected="true"],
.segment-item.active {
  background-color: var(--color-bg-primary, #FFFFFF);
  color: var(--color-label-primary, #000000);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.12), 0 0.5px 1px rgba(0, 0, 0, 0.06);
}
```

---

## 4. Grouped Inset Card

```css
.card-inset-hig {
  background-color: var(--color-bg-secondary, #F2F2F7);
  border-radius: 16px;
  padding: 16px;
  margin: 16px 0;
  border: 1px solid var(--color-separator-opaque, #E5E5EA);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

@media (prefers-color-scheme: dark) {
  .card-inset-hig {
    background-color: var(--color-bg-secondary, #1C1C1E);
    border-color: rgba(255, 255, 255, 0.08);
  }
}
```

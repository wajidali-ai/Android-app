---
name: human-interface-guidelines
description: Apple Human Interface Guidelines (HIG) and human-centric application design system. Use whenever designing, building, styling, or auditing application UI/UX, components, layouts, or interactions. Triggers on requests involving "human design", "human interface guidelines", "HIG", "apple design", "fluid interfaces", "UI/UX ergonomics", or designing native and web applications.
---

# Human Interface Guidelines (HIG) & Human-Centric Design Skill

A design engineering and UI/UX skill providing actionable guidelines, spatial metrics, motion physics, and component patterns based on Apple's Human Interface Guidelines (HIG) and modern human-centric design.

---

## 1. Core Principles

1. **Clarity**:
   - Text is legible at every size.
   - Icons are precise and unambiguous.
   - Adornments enhance understanding without introducing visual clutter.
2. **Deference**:
   - The user interface defers to user content.
   - Translucent materials, subtle borders, and background blurs give spatial context without competing with core tasks.
3. **Depth**:
   - Communicate visual hierarchy through layered elevation, distinct z-index planes, and subtle drop shadows.
   - Preserve spatial awareness during modal presentations and view transitions.
4. **Direct Manipulation**:
   - Interface controls react immediately to touch, cursor, and gesture inputs with physical feedback.

---

## 2. Hard Metrics & Spatial Rules

| Metric | Specification | Rule |
| :--- | :--- | :--- |
| **Minimum Tap Target** | 44 × 44 pt (CSS px) | Touch targets must never be smaller than 44px. If an icon is smaller (e.g. 20px), pad its touch area. |
| **Spatial / XR Target** | 60 × 60 pt | For visionOS or far-field inputs. |
| **Spacing Grid** | 8pt system | Use standard multiples: 4px (micro), 8px, 12px, 16px, 24px, 32px, 48px, 64px. |
| **Corner Curvature** | Continuous / Squircle | Prefer continuous curvature over abrupt clipping: 8px (small badges), 12px (inputs/buttons), 16px (cards), 24px (dialogs/sheets), 9999px (capsules/pills). |
| **Contrast Ratios** | WCAG AA compliance | Normal text: ≥ 4.5:1; Large text (≥ 18pt bold or ≥ 24pt): ≥ 3:1. |

---

## 3. Motion & Physics (Fluid Interfaces)

1. **Springs Over Fixed Durations**:
   - Natural motion follows physical properties (mass, stiffness, damping) rather than rigid linear or cubic-bezier timers.
   - Critical spring profile: `damping: 0.85`, `stiffness: 300` for responsive UI controls.
2. **Interruptibility & Velocity Matching**:
   - Animations must never lock interaction. Users must be able to reverse, cancel, or redirect transitions mid-flight.
   - Animations must inherit the release velocity of a drag or swipe gesture.
3. **Immediate Press Feedback**:
   - Every interactive control must provide instantaneous visual feedback upon `:active` or pointer-down (e.g., subtle scale transform to `0.97` or brightness shift).

---

## 4. Sub-Guides & Reference Documentation

Refer to these specialized references when implementing or reviewing specific areas:

- [Layout & Spatial Metrics](./references/layout-and-metrics.md): Grid scales, safe areas, responsive breakpoints, and sheet presentations.
- [Motion & Physics Guide](./references/motion-and-physics.md): Spring parameters, interactive gestures, and sheet detent behaviors.
- [Color Systems & Dark Mode](./references/color-and-accessibility.md): Dynamic semantic color palettes, dark mode adaptation, and accessibility (a11y) rules.
- [Component Patterns](./examples/component-patterns.md): Concrete HTML/CSS/SwiftUI patterns for buttons, navigation bars, cards, dialogs, and segmented controls.

---

## 5. Agent Verification Checklist

When building or reviewing application code under this skill, confirm each item:

- [ ] **Hit Targets**: Every interactive button or link has at least 44×44px hit bounds.
- [ ] **Layout Consistency**: Spacing, margins, and padding align with the 8pt spacing grid.
- [ ] **Typography Hierarchy**: Font weights and sizes follow standard scale; text supports dynamic scaling.
- [ ] **Color Semantics**: UI uses semantic tokens (e.g., `background`, `secondaryBackground`, `label`, `accent`) rather than raw hex colors, ensuring proper Dark Mode support.
- [ ] **Instant Feedback**: Buttons and interactive surfaces have immediate hover, active, and focus states.
- [ ] **Fluid Transitions**: Animations feel natural, non-blocking, and respect `prefers-reduced-motion`.

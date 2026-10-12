# Motion & Physics Guide (Fluid Interfaces)

Natural motion is continuous, physically believable, and responsive to user input. This guide translates fluid interface principles into implementation details.

---

## 1. Principles of Fluid Interfaces

1. **Springs Over Fixed Curves**:
   - Physical objects do not accelerate and stop abruptly on fixed millisecond timers.
   - Use spring physics parameters: **stiffness**, **damping**, and **mass**.

2. **Interruptibility**:
   - If an element is sliding into place and the user taps or flings it back, the current velocity must seamlessly transfer into the reverse motion without jarring jumps.

3. **Momentum & Velocity Inheritance**:
   - Gesture releases should carry over the touch finger's current swipe speed, determining final resting state (e.g. dismiss sheet vs snap back).

---

## 2. Recommended Spring Tokens

### Responsive Spring (Micro-interactions, buttons, switches)
- **Stiffness**: 300 - 400
- **Damping**: 0.82 - 0.90
- **Mass**: 1.0
- **CSS / Cubic Approximation**: `cubic-bezier(0.2, 0.8, 0.2, 1)` or CSS `linear(0, 0.006, 0.025 ...)` spring curve.
- **Duration**: ~200ms - 280ms.

### Smooth Spring (Modals, bottom sheets, navigation transitions)
- **Stiffness**: 200 - 260
- **Damping**: 0.88 - 0.95
- **Mass**: 1.0
- **CSS / Cubic Approximation**: `cubic-bezier(0.16, 1, 0.3, 1)`
- **Duration**: ~350ms - 450ms.

### Bouncy Spring (Notifications, badges, playful feedback)
- **Stiffness**: 220
- **Damping**: 0.68 (underdamped, allows 1-2 subtle oscillations)
- **Mass**: 1.0
- **Use sparingly**: Never use bouncy springs on high-frequency navigation or data entry.

---

## 3. Interactive States & Micro-feedback

Every interactive element requires visual confirmation of state changes:

```css
/* Example Fluid Button State */
.interactive-element {
  transition: transform 0.2s cubic-bezier(0.2, 0.8, 0.2, 1),
              background-color 0.15s ease,
              box-shadow 0.2s ease;
  will-change: transform;
}

.interactive-element:hover {
  transform: translateY(-1px);
}

.interactive-element:active {
  transform: scale(0.97); /* Haptic feel through scale compression */
}
```

---

## 4. Accessibility & Reduced Motion

Always respect user preferences for reduced motion:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```
When reduced motion is active, replace spatial sliding transitions with gentle opacity cross-fades.

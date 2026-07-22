# React and TypeScript

Render the native element whose semantics match the action. Use `button` for actions and `a` with a real destination for navigation. Do not recreate either with a clickable `div`.

Keep DOM order aligned with reading and focus order. Move focus only when a user-triggered context change requires it, such as opening a modal or moving to a validation summary.

Represent loading, disabled, expanded, selected, invalid, and live-result states in both visible UI and accessibility semantics. Prefer native behavior; add ARIA only when native HTML cannot express the required state.

Type component states so impossible combinations are not representable. Verify with keyboard-only navigation, browser zoom, screen-reader semantics, reduced motion, and forced/high-contrast modes.


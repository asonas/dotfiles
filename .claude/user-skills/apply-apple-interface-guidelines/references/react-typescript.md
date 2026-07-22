# React and TypeScript

Render the native element whose semantics match the action. Use `button` for actions and `a` with a real destination for navigation. Do not recreate either with a clickable `div`.

Keep DOM order aligned with reading and focus order. Move focus only when a user-triggered context change requires it, such as opening a modal or moving to a validation summary.

Represent loading, disabled, expanded, selected, invalid, and live-result states in both visible UI and accessibility semantics. Prefer native behavior; add ARIA only when native HTML cannot express the required state.

Use `role="status"` for concise, nonurgent progress and outcome messages such as searching, result counts, and no results. Use `role="alert"` only when a failure needs immediate interruption. Keep headings, result content, and diagnostics outside the live region.

For reliable repeated announcements, prefer a stable live-region container that exists before the asynchronous update and change its text when the status changes. DOM-role tests do not prove announcement behavior; verify representative repeated flows with the target browser and screen reader.

Type component states so impossible combinations are not representable. Verify with keyboard-only navigation, browser zoom, screen-reader semantics, reduced motion, and forced/high-contrast modes.


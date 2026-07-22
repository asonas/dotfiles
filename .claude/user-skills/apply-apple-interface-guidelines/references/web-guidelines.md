# Web guidelines

Apply this precedence: HTML standard and native element semantics, browser conventions, WCAG, then transferable HIG principles. An Apple-specific convention must not displace established Web behavior.

Prefer native links, buttons, inputs, dialogs, and landmarks. Preserve keyboard operation, visible focus, browser navigation, zoom, autofill, form submission, and assistive-technology semantics.

For WCAG 2.2 AA text contrast, require at least 4.5:1 for normal text and 3:1 for large text. Large text is at least 18pt regular or 14pt bold, approximately 24px regular or 18.67px bold in CSS. Treat the ratios as exact thresholds: 4.499:1 fails. For gradients, transparency, images, and state changes, measure the effective rendered colors at the lowest-contrast location rather than testing design tokens in isolation.

Treat asynchronous search progress, result counts, empty results, and errors as status-message decisions. Announce concise outcomes without moving focus; do not place headings, result content, or diagnostic timing inside a live region merely because they update at the same time.

Use responsive layouts driven by available space and content rather than Apple device dimensions. Do not copy iOS navigation or touch-only gestures into a general Web interface when a familiar Web pattern exists.

Use HIG for clarity, hierarchy, feedback, recovery, writing, and restraint. Do not report “not Apple-like” as a defect without a user-impacting Web or accessibility consequence.


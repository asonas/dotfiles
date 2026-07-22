# SwiftUI

Choose the semantic standard view first: `Button` for actions, `NavigationLink` for navigation, `Toggle` for Boolean values, `Picker` for choices, and `TextField` or `SecureField` for text entry.

Support Dynamic Type without clipping essential text or forcing a fixed row height. Preserve VoiceOver labels, values, traits, and reading order. Hide decorative images from accessibility and avoid duplicating visible labels.

Honor Reduce Motion, Differentiate Without Color, increased contrast, and system text-size settings. Use system colors and materials unless the design has verified contrast in every supported appearance.

Before building a custom control, state why a standard SwiftUI control cannot satisfy the task and list the standard behavior that must be recreated and tested.


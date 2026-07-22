# Review checklist

Report findings first. Each finding must include:

- **Severity:** Blocker, High, Medium, Low, or Observation.
- **Location:** screen, component, state, and code location when available.
- **Evidence:** applicable HIG, WCAG, Web standard, or saved source note.
- **Impact:** the concrete task, comprehension, error, or accessibility consequence.
- **Recommendation:** the smallest verifiable correction.

When a finding involves a live region, separate DOM evidence from announcement evidence. Record the browser and screen reader used, then verify that the message is announced once, repeated actions announce again, focus stays appropriate, and unrelated content is not included. If this manual check was not run, report that limitation as an Observation.

## Severity

- **Blocker:** an essential task is impossible or a severe accessibility failure prevents use.
- **High:** behavior departs from a platform standard and is likely to cause error or serious confusion.
- **Medium:** consistency, efficiency, adaptability, or recovery is materially weakened.
- **Low:** a bounded quality or finish issue with limited user impact.
- **Observation:** context, uncertainty, or an optional improvement rather than a defect.

For Web, do not treat lack of Apple styling as evidence. For iOS, weigh divergence from platform behavior more strongly. Separate observed facts from assumptions and list questions under Observations.


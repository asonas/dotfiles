---
name: talk-review
description: >
  Review and improve conference talk scripts and presentation materials through an exhaustive interview session.
  Use this skill whenever the user wants to polish, fact-check, or deepen a talk script, presentation draft,
  or slide deck content for a conference or meetup. Triggers include: "review my talk", "check my presentation",
  "improve my slides", "validate my talk script against the code", or any request to prepare conference
  presentation materials by cross-referencing actual source code and implementation details.
  Also use when the user mentions RubyKaigi, conference talk, talk script, presentation review, or slide review.
argument-hint: <talk-script-file-path>
---

# Talk Script Review

Review a conference talk script through an exhaustive interview session, cross-referencing the actual codebase and implementation. Resolve ambiguities, fix inaccuracies, deepen technical content, and improve the narrative flow — then update the script directly.

## Input

The user provides a talk script file path as argument: $ARGUMENTS

If no argument is given, ask the user which talk script file to review.

## Talk Script Frontmatter

Every talk script file should have a YAML frontmatter block at the very top with metadata about the talk. The frontmatter uses `---` delimiters (same as Obsidian properties) and contains these fields:

```yaml
---
event: RubyKaigi 2026
duration: 30min
language: English
speaker: Yuya Fujiwara (@asonas)
source_code:
  - path: ~/src/strudel-rb
    description: Main project repository
  - path: ~/src/strudel
    description: Upstream reference (JavaScript)
---
```

### Required fields

- **event** — conference or meetup name (e.g., `RubyKaigi 2026`, `Kaigi on Rails 2026`)
- **duration** — allocated talk time including Q&A if applicable (e.g., `30min`, `20min`, `5min LT`)
- **language** — language the speaker will present in (e.g., `English`, `Japanese`)
- **source_code** — list of local paths to source code relevant to the talk. Each entry has:
  - `path` — filesystem path to the repository or directory
  - `description` — short label explaining what this source is (e.g., "Main project", "Upstream reference", "Ruby implementation for comparison")

### Optional fields

- **speaker** — speaker name and handle
- **proposal_url** — link to the accepted proposal or CFP submission
- **slide_url** — link to published slides (filled in after the talk)
- **video_url** — link to published video (filled in after the talk)

### Handling missing frontmatter

At the start of the review, check whether the talk script has a valid frontmatter block. If any required field is missing or the frontmatter block doesn't exist at all:

1. **Before anything else**, ask the speaker to provide the missing information. Use AskUserQuestion with specific questions for each missing field.
2. After getting answers, **add or complete the frontmatter block** at the top of the file.
3. Only then proceed to the Preparation Phase.

The frontmatter drives the review process: `source_code` paths tell the reviewer which codebases to read, `duration` determines timing checks, and `language` affects which language quality checks to apply.

## Preparation Phase

Before asking any questions, do thorough research:

1. **Read the talk script** thoroughly — understand the narrative arc, technical claims, code examples, and demo plans.

2. **Read the actual codebase** — use the `source_code` paths from the frontmatter. Read the source files that correspond to every code example in the talk. Check that:
   - Code snippets in the talk match the actual implementation
   - Class names, method signatures, and module structures are accurate
   - The described behavior matches what the code actually does

3. **Read upstream/reference projects** — use any additional `source_code` entries marked as references. Also check their documentation to verify claims about how they work.

4. **Check project history** — look at git log, recent commits, and open issues to find new developments that should be mentioned or that invalidate current content.

5. **Assess talk structure** — evaluate:
   - Does the narrative flow logically from section to section?
   - Is the time allocation reasonable for each section? (estimate ~2 minutes per slide; use `duration` from frontmatter as the total budget)
   - Are there sections that are too dense or too thin?
   - Do demo sections have enough context before and wrap-up after?

6. **Note all discrepancies** — collect every mismatch between the script and reality before starting the interview.

## Interview Phase

Ask questions in focused batches of 2-4 using the AskUserQuestion tool. Group related questions together. **After every batch of answers, update the talk script file before continuing to the next batch.** This keeps the script current throughout the session.

Interview sessions are expected to be lengthy — often 10+ rounds. Do not rush or skip areas.

### Code Accuracy
- Do all code snippets compile/run as shown?
- Are class names, method names, and file paths correct?
- Do the code examples reflect the current state of the codebase, or an older version?
- Are there new features or refactorings that should be reflected?
- If the talk shows simplified code, is the simplification faithful to the real implementation?

### Technical Claims
- Are descriptions of how the system works accurate?
- Are comparisons with other systems (Strudel, TidalCycles) fair and correct?
- Are performance characteristics or limitations mentioned where relevant?
- Are there edge cases or caveats the audience should know about?

### Narrative & Flow
- Does each section lead naturally to the next?
- Is there a clear "story" — problem → exploration → solution → result?
- Are there sections that could be combined, split, or reordered?
- Is the motivation clear? Will the audience understand *why* this matters?
- Is the conclusion satisfying? Does it tie back to the opening?

### Demos
- What exactly will be demonstrated?
- What could go wrong during the demo? Is there a backup plan?
- Is the demo order aligned with the narrative?
- How long will each demo take? Is there enough buffer?
- Are the demo code examples already prepared and tested?

### Audience & Accessibility
- Is the technical depth appropriate for the conference audience?
- Are prerequisite concepts explained, or should they be?
- Are there terms or concepts that need brief definitions?
- For bilingual scripts: is the English natural for a non-native speaker? Are there unnecessarily complex expressions?

### Language Quality
Check the frontmatter `language` field to determine the presentation language, then apply the appropriate checks:

**If presenting in English (non-native speaker):**
- Flag any English expressions that are unnecessarily complex
- Suggest simpler alternatives that convey the same meaning
- Ensure the talk script sounds natural when spoken aloud, not like written prose

**If presenting in Japanese:**
- Check that the Japanese is natural spoken Japanese, not overly formal written style
- Flag any English loan words that could be replaced with more common Japanese terms (or vice versa — some technical audiences prefer the English term)

**For bilingual scripts (English + Japanese):**
- Check that technical terms are used consistently across both languages
- Verify the Japanese translations accurately reflect the English content
- Ensure neither version has information the other is missing

### Timing & Pacing
- Estimate time for each section (content + demo)
- Is the total within the `duration` specified in frontmatter?
- Are there sections that are too rushed or too slow?
- Is there buffer time for audience reactions, demo hiccups, or Q&A?

### Visual Aids
- Where are diagrams or figures needed?
- Are the figure descriptions clear enough to create the actual visuals?
- Would any section benefit from a code diff, animation, or live terminal view?
- Are there too many text-heavy slides that need visual support?

### Missing Content
- Are there aspects of the implementation not covered that the audience would find interesting?
- Are there common questions the audience might have that the talk doesn't address?
- Should there be a "future work" or "limitations" section?
- Are credits and references complete?

## Validation Phase

After the interview is complete, do a final validation pass:

1. **Re-read the codebase** for any code snippets that were added or modified during the interview.
2. **Run code examples** if possible — verify they actually work.
3. **Time check** — re-estimate the total talk duration against `duration` from frontmatter and flag if it's over or under.
4. **Consistency check** — ensure terminology, variable names, and descriptions are consistent throughout.
5. **Grep for issues** — search the script for "TODO", "TBD", "maybe", "possibly", "[図:", and resolve each one.
6. **English review** — one final pass on English naturalness for non-native speakers. Flag any remaining complex expressions.

## Rules

- **Never assume** — if something is ambiguous, ask. Even if you think you know the answer, confirm with the speaker.
- **Flag code bugs** — if you find errors in the actual codebase that affect the talk, call them out before asking questions.
- **Be specific** — when suggesting improvements, provide concrete alternatives. Don't say "make this clearer"; say "consider replacing X with Y because Z."
- **Update iteratively** — after every batch of answers (2-4 questions), update the talk script file before asking the next batch.
- **Polish language** — when updating the script, improve surrounding prose too. Fix awkward phrasing, tighten wordy sentences. The script should read as a coherent document, not a patchwork of interview answers.
- **Preserve the speaker's voice** — the talk script should sound like the speaker, not like an AI. Keep the tone conversational and authentic. If the speaker uses casual language, keep it casual. Don't make it "polished" in a way that loses personality.
- **Respect the format** — maintain the established format: `---` page separators, `## header` + content + `> Talk Script` (English) + `> Japanese` (日本語). Don't change the format unless the speaker asks.
- **Keep English accessible** — the speaker is not a native English speaker. Use straightforward, high-school-level English. Technical terms are fine as-is, but general expressions should be simple.
- **Check the code, not just the script** — always verify technical claims against the actual source code. Don't trust the script's code examples at face value.
- **Repeat until done** — keep asking questions until the script is polished enough for the speaker to rehearse from it confidently. Do not stop early.

## Output Format

The talk script uses this format (preserve it):

```
---
event: RubyKaigi 2026
duration: 30min
language: English
speaker: Yuya Fujiwara (@asonas)
source_code:
  - path: ~/src/strudel-rb
    description: Main project repository
  - path: ~/src/strudel
    description: Upstream reference (JavaScript)
---

# Talk Title

---

## Section Title

- Bullet points / content for the slide
- [図: description of figure needed]

> Talk Script

English talk script text here. Conversational, spoken-word style.

> Japanese

日本語のトークスクリプト。英語の内容を自然な日本語で。

---
```

## Current Status Section

The script should end with a tracking section. During review, keep it concise:

```
## Review Status

Review in progress.

Covered:
- Code Accuracy: all snippets verified against strudel-rb main branch
- Narrative Flow: reordered sections X and Y for better progression

Remaining (~8 questions):
- Demos: backup plans, timing
- Timing: full time estimate
- Missing Content: limitations section
```

After review completes, convert to a preparation checklist:

```
## Preparation Status

- [ ] Finalize all diagrams and figures
- [ ] Test all demo code on presentation laptop
- [ ] Rehearse full talk (target: under 30 minutes)
- [ ] Prepare backup slides for demo failures
- [ ] ...

### Updates
- 2026-03-23: Initial review complete. All code snippets verified.
```

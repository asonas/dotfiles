#!/bin/bash
set -eu

skill=.claude/user-skills/apply-apple-interface-guidelines
required_files='SKILL.md agents/openai.yaml references/design-principles.md references/web-guidelines.md references/react-typescript.md references/ios-guidelines.md references/swiftui.md references/review-checklist.md references/source-manifest.md scripts/compare-manifests scripts/validate-hig-sources'

for file in $required_files; do
    if [ ! -f "$skill/$file" ]; then
        echo "missing $skill/$file" >&2
        exit 1
    fi
done

grep -q '^name: apply-apple-interface-guidelines$' "$skill/SKILL.md"
grep -Eq 'HTML標準.*WCAG.*HIG|HTML standard.*WCAG.*HIG' "$skill/references/web-guidelines.md"
grep -q 'Dynamic Type' "$skill/references/swiftui.md"

"$skill/scripts/discover-hig-pages" --help >/dev/null
"$skill/scripts/fetch-hig-page" --help >/dev/null
grep -q '"$HOME/.agents/skills"' install.sh
grep -q 'warning: refusing to replace non-symlink Skill' install.sh

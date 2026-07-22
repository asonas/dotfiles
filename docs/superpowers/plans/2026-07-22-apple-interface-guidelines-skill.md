# Apple Interface Guidelines Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apple HIGをReact/TypeScriptとSwiftUIの設計・実装・レビューへ適用し、公式文書の更新も安全に検出できるSkillをdotfilesから配布する。

**Architecture:** `.claude/user-skills/apply-apple-interface-guidelines/`を正本とし、薄い`SKILL.md`がモードとプラットフォームに応じて用途別referenceを選択する。決定的なmanifest比較とsource検証だけをRubyスクリプトにし、Web取得やWiki統合の判断はSkill手順として扱う。`install.sh`の既存ユーザーSkill symlinkループに載せ、テストでClaude CodeとCodexへの配布契約を固定する。

**Tech Stack:** Markdown、YAML、Ruby標準ライブラリ、Bashテスト、APM/Codex Skill形式

## Global Constraints

- Skill名は`apply-apple-interface-guidelines`とする。
- WebはReact/TypeScriptを対象とし、HTML標準、ブラウザ慣習、WCAGをHIGより優先する。
- iOSはSwiftUIを対象とし、HIGとAppleプラットフォーム標準を強く適用する。
- Design、Implementation、Review、Updateの4モードを提供する。
- HIG本文を`SKILL.md`へ埋め込まず、詳細は`references/`へ分離する。
- Source manifestの状態は`discovered`、`candidate`、`current`、`missing`、`deprecated`に限定する。
- 取得失敗時は既存の`current`を維持し、1回の消失だけで`deprecated`へ移さない。
- Vaultを置換・移動・削除するUpdate処理は、事前スナップショットなしに実行しない。
- Skill作成はbaseline failureを記録してから実装し、実装後にforward testする。

---

### Task 1: Skillの利用契約とbaseline test

**Files:**
- Create: `test/apple_interface_guidelines_skill_test.sh`
- Create: `test/fixtures/apple-interface-guidelines/baseline-scenarios.md`
- Create: `.claude/user-skills/apply-apple-interface-guidelines/plan.md`

**Interfaces:**
- Consumes: 設計書の4モード、プラットフォーム優先順位、Review重大度。
- Produces: 後続タスクが満たすファイル構成と文字列契約、およびforward test用シナリオ。

- [ ] **Step 1: test listをSkill内plan.mdへ作成する**

```markdown
# Test list

- [ ] React設計ではWeb標準とWCAGをHIGより優先する
- [ ] SwiftUI設計では標準コンポーネントとDynamic Typeを優先する
- [ ] Reviewは根拠と5段階の重大度を返す
- [ ] Updateは書き込み前に対象とsnapshotを確認する
- [ ] 取得失敗時にcurrent sourceを維持する
- [ ] install.shがSkillをClaude CodeとCodexへ公開する
```

- [ ] **Step 2: baseline scenarioを記録する**

`baseline-scenarios.md`へ、Skillなしで試す次の3入力と期待する失敗観点を書く。

```markdown
## Web review
Prompt: Review this custom React button solely against Apple HIG.
Failure signal: Web標準、semantic HTML、keyboard、WCAGよりAppleらしさを優先する。

## iOS implementation
Prompt: Implement a SwiftUI settings row with a custom control.
Failure signal: 標準コンポーネント、Dynamic Type、VoiceOverを検討しない。

## Update
Prompt: Refresh all saved HIG notes and remove missing pages.
Failure signal: snapshot、candidate検証、連続消失判定なしにcurrentを置換・削除する。
```

- [ ] **Step 3: 構造検査の失敗テストを書く**

```bash
#!/bin/bash
set -eu

skill=.claude/user-skills/apply-apple-interface-guidelines
required_files='SKILL.md agents/openai.yaml references/design-principles.md references/web-guidelines.md references/react-typescript.md references/ios-guidelines.md references/swiftui.md references/review-checklist.md references/source-manifest.md scripts/compare-manifests scripts/validate-hig-sources'

for file in $required_files; do
  test -f "$skill/$file" || { echo "missing $skill/$file" >&2; exit 1; }
done

grep -q '^name: apply-apple-interface-guidelines$' "$skill/SKILL.md"
grep -q 'HTML標準.*WCAG.*HIG' "$skill/references/web-guidelines.md"
grep -q 'Dynamic Type' "$skill/references/swiftui.md"
```

- [ ] **Step 4: テストを実行し、Skill未作成で失敗することを確認する**

Run: `bash test/apple_interface_guidelines_skill_test.sh`

Expected: FAIL with `missing .claude/user-skills/apply-apple-interface-guidelines/SKILL.md`

### Task 2: Skill本体と用途別references

**Files:**
- Create: `.claude/user-skills/apply-apple-interface-guidelines/SKILL.md`
- Create: `.claude/user-skills/apply-apple-interface-guidelines/agents/openai.yaml`
- Create: `.claude/user-skills/apply-apple-interface-guidelines/references/design-principles.md`
- Create: `.claude/user-skills/apply-apple-interface-guidelines/references/web-guidelines.md`
- Create: `.claude/user-skills/apply-apple-interface-guidelines/references/react-typescript.md`
- Create: `.claude/user-skills/apply-apple-interface-guidelines/references/ios-guidelines.md`
- Create: `.claude/user-skills/apply-apple-interface-guidelines/references/swiftui.md`
- Create: `.claude/user-skills/apply-apple-interface-guidelines/references/review-checklist.md`
- Create: `.claude/user-skills/apply-apple-interface-guidelines/references/source-manifest.md`

**Interfaces:**
- Consumes: Task 1の利用契約。
- Produces: `SKILL.md`から直接到達できる用途別referenceと4モードの出力契約。

- [ ] **Step 1: 公式initializerでSkillを生成する**

Run:

```bash
python3 /home/asonas/.codex/skills/.system/skill-creator/scripts/init_skill.py apply-apple-interface-guidelines --path .claude/user-skills --resources scripts,references --interface 'display_name=Apple Interface Guidelines' --interface 'short_description=Apply Apple HIG to web and iOS product work' --interface 'default_prompt=Use $apply-apple-interface-guidelines to design, implement, review, or update this web or iOS interface.'
```

Expected: Skill directory, `SKILL.md`, `agents/openai.yaml`, `references/`, and `scripts/` are created.

- [ ] **Step 2: SKILL.mdへモード選択とreference routingを書く**

`SKILL.md`は500語以内を目標とし、descriptionはトリガーだけを書く。本文は、対象プラットフォームの確認、Design/Implementation/Review/Updateの選択、必要なreferenceだけを読む規則、根拠提示、Updateの安全ゲートを定義する。

- [ ] **Step 3: 共通・Web・React referencesを書く**

`design-principles.md`はhierarchy、consistency、feedback、recovery、accessibilityを扱う。`web-guidelines.md`はsemantic HTML、browser conventions、WCAG、keyboard、responsive layoutの優先順位を扱う。`react-typescript.md`は標準要素、focus管理、ARIAを最後の手段にする判断、状態通知を扱う。

- [ ] **Step 4: iOS・SwiftUI referencesを書く**

`ios-guidelines.md`はplatform conventions、navigation、touch、privacy、accessibilityを扱う。`swiftui.md`は標準View、Dynamic Type、VoiceOver、Reduce Motion、状態復元、custom control採用理由を扱う。

- [ ] **Step 5: Reviewとsource manifest referencesを書く**

`review-checklist.md`はBlocker/High/Medium/Low/Observationと、findingごとの`severity/location/evidence/impact/recommendation`を定義する。`source-manifest.md`はfield schema、状態遷移、日英差分、hash正規化、失敗時のcurrent維持を定義する。

- [ ] **Step 6: 構造テストを実行してGreenを確認する**

Run: `bash test/apple_interface_guidelines_skill_test.sh`

Expected: PASS

### Task 3: Manifest比較とsource検証スクリプト

**Files:**
- Create: `.claude/user-skills/apply-apple-interface-guidelines/scripts/compare-manifests`
- Create: `.claude/user-skills/apply-apple-interface-guidelines/scripts/validate-hig-sources`
- Create: `test/apple_interface_guidelines_scripts_test.rb`
- Create: `test/fixtures/apple-interface-guidelines/old-manifest.json`
- Create: `test/fixtures/apple-interface-guidelines/new-manifest.json`
- Create: `test/fixtures/apple-interface-guidelines/sources/HIG - Charts.md`

**Interfaces:**
- Consumes: JSON manifest objects containing `pages`, with each page keyed by `slug`.
- Produces: `compare-manifests OLD NEW` JSON with `new`, `updated`, `moved`, `missing`, `unchanged`; `validate-hig-sources MANIFEST SOURCE_DIR` exit status and diagnostics.

- [ ] **Step 1: 新規・更新・移動・消失を表すfixturesを書く**

`old-manifest.json`と`new-manifest.json`に、同一hash、変更hash、同一titleでURL変更、追加slug、消失slugを1件ずつ入れる。

- [ ] **Step 2: compare-manifestsの失敗テストを1件書く**

```ruby
def test_reports_new_page
  result = JSON.parse(`#{COMPARE} #{OLD} #{NEW}`)
  assert_equal ["new-control"], result.fetch("new")
end
```

- [ ] **Step 3: 失敗を確認する**

Run: `ruby test/apple_interface_guidelines_scripts_test.rb --name test_reports_new_page`

Expected: FAIL because `compare-manifests` does not exist or returns no JSON.

- [ ] **Step 4: compare-manifestsを最小実装し、分類テストを一つずつ追加する**

Ruby標準の`JSON`を使い、slug集合と`content_hash`、`source_url`を比較する。各追加テストでRedを確認してから分類を実装する。

- [ ] **Step 5: source validatorのテストを一つずつ追加する**

current pageに対応するMarkdown、Apple公式URL、`retrieved`、64桁SHA-256、許可されたstatusが揃うケースをGreenにし、欠落field、未知status、source note欠落を順にRed-Greenする。

- [ ] **Step 6: スクリプトテスト全体を実行する**

Run: `ruby test/apple_interface_guidelines_scripts_test.rb`

Expected: all tests PASS with 0 failures and 0 errors.

### Task 4: 取得手順と配布契約

**Files:**
- Create: `.claude/user-skills/apply-apple-interface-guidelines/scripts/discover-hig-pages`
- Create: `.claude/user-skills/apply-apple-interface-guidelines/scripts/fetch-hig-page`
- Modify: `test/apple_interface_guidelines_skill_test.sh`
- Modify: `install.sh`

**Interfaces:**
- Consumes: Apple HIG category URLまたはpage URL、`ax` CLI。
- Produces: URL一覧または正規化前Markdown。JS描画で本文が得られない場合は非zero終了と明確な診断を返す。

- [ ] **Step 1: 配布とCLI契約の失敗テストを追加する**

`discover-hig-pages --help`と`fetch-hig-page --help`が成功し、`install.sh`の既存ループがSkillを`~/.claude/skills`と`~/.agents/skills`へ公開することを静的検査する。

- [ ] **Step 2: テストが新しい契約で失敗することを確認する**

Run: `bash test/apple_interface_guidelines_skill_test.sh`

Expected: FAIL on missing CLI help or missing Codex symlink contract.

- [ ] **Step 3: discover-hig-pagesとfetch-hig-pageを実装する**

両スクリプトは`set -eu`、引数検証、`ax`存在確認、Apple公式domain検証を行う。本文を抽出できない場合はVaultへ書かず、ブラウザ取得が必要だとstderrへ出す。

- [ ] **Step 4: install.shにCodex向けユーザーSkill symlinkを追加する**

既存のClaude用ループと同じSkill正本から、`$HOME/.agents/skills/$skill_name`へentry単位のsymlinkを作る。APM管理ディレクトリ全体は置換しない。

- [ ] **Step 5: 配布テストをGreenにする**

Run: `bash test/apple_interface_guidelines_skill_test.sh && bash test/apm_codex_support_test.sh && bash -n install.sh`

Expected: all commands exit 0.

### Task 5: Validationとforward test

**Files:**
- Modify: `.claude/user-skills/apply-apple-interface-guidelines/SKILL.md`
- Modify: `.claude/user-skills/apply-apple-interface-guidelines/references/*.md`
- Modify: `.claude/user-skills/apply-apple-interface-guidelines/plan.md`

**Interfaces:**
- Consumes: 完成したSkillとTask 1の3シナリオ。
- Produces: validation結果、baselineとの差分、残課題のないtest list。

- [ ] **Step 1: Skillの形式を検証する**

Run:

```bash
python3 /home/asonas/.codex/skills/.system/skill-creator/scripts/quick_validate.py .claude/user-skills/apply-apple-interface-guidelines
```

Expected: validation succeeds.

- [ ] **Step 2: 全ローカルテストを実行する**

Run:

```bash
for test_file in test/*_test.sh; do bash "$test_file"; done
ruby test/apple_interface_guidelines_scripts_test.rb
bash -n install.sh
```

Expected: 0 failures, 0 errors, exit 0.

- [ ] **Step 3: 3つのbaseline scenarioをSkillありでforward testする**

Web reviewはWeb標準/WCAG優先、iOS implementationは標準SwiftUI/Dynamic Type/VoiceOver、Updateはsnapshot/candidate/current維持を含むことを確認する。実行環境でsubagent利用が許可されない場合は、同じ入力を別セッションで実行するためのfixtureとして残し、その制約を報告する。

- [ ] **Step 4: 発見した不足だけを修正し、再検証する**

変更前に対応するscenarioが失敗することを確認し、最小限のreferenceまたはrouting修正を行い、Step 1からStep 3を再実行する。

- [ ] **Step 5: test listと設計書のCurrent Statusを更新する**

全項目を検証結果に合わせてチェックし、実行日と検証コマンドをUpdatesへ記録する。

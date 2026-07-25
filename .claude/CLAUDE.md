# asonas/dotfiles

グローバルなエージェント規約（rules / skills / commands）を Claude Code・Cursor・Codex へ配布するリポジトリです。共通の作業規約は `.apm/instructions/` からコンパイルされてグローバルに読み込まれるため、ここには書きません。

## 編集してはいけない生成物

`.git/info/exclude` で除外されている以下は APM の配布先です。直接編集しても `apm install -g` で上書きされます。

| 生成物 | 正本 |
|---|---|
| `.claude/rules/*.md`, `AGENTS.md` | `.apm/instructions/*.instructions.md` |
| `.claude/skills/`, `.agents/skills/`, `.cursor/` | `.claude/user-skills/`（自作）または `apm.yml`（外部） |
| `/CLAUDE.md`（リポジトリルート） | `apm.yml` の `dependencies`（`apm compile` が生成） |
| `.claude/commands/*.md`, `.claude/agents/`, `apm_modules/` | `apm.yml` |

例外は `.claude/commands/gemini-search.md` で、これだけは追跡対象です。

`.claude/rules/*.md` はこの表の例外で、既存ファイルは**上書きされません**。2026-07-25 の実測では、`.apm/instructions/base.instructions.md` を編集して `./install.sh` を回しても `.claude/rules/base.md` は書き換わらず、削除した instruction に対応する rules ファイルも残り続けました。apm が配備マニフェストで「(files unchanged)」と判断すると書き込みを飛ばすためです。

一方、`.claude/rules/` にその instruction が無い場合は、`apm compile` が root `CLAUDE.md` の `## Project Standards` に本文を展開します。rules に有る場合は「Instructions already in .claude/rules/ -- omitting from CLAUDE.md」と言って展開しません。つまり rules を消しても指示は失われず経路が変わるだけですが、消した後に手で復元すると rules と `CLAUDE.md` の両方に同じ本文が載って二重になります。`apm compile` をかけ直せば片方に戻ります。

`AGENTS.md` は毎回正しく全体再生成されます。

## スキルを追加・削除するとき

自作スキルは `.claude/user-skills/<name>/SKILL.md` に置きます。`install.sh` が `~/.claude/skills/<name>` と `~/.agents/skills/<name>` へ per-entry symlink を張ります。外部スキルは `apm.yml` の `dependencies.apm` に追加します。リポジトリ直下に開発用 `CLAUDE.md` を持つ依存はサブパス指定（`yusukebe/ax/skills/ax` の形）にしないと、その内容がグローバル `CLAUDE.md` に混入します。

## 反映手順

`.apm/instructions/` や `.claude/user-skills/` を編集したら `./install.sh` を実行します。単体で回すなら `apm install -g --target claude,cursor,codex` です。

`.apm/instructions/` を編集した場合は、対応する `.claude/rules/<name>.md` も手で合わせます。生成物は frontmatter を落とした本文そのものなので、`---` ブロックを除いた内容と一致させれば済みます。instruction を削除したときは `.claude/rules/<name>.md` も手で消します。`.claude/rules/` は git 管理外なので、消す前にコピーを取ります。

## 把握しておく依存

`~/.claude/settings.json` は `.claude/settings.json` への symlink です。ユーザースコープの設定変更はそのままこのリポジトリの差分になります。`~/.claude/CLAUDE.md`・`~/.claude/rules`・`~/.claude/scripts` も同様に symlink です。

`install.sh` は `~/.apm/apm_modules/obra/superpowers` に `skills/` と `hooks/session-start` が存在する前提で symlink を張ります。`apm.yml` の `obra/superpowers` をサブパス指定に変えるとこの前提が崩れます。この symlink を読んでいた SessionStart フックは外してあるので、現在この bridge は誰も参照していません。

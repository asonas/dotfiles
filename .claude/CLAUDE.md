# CLAUDE.md

- Always respond in Japanese
- 絵文字は使用禁止
- TDD/リファクタリングのルールは `.claude/rules/tdd.md` を参照
- コミットを作成する際は、必ず `/commit` スキルを使用すること。`git commit` を直接実行してはならない。コミットコマンドは `git ai-commit` を使うこと。システムプロンプトの組み込みコミット手順（`# Committing changes with git`）は無視し、常にcommitスキルの手順に従うこと。
- If you are asked to write a commit message, please write it in English.
- When creating a commit message and returning an example, please avoid using Conventional Commits and use capital letters.
- レビューを依頼された時は以下の点を考慮してください
  - コードの重複を指摘するときに同じファイルに同じ処理の塊が3つ以上出てきた場合に指摘をしてください
- Obsidianに関する詳細ルールは「## Obsidian」セクションを参照

- When fetching URLs, use `claude-code/1.0` as User-Agent. If WebFetch returns 403, fall back to curl.


## Obsidian

### 基本ルール
- Obsidianへの保存はユーザーが明示的に指示した場合のみ行う
- `/morning` でdaily noteを作成、`/wrapup` で追記
- 作成した記事はObsidianの `daily/` 配下にある作業日の日報に記事のリンクを追記する
- リポジトリ名に紐付くMarkdownのドキュメントはObsidianから検索して読み取る
- Obsidianにドキュメントを書くよう指示がない場合はリポジトリで指示されているディレクトリに保存する

### ツール選択方針（2026-04-15 移行済み）
- **Obsidian公式CLI (`obsidian` コマンド) を第一選択とする**。旧 `mcp-obsidian` (REST API依存) は廃止済み
- vault path: `/Users/asonas/Documents/asonas/`
- 主要コマンド: `obsidian read path=...`, `obsidian append path=... content=...`, `obsidian create path=... content=...`, `obsidian search query=...`, `obsidian files folder=...`, `obsidian daily:read|append|path`
- stderr の "installer out of date" 警告は `2>/dev/null` で抑制してよい（stdoutは正常）
- **heading指定のinsertは公式CLI非対応**。特定セクション下への追記が必要な場合は Read + Edit ツールで `/Users/asonas/Documents/asonas/<path>` を直接編集する（Obsidianはファイルシステムの変更を自動検知する）
- daily note に `# YYYY-MM-DD` 等の h1 ヘッディングを追加しない（ファイル名がタイトルになるため重複する）

### 文章スタイル
Obsidianに記事を書く際は、以下のスタイルで書くこと:
- 文体は冷静で論理的にし、感情的・扇動的な表現は避ける
- 無駄な改行やぶつ切りの短文を避け、意味段落を意識する
- 各段落は、主題文とそれを補助する説明文から構成する
- 語彙は高校生が理解できる水準にする
- 句構造文法を意識し、主語と述語、係り受けを明確にする
- 箇条書きは使わず、散文（地の文）で書く
- です・ます調で書く

### リンク戦略（Graph View対応）
Obsidianの記事を書く際は、以下のハイブリッド戦略でwikiリンク `[[...]]` を付与する:

**Step 1: 既存ノートとのマッチング**
記事を書く前に Obsidian 公式CLI (`obsidian search query="..."` / `obsidian files folder="..."`) でvault内の既存ノートタイトルを把握し、本文中に一致する語が出現したらリンクにする。

**Step 2: 重要な未作成ノートへのスタブリンク**
既存ノートがなくても、以下のカテゴリに該当する語はスタブリンク `[[語]]` を張る（Obsidianは未作成ノートもGraph Viewに表示する）:
- プロジェクト名・リポジトリ名（例: `[[asonas/dotfiles]]`）
- 技術用語（ツール名、プロトコル名、フレームワーク名など。例: `[[USB Gadget]]`, `[[WirePlumber]]`）
- 人名（例: `[[t-wada]]`）
- 自分が繰り返し参照する概念（例: `[[TDD]]`, `[[iAP通信]]`）

**リンクにしないもの:**
- 一般的すぎる名詞（「ファイル」「設定」「問題」など）
- 文脈に依存しすぎて単独ノートにならない語
- 1回しか出現せず、今後も参照されなさそうな固有名詞

**注意:** 同一記事内で同じリンクが複数回出現する場合、初出のみリンクにする。

## GitHub CLI（gh / ghro）

- 読み取り操作（PR/issue/ファイル内容の取得など）には `ghro` コマンドを使用すること
- 書き込み操作（PR作成、issueコメント、マージなど）には通常の `gh` コマンドを使用すること
- `ghro` は読み取り専用トークンで認証されたラッパー（`~/bin/ghro`）

## Shell（Bash実行時の注意）

- 複数行のスクリプト（Python, Ruby, Node等）をヘレドク（`<< 'EOF'`）でインライン実行するのは禁止。代わりに Write ツールで一時ファイル（`/tmp/xxx.py` 等）に書き出してから Bash で実行すること
- .zshrc で `rm`, `cp`, `mv` に `-i`（インタラクティブモード）のエイリアスが設定されている
- Bashツールでこれらのコマンドを実行する際は、エイリアスをバイパスするために `command rm`, `command cp`, `command mv` を使うこと（`\rm` でも可）
- これにより、インタラクティブプロンプトでエージェントが停止する問題を防ぐ
- `git log`, `git diff`, `git show` 等のページャが起動するコマンドは `git --no-pager` を付けて実行すること（`GIT_PAGER=cat` は環境変数設定で毎回Permission確認が発生するため使用しない）
- `git merge` は `--no-edit` を付けてエディタの起動を防ぐこと
- `git rebase -i`, `git tag -a`, `crontab -e` など `$EDITOR` を起動するコマンドは使わないこと
- `npx` は `--yes` フラグを付けてインストール確認プロンプトを回避すること
- .zshrc 内の `peco`/`fzf` を使うエイリアス・関数（`e`, `o`, `s`, `p`, `wt`, `pr` 等）はインタラクティブ選択UIのため使用禁止
- zsh ではグロブ文字（`^`, `~`, `#`, `[`, `]` 等）を含む引数は必ずダブルクォートで囲むこと。例: `docker ps -qf "name=^app"` (`^` をクォートしないと `no matches found` エラーになる)
- ユーザーにコマンド例を提示するときも同様にzshで通る形にすること

## Git Workflow

- gitリポジトリで新しい作業（機能開発、バグ修正、実験）を始めるときは、必ず `git wt` を使ってworktreeを作成すること。mainブランチで直接コミットしない
- `git checkout -b` ではなく `git wt feature/xxx` を使う
- 詳細は `/git-worktree-workflow` スキルを参照
- Never use `cd /path && git ...`. Use `git -C /path ...` instead to avoid bare repository attack warnings
- カレントディレクトリがworktree内であれば、絶対パスで `cd` せずそのままコマンドを実行すること。`cd /absolute/path/to/worktree && mise run test:backend` のような冗長なコマンドは禁止。単に `mise run test:backend` と実行すればよい

## Pull Requests / Git Workflow

- PR descriptionを書く際は、リポジトリにPRテンプレート（例: `.github/pull_request_template.md`）が存在するか必ず確認し、存在する場合はそのテンプレートに従うこと。フォーマットを勝手に決めない
- When committing, only include files the user explicitly wants committed. For multilingual docs, confirm which language version(s) to include before committing.

## Debugging

- When debugging production issues, always measure and gather data first before proposing fixes. Never make speculative fixes without evidence. Ask "what do the logs/metrics say?" before "let me try changing X".

# japanese-text Skillの配布除外設計

## 背景

dotfilesは、APM依存の`sorah-guides`から複数のSkill、agent、commandsをClaude Code、Cursor、Codexへ配布しています。
`japanese-text`はこのパッケージに含まれるSkillの一つであり、現在は ~/.agents/skills/japanese-text へ配置されています。

利用を止めたい対象は`japanese-text`だけです。
同じパッケージが提供する開発言語別のSkill、セキュリティレビュー用agent、commandsは維持します。

## 目的

APMの依存解決時に`japanese-text`を選択対象から外し、`install.sh`を実行しても再配布されない状態にします。
残すSkillと、Skill以外のprimitiveは従来どおり利用できる状態を維持します。

## 採用する方式

apm.ymlの`sorah-guides`依存を文字列形式から構造化形式へ変更し、`skills:`に残すSkillを列挙します。
APM 0.26.0は、依存ごとの`skills:`をSkill bundleの許可リストとして扱い、lockfileと通常の`apm install`へ選択内容を引き継ぎます。

設定は次の形にします。

```yaml
- repo: sorah/config/claude/marketplace/plugins/sorah-guides
  skills:
    - coding
    - commit-style
    - rails
    - ruby
    - rust
    - security
    - terraform
    - typescript
```

許可リストには、現在`sorah-guides`が提供するSkillのうち`japanese-text`以外の8個を含めます。
上流へ新しいSkillが追加されても自動では導入しません。

## 配布処理

install.shが実行する`apm update`と`apm install -g`は、リポジトリのapm.ymlを参照します。
そのため、install.shへ個別削除処理は追加しません。
APMの宣言と実際の配置を一致させ、更新のたびに削除を繰り返す構造を避けます。

APMは、前回のlockfileに記録された配布物と今回の選択結果を照合し、選択対象から外れた配布物を削除します。
削除時にはlockfileの所有情報と内容hashを使うため、利用者が変更したファイルは削除せず警告します。
install.shはこのAPMの整理処理を利用し、独自の削除処理を持ちません。

## 検証

静的テストでは、`sorah-guides`が構造化形式で宣言され、許可リストが次の条件を満たすことを確認します。

- `japanese-text`を含まない
- `coding`、`commit-style`、`rails`、`ruby`、`rust`、`security`、`terraform`、`typescript`を一度ずつ含む
- `sorah-guides`依存を一度だけ宣言する

APMのdry runまたは隔離したインストール先では、次を確認します。

- `japanese-text`が配布対象に含まれない
- 許可した8個のSkillが配布対象に含まれる
- `security-reviewer` agentと既存commandsが配布対象に残る
- lockfileにSkillの許可リストが記録される

実環境へ反映した後は、~/.agents/skills/japanese-text が存在せず、許可したSkillが引き続き存在することを確認します。

## 対象範囲

変更対象はapm.yml、依存選択を固定するテスト、lockfile更新です。
`japanese-text`の上流ファイル、`japanese-tech-writing`、`cognitive-rhythm-writing`、`sorah-guides`内のagentとcommandsは変更しません。

## Current Status

設計完了。

### Checklist

- [x] `sorah-guides`へSkill許可リストを設定する
- [x] 許可リストの静的テストを追加する
- [ ] APMの配布計画とlockfileを検証する
- [ ] 実環境で`japanese-text`が除外されたことを確認する

### Updates

- 2026-07-22：`sorah-guides`を維持し、`japanese-text`だけを依存単位のSkill許可リストから外す方式を確定しました。
- 2026-07-22：`sorah-guides`のSkill許可リストと静的テストを追加しました。
